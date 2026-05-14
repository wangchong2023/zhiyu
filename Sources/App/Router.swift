// Router.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了知识管理系统的全局路由管理器（Router），作为应用导航逻辑的核心大脑。
// 该类基于 SwiftUI 的现代导航堆栈（NavigationPath）与观察者模式，提供了卓越的视图切换能力：
// 1. 声明式路径管理：通过集中化的 AppRoute 枚举解耦了视图间的直接依赖，支持动态推栈、平级切换及“回到根路径”的操作。
// 2. 状态机同步逻辑：智能维护侧边栏选中项（SidebarSelection）与主标签（AppTab）的一致性，确保在跨平台（iPadOS vs iOS）布局切换时导航状态的透明迁移。
// 3. 空间历史追踪：内置了轻量级的导航历史（Breadcrumbs）记录机制，为用户提供最近访问页面的快速回溯能力。
// 4. 外部调度接入：提供单例接口支持 Deep Link、搜索跳转及系统级指令对应用路由的直接编排。
// 版本: 1.2
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI
import Observation

/// 应用程序路由目标定义
/// 每个 Case 对应系统中的一个物理视图或逻辑页面。
/// 映射逻辑详见 `ViewFactory.makeView(for:)`。
enum AppRoute: Hashable, Identifiable {
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
    case search
    
    /// 知识摄取中心 (OCR、PDF 导入、网页裁剪) -> `IngestView`
    case ingest
    
    /// 知识图谱 (可视化展示页面间的关联网络) -> `GraphContainerView`
    case graph
    
    var id: String {
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
        case .search: return "search"
        case .ingest: return "ingest"
        case .graph: return "graph"
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
            }
        }
    }
    
    private func syncTab(for selection: SidebarSelection) {
        switch selection {
        case .tool(let tool):
            switch tool {
            case .chat: selectedTab = .chat
            case .graph: selectedTab = .graph
            case .search: selectedTab = .search
            case .ingest: selectedTab = .ingest
            case .pageList, .dashboard, .lint, .tagCloud, .taskCenter, .synthesis, .weeklyReport, .log, .collab, .pluginMarket:
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
    var selectedTab: AppTab = AppTab(rawValue: UserDefaults.standard.string(forKey: "app_selected_tab") ?? "") ?? .knowledge {
        didSet {
            UserDefaults.standard.set(selectedTab.rawValue, forKey: "app_selected_tab")
        }
    }
    
    /// 空间导航历史 (面包屑)
    var navigationHistory: [KnowledgePage] = []

    /// 强制 UI 刷新标识（主要用于多语言切换）
    var languageForceUpdate: Bool = false
    
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
        switch route {
        case .notebookHub, .dashboard: sidebarSelection = .tool(.dashboard)
        case .pageList(let type): sidebarSelection = type == nil ? .tool(.pageList) : .filteredIndex(type!)
        case .tagCloud: sidebarSelection = .tool(.tagCloud)
        case .taskCenter: sidebarSelection = .tool(.taskCenter)
        case .chat: sidebarSelection = .tool(.chat)
        case .synthesis: sidebarSelection = .tool(.synthesis)
        case .settings, .help, .about: break
        case .log: sidebarSelection = .tool(.log)
        case .collab: sidebarSelection = .tool(.collab)
        case .weeklyReport: sidebarSelection = .tool(.weeklyReport)
        case .lint: sidebarSelection = .tool(.lint)
        case .pluginMarket: sidebarSelection = .tool(.pluginMarket)
        case .search: sidebarSelection = .tool(.search)
        case .ingest: sidebarSelection = .tool(.ingest)
        case .graph: sidebarSelection = .tool(.graph)
        case .pageDetail(let id): sidebarSelection = .page(id)
        }
    }
}
