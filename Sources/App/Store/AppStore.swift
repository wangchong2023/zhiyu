//
//  AppStore.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 应用层
//  核心职责：属于 Store 模块，提供相关的结构体或工具支撑。
//
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
    
    // ── 转发指标 (由 KnowledgeStore 持有，@Observable 自动追踪) ──
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
    @ObservationIgnored @Inject var llmService: any LLMServiceProtocol
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
        print(String(data: Data(base64Encoded: "IFtBcHBTdG9yZV0gSW5pdGlhbGl6aW5nIGNvcmUgZW5naW5lLi4u")!, encoding: .utf8)!)
        
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
                    break
                case .pageCreated, .pageUpdated, .pageDeleted:
                    // 页面事件由 KnowledgeStore 处理，AppStore 仅负责跨模块协调（如 Insight 更新）
                    Task { [weak self] in
                        await self?.aiInsightStore.updateStatistics()
                    }
                default: break
                }
            }
            .store(in: &cancellables)
            
        // 动态绑定物理专属数据库热切换监听
        NotificationCenter.default.publisher(for: .databaseDidSwitch)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                print(String(data: Data(base64Encoded: "IFtBcHBTdG9yZV0gRGV0ZWN0ZWQgZXhjbHVzaXZlIHBoeXNpY2FsIGRhdGFiYXNlIGhvdCBzd2FwIHN1Y2Nlc3MuLi4=")!, encoding: .utf8)!)
                Task { [weak self] in
                    await self?.aiInsightStore.updateStatistics()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - 基础管理

    /// 刷新
    public func refresh() async {
        await knowledgeStore.refresh()
        await aiInsightStore.updateStatistics()
    }

    /// seedDefaultContent
    func seedDefaultContent() async {
        await knowledgeStore.seedDefaultContent()
    }

    // ── 核心业务逻辑 ──

    /// pageByTitle
    /// - Parameter title: title
    /// - Returns: 可选值
    public func pageByTitle(_ title: String) async -> KnowledgePage? {
        await knowledgeStore.pageByTitle(title)
    }

    @discardableResult

    /// 创建Page
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

    /// 获取Backlinks
    /// - Returns: 列表
    public func getBacklinks(for id: UUID) async -> [KnowledgePage] { await pageStore.fetchBacklinksByID(for: id) }

    /// 更新Page
    /// - Parameter page: page
    /// - Parameter forceDeepScan: forceDeep扫描
    public func updatePage(_ page: KnowledgePage, forceDeepScan: Bool) async {
        await knowledgeStore.updatePage(page)
    }

    /// 保存Page
    /// - Parameter page: page
    public func savePage(_ page: KnowledgePage) async {
        await knowledgeStore.savePage(page)
    }

    /// 删除Page
    /// - Parameter page: page
    public func deletePage(_ page: KnowledgePage) async {
        await knowledgeStore.deletePage(page)
    }

    /// 撤销
    func undo() async {
        await knowledgeStore.undo()
    }

    /// 重做
    func redo() async {
        await knowledgeStore.redo()
    }

    /// 保存ToDisk
    func saveToDisk() async {
        await knowledgeStore.saveToDisk()
    }

    /// 加载FromDisk
    func loadFromDisk() async { 
        await knowledgeStore.loadFromDisk()
    }

    /// 请求Relayout
    public func requestRelayout() {
        AppEventBus.shared.publish(.graphRelayoutRequested)
    }

    /// 添加记录日志
    /// - Parameter action: action
    /// - Parameter target: target
    /// - Parameter details: details
    /// - Parameter duration: duration
    /// - Parameter startTime: 启动Time
    /// - Parameter endTime: 结束Time
    /// - Parameter module: module
    public nonisolated func addLog(action: LogAction, target: String, details: String, duration: TimeInterval? = nil, startTime: Date? = nil, endTime: Date? = nil, module: String? = "AppStore") {
        Logger.shared.addLog(action: action, target: target, details: details, duration: duration, startTime: startTime, endTime: endTime, module: module)
    }

    /// 清除Logs
    func clearLogs() async { await maintenanceService.clearLogs() }
}

// MARK: - AppStore 业务扩展
extension AppStore: CollaborationDelegate {
    @discardableResult

    /// 生成DemoData
    /// - Returns: 数值
    func generateDemoData() async -> Int {
        let count = await maintenanceService.generateDemoData()
        if count > 0 {
            AppEventBus.shared.publish(.graphRelayoutRequested)
            await refresh()
        }
        return count
    }

    /// 应用Potential链接
    /// - Parameter suggestion: suggestion
    public func applyPotentialLink(_ suggestion: PotentialLinkSuggestion) async {
        await knowledgeStore.applyPotentialLink(suggestion)
    }

    /// 应用重构Suggestion
    /// - Parameter suggestion: suggestion
    func applyRefactorSuggestion(_ suggestion: RefactorSuggestion) async {
        await knowledgeStore.applyRefactorSuggestion(suggestion)
    }

    /// 应用Remote更新
    /// - Parameter page: page
    public func applyRemoteUpdate(_ page: KnowledgePage) async {
        await knowledgeStore.updatePage(page)
    }

    /// 插入RemotePage
    /// - Parameter page: page
    public func insertRemotePage(_ page: KnowledgePage) async {
        await pageStore.syncRemotePage(page)
        await refresh()
    }

    /// 重命名Page
    /// - Parameter page: page
    func renamePage(_ page: KnowledgePage, to newTitle: String) async {
        await knowledgeStore.renamePage(page, to: newTitle)
    }

    /// 清除AllDeveloperData
    func clearAllDeveloperData() {
        Task {
            AppEventBus.shared.publish(.clearAllDataRequested)
            await maintenanceService.clearAllDeveloperData()
            await refresh()
        }
    }

    /// 导入摄取Folder
    func ingestFolder(at url: URL) async {
        await knowledgeStore.ingestFolder(at: url)
    }

    // MARK: - 标签管理 (转发至 TagStore)

    /// 获取AllTags
    /// - Returns: 列表
    public func getAllTags() -> [String: Int] {
        tagStore.getAllTags(from: pages)
    }

    /// 重命名Tag
    /// - Parameter oldTag: oldTag
    public func renameTag(_ oldTag: String, to newTag: String) async {
        await tagStore.renameTag(old: oldTag, to: newTag)
        await knowledgeStore.refresh()
    }

    /// 删除Tag
    /// - Parameter tag: tag
    public func deleteTag(_ tag: String) async {
        await tagStore.deleteTag(tag)
        await knowledgeStore.refresh()
    }

    /// bulk删除Tags
    /// - Parameter tags: tags
    public func bulkDeleteTags(_ tags: [String]) async {
        await tagStore.bulkDeleteTags(tags)
        await knowledgeStore.refresh()
    }

    /// 添加NewTag
    /// - Parameter tag: tag
    public func addNewTag(_ tag: String) {
        tagStore.addNewTag(tag)
    }
}

// MARK: - AnyPageStore 协议实现
@MainActor
extension AppStore: AnyPageStore {
    public var logEntries: [LogEntry] { [] }

    /// 拉取AllPages
    /// - Returns: 列表
    public func fetchAllPages() async throws -> [KnowledgePage] {
        await knowledgeStore.refresh()
        return knowledgeStore.pages
    }

    /// reloadFromDisk
    public func reloadFromDisk() async {
        await knowledgeStore.loadFromDisk()
    }

    /// 替换AllPages
    /// - Parameter newPages: newPages
    public func replaceAllPages(_ newPages: [KnowledgePage]) async {
        await knowledgeStore.saveToDisk() // 这里原逻辑可能有误，通常是覆盖磁盘
        // 修正为：
        await pageStore.replaceAllPages(newPages)
        await knowledgeStore.refresh()
    }

    /// 重置Database
    public func resetDatabase() async throws {
        try await pageStore.resetDatabase()
        await knowledgeStore.refresh()
    }

    /// 执行BatchWrite
    /// - Parameter block: 阻塞
    /// - Returns: 返回值
    public func performBatchWrite(_ block: @escaping @Sendable (Database) throws -> Void) async throws {
        try await pageStore.performBatchWrite(block)
        await knowledgeStore.refresh()
    }

    /// 创建Page
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

    /// any创建Page
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

    /// 更新Page
    /// - Parameter page: page
    public func updatePage(_ page: KnowledgePage) async throws {
        await knowledgeStore.updatePage(page)
    }

    /// any更新Page
    /// - Parameter page: page
    /// - Parameter forceDeepScan: forceDeep扫描
    public func anyUpdatePage(_ page: KnowledgePage, forceDeepScan: Bool) async {
        await knowledgeStore.updatePage(page)
    }

    /// any删除Page
    /// - Parameter page: page
    public func anyDeletePage(_ page: KnowledgePage) async {
        await knowledgeStore.deletePage(page)
    }

    /// 同步RemotePage
    /// - Parameter page: page
    public func syncRemotePage(_ page: KnowledgePage) async {
        await pageStore.syncRemotePage(page)
        await knowledgeStore.refresh()
    }

    /// 拉取BacklinksByID
    /// - Returns: 列表
    public func fetchBacklinksByID(for id: UUID) async -> [KnowledgePage] {
        await pageStore.fetchBacklinksByID(for: id)
    }

    /// 搜索Pages
    /// - Parameter query: query
    /// - Returns: 列表
    public func searchPages(query: String) async -> [KnowledgePage] {
        await pageStore.searchPages(query: query)
    }

    /// seedDefaultContent
    /// - Parameter logger: logger
    /// - Returns: 返回值
    public func seedDefaultContent(logger: @escaping @Sendable (LogAction, String, String) -> Void) async {
        await knowledgeStore.seedDefaultContent()
    }

    /// 获取StorageStats
    /// - Returns: 返回值
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
