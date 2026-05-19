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
//   - 2026-05-16: DIP 重构：将 pageStore 依赖改为 any AnyPageStoreCapabilities 协议。
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

    // ── UI 状态 ──
    public var pendingCoachMark: CoachMarkType? = nil
    
    // ── 转发指标 (由专用 Store 持有) ──
    public var pages: [KnowledgePage] { knowledgeStore.pages }
    public var totalPages: Int { knowledgeStore.totalPages }
    public var totalWords: Int { knowledgeStore.totalWords }
    public var isScanning: Bool { knowledgeStore.isScanning }
    public var isScanningAI: Bool { isScanning }
    public var showCreateSheet: Bool {
        get { knowledgeStore.showCreateSheet }
        set { knowledgeStore.showCreateSheet = newValue }
    }

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
    @ObservationIgnored @Inject var pageStore: any AnyPageStoreCapabilities
    @ObservationIgnored @Inject var pageManager: KnowledgePageManager
    @ObservationIgnored @Inject var maintenanceService: MaintenanceService
    @ObservationIgnored @Inject var logger: any LoggerProtocol
    @ObservationIgnored @Inject var performanceService: PerformanceService
    @ObservationIgnored @Inject var llmService: LLMService
    @ObservationIgnored @Inject var settingsStore: SettingsStore
    @ObservationIgnored @Inject var linkService: LinkService
    @ObservationIgnored @Inject var backupService: BackupService
    @ObservationIgnored @Inject var undoService: UndoService
    @ObservationIgnored @Inject var ingestService: IngestService
    @ObservationIgnored @Inject var securityService: VaultStorageSecurityService
    @ObservationIgnored @Inject var snapshotService: SnapshotService

    // ── 职责解耦：子 Store 聚合 ──
    @ObservationIgnored public var searchStore: SearchStore!
    @ObservationIgnored public var aiWorkflowStore: AIWorkflowStore!
    @ObservationIgnored public var tagStore: TagStore!
    @ObservationIgnored public var knowledgeStore: KnowledgeStore!
    
    public var aiInsightStore: AIInsightStore { aiWorkflowStore.insightStore }

    // ── 私有属性 ──
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    // MARK: - 初始化
    
    public init() {
        print("🏛️ [AppStore] 正在初始化核心引擎...")
        
        // 1. 初始化子 Store
        self.searchStore = SearchStore()
        self.aiWorkflowStore = AIWorkflowStore()
        self.tagStore = TagStore()
        self.knowledgeStore = KnowledgeStore()
        
        // 2. 将核心 Store 及子 Store 自动注册到全局 DI 容器中 (@DIP)
        // 确保无论生产环境还是单元测试环境，只要 AppStore 被实例化，其内部的子 Store 均立即可供 @Inject 注入
        // 这样可以彻底打通测试沙盒数据流，并防止因测试多实例覆盖导致的数据订阅和状态不一致问题
        let container = ServiceContainer.shared
        container.register(self, for: AppStore.self)
        container.register(self.searchStore, for: SearchStore.self)
        container.register(self.aiWorkflowStore, for: AIWorkflowStore.self)
        container.register(self.aiWorkflowStore as any AIWorkflowCapabilities, for: (any AIWorkflowCapabilities).self)
        container.register(self.aiWorkflowStore.insightStore, for: AIInsightStore.self)
        container.register(self.tagStore, for: TagStore.self)
        container.register(self.knowledgeStore, for: KnowledgeStore.self)
        
        // 3. 注册系统事件订阅
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        AppEventBus.shared.subscribe()
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .pagesCleared:
                    // 仅处理应用层清理逻辑
                    break
                case .pageCreated, .pageUpdated, .pageDeleted:
                    // 页面事件由 KnowledgeStore 处理，AppStore 仅负责跨模块协调（如 Insight 更新）
                    Task { [weak self] in
                        await self?.aiInsightStore.updateStatistics()
                    }
                case .clearAllDataRequested:
                    self.clearAllDeveloperData()
                default: break
                }
            }
            .store(in: &cancellables)
            
        // 动态绑定物理专属数据库热切换监听
        NotificationCenter.default.publisher(for: .databaseDidSwitch)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                print("🔄 [AppStore] 监测到专属物理库热切换成功...")
                Task { [weak self] in
                    await self?.aiInsightStore.updateStatistics()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - 基础管理

    public func refresh() async {
        await knowledgeStore.refresh()
        await aiInsightStore.updateStatistics()
    }

    func seedDefaultContent() async {
        await knowledgeStore.seedDefaultContent()
    }

    // ── 核心业务逻辑 ──

    public func pageByTitle(_ title: String) async -> KnowledgePage? {
        await knowledgeStore.pageByTitle(title)
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
        await knowledgeStore.createPage(
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

    public func getBacklinks(for id: UUID) async -> [KnowledgePage] { await pageStore.fetchBacklinksByID(for: id) }

    public func updatePage(_ page: KnowledgePage, forceDeepScan: Bool) async {
        await knowledgeStore.updatePage(page)
    }

    public func savePage(_ page: KnowledgePage) async {
        await knowledgeStore.savePage(page)
    }

    public func deletePage(_ page: KnowledgePage) async {
        await knowledgeStore.deletePage(page)
    }

    func undo() async {
        await knowledgeStore.undo()
    }

    func redo() async {
        await knowledgeStore.redo()
    }

    func saveToDisk() async {
        await knowledgeStore.saveToDisk()
    }

    func loadFromDisk() async { 
        await knowledgeStore.loadFromDisk()
    }

    public func requestRelayout() {
        AppEventBus.shared.publish(.graphRelayoutRequested)
    }

    public nonisolated func addLog(action: LogAction, target: String, details: String, duration: TimeInterval? = nil, startTime: Date? = nil, endTime: Date? = nil, module: String? = "AppStore") {
        Logger.shared.addLog(action: action, target: target, details: details, duration: duration, startTime: startTime, endTime: endTime, module: module)
    }

    func clearLogs() async { await maintenanceService.clearLogs() }
}

// MARK: - AppStore 业务扩展
extension AppStore: CollaborationDelegate {
    @discardableResult
    func generateDemoData() async -> Int {
        let count = await maintenanceService.generateDemoData()
        if count > 0 { await refresh() }
        return count
    }

    public func applyPotentialLink(_ suggestion: PotentialLinkSuggestion) async {
        await knowledgeStore.applyPotentialLink(suggestion)
    }

    func applyRefactorSuggestion(_ suggestion: RefactorSuggestion) async {
        await knowledgeStore.applyRefactorSuggestion(suggestion)
    }

    public func applyRemoteUpdate(_ page: KnowledgePage) async {
        await knowledgeStore.updatePage(page)
    }

    public func insertRemotePage(_ page: KnowledgePage) async {
        await pageStore.syncRemotePage(page)
        await refresh()
    }

    func renamePage(_ page: KnowledgePage, to newTitle: String) async {
        await knowledgeStore.renamePage(page, to: newTitle)
    }

    func clearAllDeveloperData() {
        Task {
            await maintenanceService.clearAllDeveloperData()
            searchStore.clearAll()
            settingsStore.reset()
            aiWorkflowStore.clearAll()
            await refresh()
        }
    }

    func ingestFolder(at url: URL) async {
        // 转发至领域层 KnowledgePageManager 执行物理和向量导入流程
        await pageManager.ingestFolder(at: url, pageStore: self)
        await knowledgeStore.refresh()
    }

    // MARK: - 标签管理 (转发至 TagStore)

    public func getAllTags() -> [String: Int] {
        tagStore.getAllTags(from: pages)
    }

    public func renameTag(_ oldTag: String, to newTag: String) async {
        await tagStore.renameTag(old: oldTag, to: newTag)
        await knowledgeStore.refresh()
    }

    public func deleteTag(_ tag: String) async {
        await tagStore.deleteTag(tag)
        await knowledgeStore.refresh()
    }

    public func bulkDeleteTags(_ tags: [String]) async {
        await tagStore.bulkDeleteTags(tags)
        await knowledgeStore.refresh()
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
        await knowledgeStore.refresh()
        return knowledgeStore.pages
    }

    public func reloadFromDisk() async {
        await knowledgeStore.loadFromDisk()
    }

    public func replaceAllPages(_ newPages: [KnowledgePage]) async {
        await knowledgeStore.saveToDisk() // 这里原逻辑可能有误，通常是覆盖磁盘
        // 修正为：
        await pageStore.replaceAllPages(newPages)
        await knowledgeStore.refresh()
    }

    public func resetDatabase() async throws {
        try await pageStore.resetDatabase()
        await knowledgeStore.refresh()
    }

    public func performBatchWrite(_ block: @escaping @Sendable (Database) throws -> Void) async throws {
        try await pageStore.performBatchWrite(block)
        await knowledgeStore.refresh()
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
        await knowledgeStore.createPage(
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
        await knowledgeStore.createPage(
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

    public func updatePage(_ page: KnowledgePage) async throws {
        await knowledgeStore.updatePage(page)
    }

    public func anyUpdatePage(_ page: KnowledgePage, forceDeepScan: Bool) async {
        await knowledgeStore.updatePage(page)
    }

    public func anyDeletePage(_ page: KnowledgePage) async {
        await knowledgeStore.deletePage(page)
    }

    public func syncRemotePage(_ page: KnowledgePage) async {
        await pageStore.syncRemotePage(page)
        await knowledgeStore.refresh()
    }

    public func fetchBacklinksByID(for id: UUID) async -> [KnowledgePage] {
        await pageStore.fetchBacklinksByID(for: id)
    }

    public func searchPages(query: String) async -> [KnowledgePage] {
        await pageStore.searchPages(query: query)
    }

    public func seedDefaultContent(logger: @escaping @Sendable (LogAction, String, String) -> Void) async {
        await knowledgeStore.seedDefaultContent()
    }

    public func getStorageStats() async -> (databaseSize: Int64, logsSize: Int64, exportsSize: Int64) {
        await pageStore.getStorageStats()
    }
}

// MARK: - GraphDataProvider 协议实现
@MainActor
extension AppStore: GraphDataProvider {
    public var clusters: [GraphClusteringService.Cluster] { [] }
    public var isAIProcessing: Bool { isScanningAI }
}
