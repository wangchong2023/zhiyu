// SQLiteStore.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：基于 SQLite 的核心存储引擎。
// 负责物理数据的读写编排与数据库级别的状态同步。
// 版本: 2.2
// 修改记录:
//   - 2026-05-16: 架构升级：重构为 actor，并修正 MainActor 访问冲突。
//   - 2026-05-16: 接口补全：全面遵循 AnyPageStore 协议。
// 版权: © 2026 Wang Chong。保留所有权利。

import Foundation
import Combine
import GRDB

/// 核心持久化存储引擎 (L1Actor)
/// 采用 actor 模式确保多端并发下的数据一致性，封装复杂的 SQL 事务。
public actor SQLiteStore: AnyPageStoreCapabilities {
    
    // ── 内存缓存 ──
    private var _pages: [KnowledgePage] = []
    
    // ── 物理写入器 ──
    private let dbWriter: any DatabaseWriter
    
    // ── 仓库依赖 (DI) ──
    private let knowledgeRepository: any KnowledgeRepository
    private let vectorRepository: any VectorRepository
    private let governanceRepository: any GovernanceRepository
    
    // ── 助手服务 ──
    public let embeddingManager: EmbeddingManager

    // MARK: - 初始化
    
    public init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
        let knowledgeRepo = KnowledgePageRepository(dbWriter: dbWriter)
        let vectorRepo = VectorDataRepository(dbWriter: dbWriter)
        let governanceRepo = AIGovernanceRepository(dbWriter: dbWriter)
        
        self.knowledgeRepository = knowledgeRepo
        self.vectorRepository = vectorRepo
        self.governanceRepository = governanceRepo
        self.embeddingManager = EmbeddingManager(repository: vectorRepo)
        
        // 初始同步
        Task {
            await reloadFromDisk()
        }
    }

    // MARK: - 基础访问 (AnyPageStoreCapabilities)
    
    public var pages: [KnowledgePage] { _pages }
    
    public func reloadFromDisk() async {
        _pages = (try? await knowledgeRepository.fetchAll()) ?? []
    }

    /// 全量获取页面列表
    public func fetchAllPages() async throws -> [KnowledgePage] {
        try await knowledgeRepository.fetchAll()
    }

    // MARK: - 页面操作

    public func createPage(
        title: String,
        pageType: PageType,
        customIcon: String? = nil,
        content: String = "",
        tags: [String] = [],
        sourceURL: String? = nil,
        rawSnippet: String? = nil,
        fileSize: Int64? = nil,
        sourceType: String? = nil
    ) async throws -> KnowledgePage {
        let page = KnowledgePage(
            title: title,
            pageType: pageType,
            customIcon: customIcon,
            content: content,
            tags: tags,
            sourceURL: sourceURL,
            rawTextSnippet: rawSnippet,
            fileSize: fileSize,
            sourceType: sourceType
        )
        try await knowledgeRepository.save(page)
        await reloadFromDisk()
        return page
    }
    
    public func updatePage(_ page: KnowledgePage) async throws {
        try await knowledgeRepository.save(page)
        await reloadFromDisk()
    }
    
    public func deletePage(_ page: KnowledgePage) async throws {
        try await knowledgeRepository.delete(id: page.id)
        await reloadFromDisk()
    }

    public func syncRemotePage(_ page: KnowledgePage) async {
        _ = try? await knowledgeRepository.save(page)
        await reloadFromDisk()
    }

    public func resetDatabase() async throws {
        // 核心步骤：直接使用绑定的局部 dbWriter 进行数据清空，不再强耦合 MainActor 全局单例
        try await dbWriter.erase()
        _pages = []
    }

    // MARK: - 搜索与关联

    public func searchPages(query: String) async -> [KnowledgePage] {
        return (try? await knowledgeRepository.search(query: query)) ?? []
    }

    public func fetchBacklinksByID(for id: UUID) async -> [KnowledgePage] {
        let backlinkIDs = (try? await knowledgeRepository.fetchBacklinks(for: id)) ?? []
        return _pages.filter { backlinkIDs.contains($0.id) }
    }
    
    // MARK: - 标签管理
    
    public func renameTag(_ oldTag: String, to newTag: String) async {
        _ = try? await knowledgeRepository.renameTag(old: oldTag, to: newTag)
        await reloadFromDisk()
    }
    
    public func deleteTag(_ tag: String) async {
        _ = try? await knowledgeRepository.deleteTag(tag)
        await reloadFromDisk()
    }
    
    // MARK: - 统计与系统

    /// 获取存储资源统计信息，级联累加多笔记本分库及全局配置库大小
    /// - Returns: 数据库总大小、日志总大小、导出文件总大小 (字节)
    public func getStorageStats() async -> (databaseSize: Int64, logsSize: Int64, exportsSize: Int64) {
        let (dbPath, globalDBPath) = await MainActor.run {
            (DatabaseManager.shared.dbURL?.path ?? "", DatabaseManager.shared.globalDBURL?.path ?? "")
        }
        
        var totalDbSize: Int64 = 0
        
        // 1. 累加当前活跃的专属笔记本数据库物理文件大小及其 WAL/SHM 缓存文件
        if !dbPath.isEmpty {
            totalDbSize += (try? FileManager.default.attributesOfItem(atPath: dbPath)[.size] as? Int64) ?? 0
            
            let walPath = dbPath + "-wal"
            let shmPath = dbPath + "-shm"
            totalDbSize += (try? FileManager.default.attributesOfItem(atPath: walPath)[.size] as? Int64) ?? 0
            totalDbSize += (try? FileManager.default.attributesOfItem(atPath: shmPath)[.size] as? Int64) ?? 0
        }
        
        // 2. 累加全局主配置库大小及其 WAL/SHM 缓存文件
        if !globalDBPath.isEmpty {
            totalDbSize += (try? FileManager.default.attributesOfItem(atPath: globalDBPath)[.size] as? Int64) ?? 0
            
            let globalWalPath = globalDBPath + "-wal"
            let globalShmPath = globalDBPath + "-shm"
            totalDbSize += (try? FileManager.default.attributesOfItem(atPath: globalWalPath)[.size] as? Int64) ?? 0
            totalDbSize += (try? FileManager.default.attributesOfItem(atPath: globalShmPath)[.size] as? Int64) ?? 0
        }
        
        // 3. 级联遍历扫描沙盒目录，累加其他非激活状态笔记本专属库大小
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let vaultsDir = appSupport.appendingPathComponent(AppConstants.Storage.vaultsDirectoryName)
        
        if let fileURLs = try? FileManager.default.contentsOfDirectory(at: vaultsDir, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) {
            for fileURL in fileURLs {
                let isSqlite = fileURL.pathExtension == "sqlite3" || fileURL.pathExtension == "sqlite"
                let isCompanion = fileURL.path.hasSuffix("-wal") || fileURL.path.hasSuffix("-shm")
                
                if isSqlite || isCompanion {
                    // 排除已经累计过的当前活跃库路径
                    if !dbPath.isEmpty && !fileURL.path.hasPrefix(dbPath) {
                        let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey])
                        if let fileSize = resourceValues?.fileSize {
                            totalDbSize += Int64(fileSize)
                        }
                    }
                }
            }
        }
        
        return (totalDbSize, 0, 0)
    }
    
    /// 执行批量数据库写入操作 (在隔离环境内)
    public func performBatchWrite(_ block: @escaping @Sendable (Database) throws -> Void) async throws {
        // 核心步骤：直接使用局部的 dbWriter 执行写入，实现 100% 线程安全的隔离事务
        try await dbWriter.write { db in try block(db) }
    }
    
    /// 填充默认引导内容
    public func seedDefaultContent(logger: @escaping @Sendable (LogAction, String, String) -> Void) async {
        let pagesToCreate: [(String, PageType, String, [String])] = [
            (L10n.Common.Demo.Welcome.title, .concept, L10n.Common.Demo.Welcome.content, [L10n.Common.Demo.Welcome.tag1, L10n.Common.Demo.Welcome.tag2, L10n.Common.Demo.Welcome.tag3]),
            (L10n.Common.Demo.aiAgent.title, .concept, L10n.Common.Demo.aiAgent.content, ["AI", "Agent"]),
            (L10n.Common.Demo.planning.title, .concept, L10n.Common.Demo.planning.content, ["AI", "Planning"]),
            (L10n.Common.Demo.memory.title, .concept, L10n.Common.Demo.memory.content, ["AI", "Memory", "RAG"])
        ]
        
        for (title, type, content, tags) in pagesToCreate {
            _ = try? await createPage(title: title, pageType: type, content: content, tags: tags)
            logger(.create, title, "Seeded default content")
        }
    }

    public func replaceAllPages(_ newPages: [KnowledgePage]) async {
        try? await performBatchWrite { db in
            try KnowledgePage.deleteAll(db)
            for p in newPages { try p.insert(db) }
        }
        await reloadFromDisk()
    }
}

// MARK: - 类型抹除适配 (AnyPageStore)

extension SQLiteStore {
    public func anyCreatePage(
        title: String,
        pageType: PageType,
        customIcon: String?,
        content: String,
        tags: [String],
        sourceURL: String?,
        rawSnippet: String?,
        fileSize: Int64?,
        sourceType: String?,
        forceDeepScan: Bool
    ) async -> KnowledgePage {
        (try? await createPage(
            title: title,
            pageType: pageType,
            customIcon: customIcon,
            content: content,
            tags: tags,
            sourceURL: sourceURL,
            rawSnippet: rawSnippet,
            fileSize: fileSize,
            sourceType: sourceType
        )) ?? KnowledgePage(title: title, pageType: pageType)
    }

    public func anyUpdatePage(_ page: KnowledgePage, forceDeepScan: Bool) async {
        _ = try? await updatePage(page)
    }
    
    public func anyDeletePage(_ page: KnowledgePage) async {
        _ = try? await deletePage(page)
    }

    public nonisolated func addLog(action: LogAction, target: String, details: String, duration: TimeInterval?, startTime: Date?, endTime: Date?, module: String?) {
        // 存储引擎层不直接记录日志，由上层协调
    }
}
