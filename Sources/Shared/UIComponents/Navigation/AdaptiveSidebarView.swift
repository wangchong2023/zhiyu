// AdaptiveSidebarView.swift
//
// 作者: Wang Chong
// 功能说明: 响应式侧边栏 (iPad/Mac 专属)
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
//   - 更新: 2026-05-04
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 响应式侧边栏 (iPad/Mac 专属)
/// 将传统的底部 Tab 转换为更符合大屏习惯的垂直侧边栏。
/// 响应式侧边栏视图 (iPad/Mac 专属)
/// 负责将大屏环境下的导航从底部 Tab 切换为侧边栏 List 模式，优化空间利用率与交互路径
@MainActor
struct AdaptiveSidebarView: View {
    @Environment(AppStore.self) var store
    @Environment(Router.self) var router
    @Binding var selectedTab: AppTab
    
    var body: some View {
        List {
            Section(Localized.tr("sidebar.knowledge")) {
                sidebarRow(for: .knowledge)
            }
            
            Section(Localized.tr("sidebar.tools")) {
                sidebarRow(for: .chat)
                sidebarRow(for: .ingest)
                sidebarRow(for: .search)
                sidebarRow(for: .graph)
                
                // 快捷跳转到任务中心 (作为 Knowledge 模块的子操作)
                Button(action: {
                    selectedTab = .knowledge
                    router.navigateToTool(.taskCenter)
                }) {
                    Label(L10n.AI.Task.centerTitle, systemImage: "arrow.triangle.2.circlepath")
                }
            }
        }
        #if !os(watchOS)
        .listStyle(.sidebar)
        #endif
        .navigationTitle(Localized.tr("app.name"))
        .toolbar {
            #if os(watchOS)
            ToolbarItem(placement: .automatic) {
                VaultBadge()
            }
            #else
            ToolbarItem(placement: .navigation) {
                VaultBadge()
            }
            #endif
            ToolbarItem(placement: .automatic) {
                UserProfileMenu()
            }
        }
        .id(router.languageForceUpdate)
    }
    
    private func sidebarRow(for tab: AppTab) -> some View {
        Button(action: { selectedTab = tab }) {
            Label(tab.displayTitle, systemImage: tab.icon)
                .foregroundStyle(selectedTab == tab ? Color.appAccent : .primary)
        }
        .tag(tab)
    }
}

/// 响应式主内容区域
/// 响应式主内容区域视图
/// 负责根据侧边栏选中项动态分发内容视图，支持跨平台的导航逻辑一致性
@MainActor
struct AdaptiveDetailView: View {
    @Environment(AppStore.self) var store
    @Environment(Router.self) var router
    @Binding var selectedTab: AppTab
    @Binding var selection: SidebarSelection?
    // // @Binding var languageForceUpdate: Bool
    var heroNamespace: Namespace.ID

    init(selectedTab: Binding<AppTab>, selection: Binding<SidebarSelection?>, heroNamespace: Namespace.ID) {
        self._selectedTab = selectedTab
        self._selection = selection
        self.heroNamespace = heroNamespace
    }

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            Group {
                switch selectedTab {
                case .knowledge:
                    DetailContentView(selection: $selection, selectedTab: $selectedTab)
                case .chat:
                    ChatView(selectedTab: $selectedTab)
                case .graph:
                    GraphContainerView(heroNamespace: heroNamespace, selectedTab: $selectedTab)
                case .search:
                    SearchView()
                case .ingest:
                    IngestView(selectedTab: $selectedTab)
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                ViewFactory.makeView(for: route)
            }
            .navigationDestination(for: KnowledgePage.self) { page in
                PageDetailView(page: page)
            }
        }
    }
}
