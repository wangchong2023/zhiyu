// SQLiteStore.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：本文件实现了知识管理系统的中央存储门面（SQLiteStore），作为整个应用层与底层持久化层之间的核心桥梁。
// 核心职责：
// 1. 响应式数据流管理：基于 GRDB 的 ValueObservation 机制实现数据库与内存状态同步。
// 2. 组件聚合：整合 KnowledgePageStore (CRUD) 与 EmbeddingManager (向量检索)。
// 3. 跨层级协调：管理数据库连接生命周期、安全性校验及后台向量同步。
//
// @SR-01: 所有用户原始文档严禁在未经授权的情况下上传至云端。
// @RR-01: 数据库事务必须满足 ACID 特性，确保在进程崩溃时数据不损坏。
// @PR-05: 数据库冷启动加载时间目标值 < 1.0s。
//
// 版本: 1.7 (Final Polish)
// 修改记录:
//   - 2026-05-16: 终极重构：合并协议实现与内部方法，解决所有冲突，确保三端一致性。
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
    let knowledgeRepository: any KnowledgeRepository
    /// 向量与分块仓储
    let vectorRepository: any VectorRepository
    /// AI 治理与观测性仓储
    let governanceRepository: any GovernanceRepository
    
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
        DatabaseManager.shared.dbURL ?? URL(fileURLWithPath: "")
    }
    
    /// 总页面计数
    var totalPages: Int { pages.count }

    // MARK: - 初始化
    
    init(dbURL providedURL: URL? = nil) {
        print("🗄️ [SQLiteStore] 正在初始化存储门面...")
        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dbPath = providedURL ?? docsDir.appendingPathComponent(AppConstants.Storage.databaseName)
        
        do {
            try DatabaseManager.shared.setup(at: dbPath)
            guard let writer = DatabaseManager.shared.dbWriter else {
                throw DatabaseError.initializationFailed
            }
            
            self.knowledgeRepository = KnowledgePageRepository(dbWriter: writer)
            self.vectorRepository = VectorDataRepository(dbWriter: writer)
            self.governanceRepository = AIGovernanceRepository(dbWriter: writer)
            self.embeddingManager = EmbeddingManager(repository: vectorRepository)

            Task {
                await embeddingManager.loadInitialCache()
                await embeddingManager.syncEmbeddings(pages: pages)
            }

            setupObservation(with: DatabaseManager.shared.dbWriter)
        } catch {
            fatalError("❌ [SQLiteStore] Failed to initialize Database: \(error)")
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
            try KnowledgePage.order(KnowledgePage.Columns.updatedAt.desc).fetchAll(db)
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
    }
    
    func reloadFromDisk() {
        Task {
            if let all = try? await knowledgeRepository.fetchAll() {
                self.pages = all
            }
        }
    }

    deinit {
        observationTask?.cancel()
    }
    
    // MARK: - 事务与数据注入
    
    func performBatchWrite(_ block: @escaping (Database) throws -> Void) throws {
        guard let writer = DatabaseManager.shared.dbWriter else { throw DatabaseError.initializationFailed }
        try writer.write { db in try block(db) }
    }
    
    func seedDefaultContent(onLog: @escaping (LogAction, String, String) -> Void) async {
        do {
            _ = try DemoDataGenerator.generate(in: self)
            onLog(.systemInit, "Seed", "Demo data generated.")
        } catch {
            onLog(.error, "Seed", "Failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - CRUD 核心业务接口

extension SQLiteStore {
    
    /// 对齐 AnyPageStore 协议的统一创建接口
    @discardableResult
    func createPage(
        title: String,
        type: PageType,
        customIcon: String? = nil,
        content: String = "",
        tags: [String] = [],
        sourceURL: String? = nil,
        rawSnippet: String? = nil,
        fileSize: Int64? = nil,
        sourceType: String? = nil,
        forceDeepScan: Bool = false
    ) async -> KnowledgePage {
        let page = KnowledgePage(
            title: title,
            pageType: type,
            customIcon: customIcon,
            content: content,
            tags: tags,
            sourceURL: sourceURL,
            rawTextSnippet: rawSnippet,
            fileSize: fileSize,
            sourceType: sourceType
        )
        try? await knowledgeRepository.save(page)
        return page
    }
    
    func updatePage(_ page: KnowledgePage, forceDeepScan: Bool) async {
        try? await knowledgeRepository.save(page)
    }
    
    func deletePage(_ page: KnowledgePage) async {
        try? await knowledgeRepository.delete(id: page.id)
    }
    
    func replaceAllPages(_ pages: [KnowledgePage]) async {
        try? await knowledgeRepository.deleteAll()
        try? await knowledgeRepository.saveAll(pages)
    }
    
    func syncRemotePage(_ page: KnowledgePage) async {
        try? await knowledgeRepository.save(page)
    }
    
    // MARK: - 查询与检索
    
    func searchPages(query: String) async -> [KnowledgePage] {
        return (try? await knowledgeRepository.search(query: query)) ?? []
    }
    
    func fetchBacklinksByID(for id: UUID) async -> [KnowledgePage] {
        guard let backlinkIDs = try? await knowledgeRepository.fetchBacklinks(for: id) else { return [] }
        return pages.filter { backlinkIDs.contains($0.id) }
    }
    
    // MARK: - 标签管理
    
    func renameTag(_ oldTag: String, to newTag: String) async {
        try? await knowledgeRepository.renameTag(oldTag, to: newTag)
    }
    
    func deleteTag(_ tag: String) async {
        try? await knowledgeRepository.deleteTag(tag)
    }
    
    // MARK: - 统计
    
    func getStorageStats() -> (databaseSize: Int64, logsSize: Int64, exportsSize: Int64) {
        let dbSize = (try? FileManager.default.attributesOfItem(atPath: dbPath.path)[.size] as? Int64) ?? 0
        return (dbSize, 0, 0)
    }
}

// MARK: - 协议支持

@MainActor
extension SQLiteStore: AnyPageStore {
    func addLog(action: LogAction, target: String, details: String, duration: TimeInterval?, startTime: Date?, endTime: Date?, module: String?) {
        Logger.shared.addLog(action: action, target: target, details: details, duration: duration, startTime: startTime, endTime: endTime, module: module ?? "SQLiteStore")
    }
    // 注意：createPage, updatePage 已在主类/扩展中实现，自动匹配协议。
}

extension SQLiteStore: @unchecked Sendable {}
