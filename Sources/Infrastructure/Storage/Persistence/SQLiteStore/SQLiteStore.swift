// SQLiteStore.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了知识管理系统的中央存储门面（SQLiteStore），作为整个应用层与底层持久化层之间的核心桥梁。
// 核心职责：
// 1. 响应式数据流管理：基于 GRDB 的 ValueObservation 机制实现数据库与内存状态同步。
// 2. 组件聚合：整合 KnowledgePageStore (CRUD) 与 EmbeddingManager (向量检索)。
// 3. 跨层级协调：管理数据库连接生命周期、安全性校验及后台向量同步。
//
// @SR-01: 所有用户原始文档严禁在未经授权的情况下上传至云端。
// @RR-01: 数据库事务必须满足 ACID 特性，确保在进程崩溃时数据不损坏。
// @PR-05: 数据库冷启动加载时间目标值 < 1.0s。
//
// 版本: 1.4
// 修改记录:
//   - 2026-05-08: 实现 SQLiteStore 门面。
//   - 2026-05-10: 标准化代码注释，增加 SRS 溯源标识。
// 版权: © 2026 Wang Chong。保留所有权利。

import Foundation
import GRDB
import NaturalLanguage
import Observation

// MARK: - SQLite 存储门面

/// 现代化存储门面，组合了 KnowledgePageStore 和 EmbeddingManager。
/// 负责协调全文搜索 (FTS5) 与向量检索的混合召回 (@PR-01, @PR-02)。
@MainActor
@Observable
final class SQLiteStore: VectorIndexableStore {
    // MARK: - Published State
    /// 当前内存中的页面列表，与数据库保持实时同步
    var pages: [KnowledgePage] = []

    // MARK: - 子组件
    /// 页面级 CRUD 仓储
    let repository: KnowledgePageStore
    /// 向量检索管理组件
    private(set) var embeddingManager: EmbeddingManager
    
    @ObservationIgnored
    private nonisolated(unsafe) var observationTask: Task<Void, Never>?
    
    // MARK: - 回调钩子
    /// 日志记录回调
    var onLog: ((LogAction, String, String) -> Void)?
    /// 持久化触发回调
    var onSaveNeeded: (() -> Void)?

    // MARK: - 动态计算属性

    /// 获取当前活跃数据库的物理路径 (@SR-02: 确保数据库位于沙盒私有目录)
    var dbPath: URL {
        // 通过 PRAGMA 获取路径，避开 GRDB internal 属性访问限制
        let path: String = (try? DatabaseManager.shared.dbWriter?.read { db in
            let row = try Row.fetchOne(db, sql: "PRAGMA database_list")
            return row?["file"] as? String
        }) ?? ""
        return URL(fileURLWithPath: path)
    }

    // MARK: - 初始化
    
    /// 初始化存储门面
    /// - Parameter providedURL: 可选的数据库路径（主要用于测试）
    init(dbURL providedURL: URL? = nil) {
        print("🗄️ [SQLiteStore] 正在初始化存储门面...")
        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dbPath = providedURL ?? docsDir.appendingPathComponent(AppConstants.Storage.databaseName)
        
        // 1. 完整性校验 (@SR-04: 安全性增强)
        if !DatabaseManager.shared.isInTesting && dbPath.scheme == "file" && FileManager.default.fileExists(atPath: dbPath.path) {
            if !SecurityManager.shared.verifyIntegrity(for: dbPath) {
                Logger.shared.addLog(action: .error, target: "SQLiteStore", details: "Database integrity check failed!", module: "Storage")
            }
        }

        do {
            // 2. 初始化 GRDB 管理器 (@PR-05: 冷启动优化)
            try DatabaseManager.shared.setup(at: dbPath)
            guard let writer = DatabaseManager.shared.dbWriter else {
                throw DatabaseError.initializationFailed
            }
            self.repository = KnowledgePageStore(dbWriter: writer)
            self.embeddingManager = EmbeddingManager(repository: repository)

            // 3. 执行旧数据迁移
            migrateLegacyJSONIfNeeded(docsDir: docsDir)

            // 4. 启动响应式观察 (@SRS-6.4: 状态同步驱动)
            setupObservation(with: DatabaseManager.shared.dbWriter)
        } catch {
            fatalError("❌ [SQLiteStore] Failed to initialize Database: \(error)")
        }

        // 初始化/更新签名 (测试环境跳过)
        if !DatabaseManager.shared.isInTesting {
            SecurityManager.shared.updateSignature(for: dbPath)
        }

        // 启动后台向量同步 (@RR-01: 最终一致性保障)
        Task {
            await embeddingManager.syncEmbeddings(pages: pages)
        }
    }

    // MARK: - 观察逻辑 (Observation)

    private func setupObservation(with dbWriter: (any DatabaseWriter)?) {
        guard let dbWriter = dbWriter else { return }
        observationTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.startObservation(on: dbWriter)
            } catch {
                Logger.shared.addLog(action: .error, target: "SQLiteStore", details: "ValueObservation failed: \(error.localizedDescription)")
            }
        }
    }

    private func startObservation(on reader: some DatabaseReader) async throws {
        let observation = ValueObservation.tracking { db in
            try KnowledgePage.order(Column("updated").desc).fetchAll(db)
        }

        for try await latestPages in observation.values(in: reader) {
            self.pages = latestPages
            await self.embeddingManager.syncEmbeddings(pages: latestPages)
        }
    }

    // MARK: - 生命周期管理

    func close() {
        observationTask?.cancel()
        observationTask = nil
    }

    func resetDatabase() throws {
        close()
        let path = dbPath
        DatabaseManager.shared.reset()

        if FileManager.default.fileExists(atPath: path.path) {
            try FileManager.default.removeItem(at: path)
        }

        try DatabaseManager.shared.setup(at: path)
        setupObservation(with: DatabaseManager.shared.dbWriter)
        Logger.shared.addLog(action: .systemInit, target: "SQLiteStore", details: "Database reset.")
    }

    deinit {
        observationTask?.cancel()
    }
}

// MARK: - AnyPageStore 协议实现

@MainActor
extension SQLiteStore: AnyPageStore {
    @discardableResult
    func createPage(title: String, type: PageType, content: String, tags: [String], sourceURL: String?, rawSnippet: String?, fileSize: Int64?, sourceType: String?, forceDeepScan: Bool) -> KnowledgePage {
        createPage(title: title, type: type, customIcon: nil, content: content, tags: tags, sourceURL: sourceURL, rawSnippet: rawSnippet, fileSize: fileSize, sourceType: sourceType, forceDeepScan: forceDeepScan)
    }
    
    func addLog(action: LogAction, target: String, details: String, duration: TimeInterval?, startTime: Date?, endTime: Date?, module: String?) {
        Logger.shared.addLog(action: action, target: target, details: details, duration: duration, startTime: startTime, endTime: endTime, module: module ?? "SQLiteStore")
    }
}

extension SQLiteStore: @unchecked Sendable {}
