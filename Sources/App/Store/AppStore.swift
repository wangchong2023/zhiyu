// AppStore.swift
//
// 作者: Wang Chong
// 功能说明: [L3] 应用调度层：本文件实现了知识管理系统的核心状态中心（AppStore），作为应用的数据聚合层与协调中心。
// 它通过“外观模式 (Facade)”整合了底层存储、AI 工作流、链接检查及协作服务，为 UI 层提供统一的数据接口。
// 核心职责包括：
// 1. 状态生命周期管理：通过 @Observable 驱动全局 UI 的响应式刷新，管理 store 的冷热启动同步。
// 2. 跨领域协同：协调 LLM 摄入、向量检索、双向链接更新及本地化设置。
// 3. 事务性业务逻辑：封装页面创建、重命名、删除等具备副作用的操作，集成撤销/重做机制。
// 4. 多平台适配桥接：作为全平台共享的代码入口，屏蔽底层各组件的依赖细节。
// 版本: 1.8
// 修改记录:
//   - 2026-05-16: 架构升级：重构为 actor 化存储后的异步对齐。
//   - 2026-05-16: 职责剥离：将 PDF/OCR 业务迁移至 IngestStore，标签/统计下沉至独立 Store。
//   - 2026-05-16: 初始化优化：移除 @Observable 对子 Store 的 lazy 干扰，采用手动初始化。
//   - 2026-05-16: DIP 重构：将 sqliteStore 依赖改为 any AnyPageStoreCapabilities 协议。
// 版权: © 2026 Wang Chong。保留所有权利。

import SwiftUI
import Combine
import Observation
import GRDB

/// 智宇核心状态中心 (L3-Facade)
/// 负责全局状态同步、跨服务协调及业务流程封装。
@Observable
@MainActor
public final class AppStore {
    
    // MARK: - 辅助类型
    
    /// 引导层类型定义
    public enum CoachMarkType: String, Sendable {
        case graphDiscovery = "graph_discovery"
    }

    /// 工具项定义
    public enum ToolItem: String, CaseIterable, Hashable {
        case pageList = "index"
        case dashboard = "dashboard"
        case tagCloud = "tagCloud"
        case taskCenter = "chat"
        case chat = "chat_ai"
        case synthesis = "synthesis"
        case weeklyReport = "weeklyReport"
        case log = "log"
        case collab = "collab"
        case pluginMarket = "pluginMarket"
        case search = "search"
        case ingest = "ingest"
        case graph = "graph"
        case lint = "lint"
        case healthCheck = "healthCheck"
        case sources = "sources"
    }

    /// 知识增长点数据模型
    public struct KnowledgeGrowthPoint: Identifiable {
        public let id = UUID()
        public let date: Date
        public let count: Int
        
        public init(date: Date, count: Int) {
            self.date = date
            self.count = count
        }
    }

    // ── 基础状态 ──
    public var pages: [KnowledgePage] = []
    public var totalPages: Int = 0
    public var totalWords: Int = 0
    public var isScanning: Bool = false
    public var isScanningAI: Bool { isScanning }
    public var pendingCoachMark: CoachMarkType? = nil
    
    // ── UI 状态 ──
    public var showCreateSheet: Bool = false

    // ── 转发指标 (由专用 Store 持有) ──
    public var brokenLinkCount: Int { aiInsightStore.brokenLinkCount }
    public var orphanPageCount: Int { aiInsightStore.orphanPageCount }
    public var totalConnectionCount: Int { aiInsightStore.totalConnectionCount }
    public var tags: [String] { Array(tagStore.getAllTags(from: pages).keys).sorted() }
    public var sourceCount: Int { aiInsightStore.sourceCount }
    public var entityCount: Int { aiInsightStore.entityCount }
    public var conceptCount: Int { aiInsightStore.conceptCount }
    public var growthSeries: [KnowledgeGrowthPoint] { aiInsightStore.growthSeries }
    public var lintIssues: [LintIssue] { aiWorkflowStore.lintIssues }
    public var isPrivacyModeEnabled: Bool { settingsStore.isPrivacyModeEnabled }
    public var showPerfDashboard: Bool {
        get { settingsStore.showPerfDashboard }
        set { settingsStore.showPerfDashboard = newValue }
    }

    // ── 核心依赖 (DI) ──
    @ObservationIgnored @Inject var sqliteStore: any AnyPageStoreCapabilities
    @ObservationIgnored @Inject var linkService: LinkService
    @ObservationIgnored @Inject var ingestService: IngestService
    @ObservationIgnored @Inject var undoService: UndoService
    @ObservationIgnored @Inject var backupService: BackupService
    @ObservationIgnored @Inject var logger: any LoggerProtocol
    @ObservationIgnored @Inject var performanceService: PerformanceService
    @ObservationIgnored @Inject var llmService: any LLMServiceProtocol
    @ObservationIgnored @Inject var snapshotService: SnapshotService
    @ObservationIgnored @Inject var insightService: KnowledgeInsightService
    @ObservationIgnored @Inject var securityService: VaultStorageSecurityService

    // ── 职责解耦：子 Store 聚合 ──
    @ObservationIgnored public var searchStore: SearchStore!
    @ObservationIgnored public var settingsStore: SettingsStore!
    @ObservationIgnored public var aiWorkflowStore: AIWorkflowStore!
    @ObservationIgnored public var tagStore: TagStore!
    
    public var aiInsightStore: AIInsightStore { aiWorkflowStore.insightStore }

    // ── 私有属性 ──
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    // MARK: - 初始化
    
    public init() {
        print("🏛️ [AppStore] 正在初始化核心引擎...")
        
        // 1. 初始化子 Store (顺序敏感)
        self.searchStore = SearchStore()
        self.settingsStore = SettingsStore()
        self.aiWorkflowStore = AIWorkflowStore()
        self.tagStore = TagStore()
        
        // 2. 注册系统事件订阅
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        AppEventBus.shared.subscribe()
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .pagesCleared:
                    self.pages = []
                    self.totalPages = 0
                case .pageCreated, .pageUpdated, .pageDeleted:
                    // 采用弱引用 [weak self] 捕获，防止强引用闭包延长生命周期导致测试环境 Race Condition 崩溃 (@SRS-7.1)
                    Task { [weak self] in
                        await self?.refresh()
                    }
                case .clearAllDataRequested:
                    self.clearAllDeveloperData()
                default: break
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - 基础管理

    public func refresh() async {
        let startTime = Date()
        self.pages = (try? await sqliteStore.fetchAllPages()) ?? []
        self.totalPages = pages.count
        self.totalWords = pages.reduce(0) { $0 + $1.content.count }
        
        let duration = Date().timeIntervalSince(startTime)
        performanceService.record(.databaseLoad, duration: duration)
        
        // 触发子 Store 同步数据
        await aiInsightStore.updateStatistics()
    }

    func seedDefaultContent() async {
        if pages.isEmpty {
            await sqliteStore.seedDefaultContent { [weak self] a, t, d in
                guard let self = self else { return }
                self.addLog(action: a, target: t, details: d)
            }
        }
    }

    // ── 核心业务逻辑 ──

    public func pageByTitle(_ title: String) async -> KnowledgePage? {
        await linkService.pageByTitle(title, in: pages)
    }

    @discardableResult
    public func createPage(
        title: String,
        pageType: PageType,
        customIcon: String? = nil,
        content: String = "",
        tags: [String] = [],
        sourceURL: String? = nil,
        rawSnippet: String? = nil,
        fileSize: Int64? = nil,
        sourceType: String? = nil,
        forceDeepScan: Bool = false
    ) async -> KnowledgePage {
        undoService.pushSnapshot(pages)

        let page = (try? await sqliteStore.createPage(
            title: title,
            pageType: pageType,
            customIcon: customIcon,
            content: content,
            tags: tags,
            sourceURL: sourceURL,
            rawSnippet: rawSnippet,
            fileSize: fileSize,
            sourceType: sourceType
        )) ?? KnowledgePage(title: title)

        backupService.markDirty()

        if totalPages >= 3 && !settingsStore.hasShownGraphCoachMark {
            settingsStore.hasShownGraphCoachMark = true
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            self.pendingCoachMark = .graphDiscovery
        }

        let totalLinks = pages.reduce(0) { $0 + $1.outgoingLinks.count }
        AppEventBus.shared.publish(.pageCreated(id: page.id, title: page.title, nodeCount: pages.count, linkCount: totalLinks))

        return page
    }

    public func getBacklinks(for id: UUID) async -> [KnowledgePage] { await sqliteStore.fetchBacklinksByID(for: id) }

    public func updatePage(_ page: KnowledgePage, forceDeepScan: Bool) async {
        undoService.pushSnapshot(pages)
        _ = try? await sqliteStore.updatePage(page)
        backupService.markDirty()
        let totalLinks = pages.reduce(0) { $0 + $1.outgoingLinks.count }
        AppEventBus.shared.publish(.pageUpdated(id: page.id, nodeCount: pages.count, linkCount: totalLinks))
    }

    public func savePage(_ page: KnowledgePage) async {
        await updatePage(page, forceDeepScan: false)
        PluginRegistry.shared.emitEvent("onPageSave", data: page.id.uuidString)
    }

    public func deletePage(_ page: KnowledgePage) async {
        undoService.pushSnapshot(pages)
        _ = try? await sqliteStore.deletePage(page)
        AppEventBus.shared.publish(.pageDeleted(id: page.id))
        PluginRegistry.shared.emitEvent("onPageDelete", data: page.id.uuidString)
    }

    func undo() async {
        if let prev = undoService.undo(currentPages: pages) {
            await sqliteStore.replaceAllPages(prev)
            await refresh()
        }
    }

    func redo() async {
        if let next = undoService.redo(currentPages: pages) {
            await sqliteStore.replaceAllPages(next)
            await refresh()
        }
    }

    func saveToDisk() async {
        await logger.saveToDisk()
        backupService.createBackup(pages: pages)
    }

    func loadFromDisk() async { await sqliteStore.reloadFromDisk(); await logger.loadFromDisk() }

    public func requestRelayout() {
        AppEventBus.shared.publish(.graphRelayoutRequested)
    }

    public nonisolated func addLog(action: LogAction, target: String, details: String, duration: TimeInterval? = nil, startTime: Date? = nil, endTime: Date? = nil, module: String? = "AppStore") {
        Logger.shared.addLog(action: action, target: target, details: details, duration: duration, startTime: startTime, endTime: endTime, module: module)
    }

    func clearLogs() async { await logger.clearAllLogs() }
}

// MARK: - AppStore 业务扩展
extension AppStore: CollaborationDelegate {
    @discardableResult
    func generateDemoData() async -> Int {
        do {
            guard let engine = sqliteStore as? SQLiteStore else { return 0 }
            let count = try await DemoDataGenerator.generate(in: engine)
            await refresh()
            return count
        } catch {
            addLog(action: .error, target: "Demo", details: "Failed to generate demo data: \(error.localizedDescription)")
            return 0
        }
    }

    public func applyPotentialLink(_ suggestion: PotentialLinkSuggestion) async {
        guard var page = pages.first(where: { $0.id == suggestion.sourcePageID }) else { return }
        
        let oldContent = page.content
        let newContent = oldContent.replacingOccurrences(
            of: suggestion.targetTitle,
            with: "[[\(suggestion.targetTitle)]]",
            options: .caseInsensitive
        )
        
        if oldContent != newContent {
            page.content = newContent
            await updatePage(page, forceDeepScan: false)
            addLog(action: .update, target: page.title, details: "Applied potential link to [[\(suggestion.targetTitle)]]")
        }
    }

    func applyRefactorSuggestion(_ suggestion: RefactorSuggestion) async {
        if suggestion.type == "rename", let page = pages.first(where: { $0.title == suggestion.target }) {
            await renamePage(page, to: suggestion.suggestion)
        }
        aiWorkflowStore.removeRefactorSuggestion(id: suggestion.id)
    }

    public func applyRemoteUpdate(_ page: KnowledgePage) async {
        _ = try? await sqliteStore.updatePage(page)
        addLog(action: .sync, target: page.title, details: "Remote update applied.")
    }

    public func insertRemotePage(_ page: KnowledgePage) async {
        await sqliteStore.syncRemotePage(page)
        addLog(action: .sync, target: page.title, details: "Remote page inserted.")
    }

    func renamePage(_ page: KnowledgePage, to newTitle: String) async {
        let oldTitle = page.title
        let modifiedPages = await linkService.prepareRename(page: page, to: newTitle, in: pages)

        try? await self.sqliteStore.performBatchWrite { db in
            for p in modifiedPages { try? p.save(db) }
        }
        addLog(action: .update, target: newTitle, details: "Renamed from \(oldTitle)")
        backupService.markDirty()
    }

    func clearAllDeveloperData() {
        Task {
            undoService.clear()
            try? await sqliteStore.resetDatabase()
            
            // 显式重置子 Store，确立单向数据流控制权 (替代被动的 EventBus 监听)
            searchStore.clearAll()
            settingsStore.reset()
            aiWorkflowStore.clearAll()
            
            AppEventBus.shared.publish(.pagesCleared)
            await refresh()
        }
    }

    func ingestFolder(at url: URL) async {
        _ = await ingestService.ingestFolder(at: url, pageStore: self)
        await refresh()
    }

    // MARK: - 标签管理 (转发至 TagStore)

    public func getAllTags() -> [String: Int] {
        tagStore.getAllTags(from: pages)
    }

    public func renameTag(_ oldTag: String, to newTag: String) async {
        await tagStore.renameTag(old: oldTag, to: newTag)
        await refresh()
    }

    public func deleteTag(_ tag: String) async {
        await tagStore.deleteTag(tag)
        await refresh()
    }

    public func bulkDeleteTags(_ tags: [String]) async {
        await tagStore.bulkDeleteTags(tags)
        await refresh()
    }

    public func addNewTag(_ tag: String) {
        tagStore.addNewTag(tag)
    }
}

// MARK: - AnyPageStore 协议实现
@MainActor
extension AppStore: AnyPageStore {
    public var logEntries: [LogEntry] { [] }

    public func fetchAllPages() async throws -> [KnowledgePage] {
        try await sqliteStore.fetchAllPages()
    }

    public func reloadFromDisk() async {
        await sqliteStore.reloadFromDisk()
    }

    public func replaceAllPages(_ newPages: [KnowledgePage]) async {
        try? await sqliteStore.replaceAllPages(newPages)
        await refresh()
    }

    public func resetDatabase() async throws {
        try await sqliteStore.resetDatabase()
    }

    public func performBatchWrite(_ block: @escaping @Sendable (Database) throws -> Void) async throws {
        try await sqliteStore.performBatchWrite(block)
    }

    public func createPage(
        title: String,
        pageType: PageType,
        customIcon: String?,
        content: String,
        tags: [String],
        sourceURL: String?,
        rawSnippet: String?,
        fileSize: Int64?,
        sourceType: String?
    ) async throws -> KnowledgePage {
        try await sqliteStore.createPage(
            title: title,
            pageType: pageType,
            customIcon: customIcon,
            content: content,
            tags: tags,
            sourceURL: sourceURL,
            rawSnippet: rawSnippet,
            fileSize: fileSize,
            sourceType: sourceType
        )
    }

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
        )) ?? KnowledgePage(title: title)
    }

    public func updatePage(_ page: KnowledgePage) async throws {
        try await sqliteStore.updatePage(page)
    }

    public func anyUpdatePage(_ page: KnowledgePage, forceDeepScan: Bool) async {
        await updatePage(page, forceDeepScan: forceDeepScan)
    }

    public func anyDeletePage(_ page: KnowledgePage) async {
        await deletePage(page)
    }

    public func syncRemotePage(_ page: KnowledgePage) async {
        await sqliteStore.syncRemotePage(page)
    }

    public func fetchBacklinksByID(for id: UUID) async -> [KnowledgePage] {
        await sqliteStore.fetchBacklinksByID(for: id)
    }

    public func searchPages(query: String) async -> [KnowledgePage] {
        await sqliteStore.searchPages(query: query)
    }

    public func seedDefaultContent(logger: @escaping @Sendable (LogAction, String, String) -> Void) async {
        await sqliteStore.seedDefaultContent(logger: logger)
    }
}

// MARK: - GraphDataProvider 协议实现
extension AppStore: GraphDataProvider {
    public var clusters: [GraphClusteringService.Cluster] { [] }
    public var isAIProcessing: Bool { isScanningAI }
}
