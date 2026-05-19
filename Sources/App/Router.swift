// Router.swift
//
// 作者: Wang Chong
// 功能说明: [L3] 应用调度层：本文件实现了知识管理系统的全局路由管理器（Router），作为应用导航逻辑的核心大脑。
// 该类基于 SwiftUI 的现代导航堆栈（NavigationPath）与观察者模式，提供了卓越的视图切换能力：
// 1. 声明式路径管理：通过集中化的 AppRoute 枚举解耦了视图间的直接依赖，支持动态推栈、平级切换及“回到根路径”的操作。
// 2. 状态机同步逻辑：智能维护侧边栏选中项（SidebarSelection）与主标签（AppTab）的一致性，确保在跨平台（iPadOS vs iOS）布局切换时导航状态的透明迁移。
// 3. 空间历史追踪：内置了轻量级的导航历史（Breadcrumbs）记录机制，为用户提供最近访问页面的快速回溯能力。
// 4. 外部调度接入：提供单例接口支持 Deep Link、搜索跳转及系统级指令对应用路由的直接编排。
// 版本: 1.2
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI
import Observation

/// 业务领域定义
public enum FeatureDomain: String, CaseIterable, Sendable {
    case knowledge
    case ai
    case insight
    case system
}

/// 应用程序路由目标定义
/// 每个 Case 对应系统中的一个物理视图或逻辑页面。
public enum AppRoute: Hashable, Identifiable {
    /// 笔记本工作台 (切换与管理不同笔记本的入口) -> `NotebookHubView`
    case notebookHub

    /// 知识仪表盘 (展示统计图表、活跃度等总览信息) -> `KnowledgeDashboardView`
    case dashboard
    
    /// 知识库页面列表 (展示所有知识条目，支持类型过滤) -> `KnowledgePageListView`
    case pageList(filterType: PageType? = nil)
    
    /// 知识条目详情页 (查看与编辑具体笔记内容) -> `PageDetailView`
    case pageDetail(id: UUID)
    
    /// 标签云视图 (可视化展示知识标签分布) -> `TagCloudView`
    case tagCloud
    
    /// 任务中心 (管理与知识条目关联的待办事项) -> `TaskCenterView`
    case taskCenter
    
    /// AI 智能对话 (基于 RAG 架构的知识问答) -> `ChatView`
    case chat
    
    /// AI 合成实验室 (深度引用、知识重组与合成) -> `SynthesisView`
    case synthesis
    
    /// 当前 AI 会话信源 (对标 NotebookLM) -> `SourceView`
    case sources
    
    /// 应用设置页面 (个性化、存储与 AI 模型配置) -> `SettingsView`
    case settings
    
    /// 帮助与反馈 -> 系统 Web 视图
    case help
    
    /// 关于应用 (版本、团队及版权信息) -> `AboutView`
    case about
    
    /// 系统运行日志 (用于排查 RAG 管道错误) -> `LogView`
    case log
    
    /// 协作中心 (多人同步与知识共享状态) -> `CollaborationView`
    case collab
    
    /// 知识周报 (AI 自动生成的学习与知识产出总结) -> `WeeklyReportView`
    case weeklyReport
    
    /// 知识巡检 (Lint 检查、无效链接与冲突检测) -> `LintView`
    case lint
    
    /// 插件市场 (扩展 AI 处理器与导入插件) -> `PluginCenterView`
    case pluginMarket
    
    /// 全局搜索中心 (混合搜索与语义过滤) -> `SearchView`
    case search(query: String? = nil, filterType: PageType? = nil)
    
    /// 知识摄取中心 (OCR、PDF 导入、网页裁剪) -> `IngestView`
    case ingest
    
    /// 知识图谱 (可视化展示页面间的关联网络) -> `GraphContainerView`
    case graph
    
    /// 知识测试 (基于页面的 AI 测验)
    case quiz
    
    /// 勋章墙 (展示用户的知识管理成就)
    case medalWall
    public var id: String {
        switch self {
        case .notebookHub: return "notebookHub"
        case .dashboard: return "dashboard"
        case .pageList(let type): return "pageList-\(type?.rawValue ?? "all")"
        case .pageDetail(let id): return "page-\(id.uuidString)"
        case .tagCloud: return "tagCloud"
        case .taskCenter: return "taskCenter"
        case .chat: return "chat"
        case .synthesis: return "synthesis"
        case .settings: return "settings"
        case .help: return "help"
        case .about: return "about"
        case .log: return "log"
        case .collab: return "collab"
        case .weeklyReport: return "weeklyReport"
        case .lint: return "lint"
        case .pluginMarket: return "pluginMarket"
        case .search(let query, let type): return "search-\(query ?? "")-\(type?.rawValue ?? "all")"
        case .ingest: return "ingest"
        case .graph: return "graph"
        case .quiz: return "quiz"
        case .medalWall: return "medalWall"
        case .sources: return "sources"
        }
    }
    
    /// 获取该路由对应的侧边栏选中项
    public var sidebarSelection: SidebarSelection? {
        switch self {
        case .notebookHub, .dashboard, .medalWall: return .tool(.dashboard)
        case .pageList(let type): return type == nil ? .tool(.pageList) : .filteredIndex(type!)
        case .tagCloud: return .tool(.tagCloud)
        case .taskCenter: return .tool(.taskCenter)
        case .chat: return .tool(.chat)
        case .synthesis, .quiz: return .tool(.synthesis)
        case .log: return .tool(.log)
        case .collab: return .tool(.collab)
        case .weeklyReport: return .tool(.weeklyReport)
        case .lint: return .tool(.lint)
        case .pluginMarket: return .tool(.pluginMarket)
        case .search: return .tool(.search)
        case .ingest: return .tool(.ingest)
        case .graph: return .tool(.graph)
        case .sources: return .tool(.sources)
        case .pageDetail(let id): return .page(id)
        case .settings, .help, .about: return nil
        }
    }
    
    /// 获取该路由所属的业务领域
    public var domain: FeatureDomain {
        switch self {
        case .notebookHub, .pageList, .pageDetail, .tagCloud, .ingest, .graph, .search, .sources:
            return .knowledge
        case .chat, .synthesis, .taskCenter, .weeklyReport, .quiz:
            return .ai
        case .dashboard, .log, .lint, .medalWall:
            return .insight
        case .settings, .help, .about, .collab, .pluginMarket:
            return .system
        }
    }
}

/// 应用程序路由管理器
/// 集中管理导航状态，支持解耦跳转与状态持久化
@Observable
@MainActor
final class Router {
    /// 全局单例，方便非视图层级调用（如 DeepLink 处理）
    static let shared = Router()
    
    /// 核心导航路径
    var path = NavigationPath()
    
    /// 当前侧边栏选中项
    var sidebarSelection: SidebarSelection? = nil {
        didSet {
            if let selection = sidebarSelection {
                syncTab(for: selection)
                
                // 触发插件事件：页面打开
                if case .page(let id) = selection {
                    PluginRegistry.shared.emitEvent("onFileOpen", data: id.uuidString)
                }
            }
        }
    }
    
    private func syncTab(for selection: SidebarSelection) {
        switch selection {
        case .tool(let tool):
            switch tool {
            case .chat: selectedTab = .chat
            case .graph: selectedTab = .graph
            case .ingest: selectedTab = .ingest
            case .synthesis: selectedTab = .synthesis
            case .search:
                // 搜索现在被合并到知识库 Tab
                selectedTab = .knowledge
            case .pageList, .dashboard, .lint, .tagCloud, .taskCenter, .weeklyReport, .log, .collab, .pluginMarket:
                selectedTab = .knowledge
            default: break
            }
        case .filteredIndex:
            selectedTab = .knowledge
        case .page:
            selectedTab = .knowledge
        }
    }
    
    /// 当前主 Tab (通过 UserDefaults 持久化，防止后台切换后状态丢失)
    var selectedTab: AppTab = AppTab(rawValue: UserDefaults.standard.string(forKey: AppConstants.Keys.Storage.selectedTab) ?? "") ?? .knowledge {
        didSet {
            UserDefaults.standard.set(selectedTab.rawValue, forKey: AppConstants.Keys.Storage.selectedTab)
        }
    }
    
    /// 空间导航历史 (面包屑)
    var navigationHistory: [KnowledgePage] = []
    
    /// 用于在跳转至 AI 对话时自动发送的预设提示词 (冷启动 Aha Moment)
    var pendingInitialChatPrompt: String? = nil

    /// 强制 UI 刷新标识（主要用于多语言切换）
    var languageForceUpdate: Bool = false
    
    /// 是否正在显示设置面板
    var isShowingSettingsSheet: Bool = false
    
    /// 触发全局语言刷新
    func triggerLanguageRefresh() {
        languageForceUpdate.toggle()
    }
    
    /// 关闭当前显示的 sheet (通过单例路由协调)
    func dismissSheet() {
        isShowingSettingsSheet = false
    }

    private init() {}
    
    // MARK: - 导航指令
    
    /// 添加到导航历史 (去重并限制长度)
    func addToHistory(_ page: KnowledgePage) {
        // 如果当前已经在历史末尾，则不重复添加
        if navigationHistory.last?.id == page.id { return }
        
        // 限制历史长度 (UX 建议：过多会导致认知负担)
        if navigationHistory.count >= DesignSystem.Metrics.maxBreadcrumbCount { // 5
            navigationHistory.removeFirst()
        }
        navigationHistory.append(page)
    }
    
    /// 清空导航历史
    func clearHistory() {
        navigationHistory.removeAll()
    }
    
    /// 跳转到指定目标
    func navigate(to route: AppRoute) {
        // 如果是详情跳转，则推入路径堆栈；否则作为顶层导航
        if isDetailRoute(route) {
            path.append(route)
        } else {
            // 顶层导航切换
            updateSelection(for: route)
            // 切换顶层时通常清空路径
            path = NavigationPath()
        }
    }
    
    /// 便捷跳转：指定页面
    func navigateToPage(id: UUID) {
        navigate(to: .pageDetail(id: id))
    }
    
    /// 便捷跳转：指定工具
    func navigateToTool(_ tool: AppStore.ToolItem) {
        sidebarSelection = .tool(tool)
        path = NavigationPath()
    }
    
    /// 返回上一级
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    /// 返回到根路径
    func popToRoot() {
        path = NavigationPath()
    }
    
    // MARK: - 辅助逻辑
    
    private func isDetailRoute(_ route: AppRoute) -> Bool {
        switch route {
        case .pageDetail, .settings, .help, .about: return true
        default: return false
        }
    }
    
    private func updateSelection(for route: AppRoute) {
        if let selection = route.sidebarSelection {
            sidebarSelection = selection
        }
    }
}
