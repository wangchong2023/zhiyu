// ContentView.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了知识管理系统的全局根视图（ContentView），作为整个应用程序的 UI 容器与状态协调中心。
// 该视图集成了响应式布局引擎与全局反馈层，主要功能点如下：
// 1. 多设备自适应导航：基于 SwiftUI 的 Size Class 机制，在 iPad/macOS 上自动切换为 NavigationSplitView（侧边栏模式），而在 iPhone 上呈现为现代化的 TabView。
// 2. 全局安全与入库控制：挂载了隐私锁定层（LockOverlay）、新手引导（Onboarding）及全局通知（Toast）系统，确保应用在不同生命周期阶段的安全性。
// 3. 动态路由编排：深度集成 Router 与 ViewFactory，支持跨模块的视图跳转、Deep Link 唤起及全局指令面板（Command Palette）的弹出。
// 4. 品牌交互反馈：实现了全局奖章（Medal）奖励弹窗与功能引导（Coach Marks）覆盖层，通过高阶动画引擎提升用户的品牌成就感。
// 版本: 1.1
// 修改记录:
//   - 2026-05-05: 升级全工程文档规范，规范化 UI 层级、圆角与间距常量
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 应用程序根视图
/// 负责全局导航分发（Tab/SplitView）、安全遮罩及全局弹窗调度
@MainActor
struct ContentView: View {
    @Environment(AppStore.self) var store
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(Router.self) var router
    @Environment(AuthService.self) var authService
    @Environment(VaultService.self) var vaultService
    
    @StateObject private var tooltipManager = TooltipManager.shared
    @State private var showCommandPalette = false
    @Namespace private var heroNamespace
    @StateObject private var medalService = MedalService.shared
    
    
    @StateObject private var onboardingService = OnboardingService()
    @Inject var deepLinkService: DeepLinkService
    @Inject var appEnv: any AppEnvironmentProtocol
    
    @State private var showSidebar = false // 方案 D: iPhone 侧边栏开关

    var body: some View {
        @Bindable var store = store
        @Bindable var router = router
        let tintColor = ThemeManager.colorForName(themeManager.accentColorRaw)
        
        ZStack {
            // 背景层
            themeManager.pageBackground()
                .ignoresSafeArea()
            
            // 主内容层
            mainContainer(tintColor: tintColor)
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("toggleSidebar"))) { _ in
                    withAnimation(.spring(response: DesignSystem.Animation.springResponse, dampingFraction: DesignSystem.Animation.springDamping)) {
                        showSidebar.toggle()
                    }
                }
            
            // 方案 D: iPhone 侧边栏抽屉层
            if showSidebar && appEnv.screenClass == .compact {
                Color.black.opacity(DesignSystem.dimmedOpacity)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: DesignSystem.Animation.springResponse, dampingFraction: DesignSystem.Animation.springDamping)) {
                            showSidebar = false
                        }
                    }
                    .transition(.opacity)
                
                HStack {
                    SidebarView(heroNamespace: heroNamespace)
                        .frame(width: DesignSystem.Sidebar.width)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card, style: .continuous))
                        .shadow(color: .black.opacity(DesignSystem.shadowOpacity), radius: DesignSystem.shadowRadius)
                        .padding(.vertical, DesignSystem.medium)
                        .padding(.leading, DesignSystem.medium)
                    Spacer()
                }
                .transition(.move(edge: .leading))
                .zIndex(DesignSystem.ZIndex.sidebarOverlay)
            }
        }
        .animation(DesignSystem.Animation.Config.prominentSpring, value: AuthSession.shared.isLoggedIn || AuthSession.shared.isGuest)
        .animation(DesignSystem.Animation.Config.prominentSpring, value: vaultService.selectedVaultID)
        .environmentObject(onboardingService)
    }
    
    @ViewBuilder
    private func mainContainer(tintColor: Color) -> some View {
        if AuthSession.shared.isLoggedIn || AuthSession.shared.isGuest {
            Group {
                if vaultService.selectedVaultID != nil {
                    mainContent(tintColor: tintColor)
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                } else {
                    NavigationStack {
                        NotebookHubView()
                    }
                    .id("NotebookHub")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        } else {
            AuthView()
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    @ViewBuilder
    private func mainContent(tintColor: Color) -> some View {
        @Bindable var store = store
        @Bindable var router = router
        ZStack {
            Group {
                if appEnv.screenClass != .compact {
                    adaptiveSplitView(tintColor: tintColor)
                } else {
                    // 恢复原版 Tab 导航 (iPhone)
                    if #available(iOS 18.0, macOS 15.0, macCatalyst 18.0, *) {
                        modernTabView(tintColor: tintColor)
                    } else {
                        legacyTabView(tintColor: tintColor)
                    }
                }
            }
            .sheet(isPresented: $store.showCreateSheet) {
                CreatePageView()
            }

            if store.securityService.isLocked {
                LockOverlayView()
                    .transition(AnyTransition.opacity.combined(with: .scale(scale: Colors.Opacity.fullOpacity * DesignSystem.Metrics.lockOverlayScaleMultiplier)))
                    .zIndex(DesignSystem.ZIndex.lockOverlay)
            }
            
            OnboardingOverlay(service: onboardingService)
            
            // 全局奖章奖励弹窗
            if let medal = medalService.newlyEarnedMedal {
                MedalRewardPopup(medal: medal) {
                    withAnimation(.spring()) {
                        medalService.newlyEarnedMedal = nil
                    }
                }
                .zIndex(DesignSystem.ZIndex.medalPopup)
                .transition(.asymmetric(insertion: .opacity, removal: .scale.combined(with: .opacity)))
            }
            
            // 功能引导弹窗 (Coach Marks)
            if let coachMark = store.pendingCoachMark {
                CoachMarkOverlay(type: coachMark, selectedTab: $router.selectedTab) {
                    store.pendingCoachMark = nil
                }
                .zIndex(DesignSystem.ZIndex.coachMark)
            }
        }
        .onAppear {
            if !onboardingService.hasCompletedOnboarding {
                onboardingService.nextStep()
            }
        }
        .onChange(of: onboardingService.hasCompletedOnboarding) { _, newValue in
            if !newValue && onboardingService.currentStep == nil {
                onboardingService.nextStep()
            }
        }
        .appToast()
    }
    
    // MARK: - iPad/Mac Adaptive SplitView
    @ViewBuilder
    private func adaptiveSplitView(tintColor: Color) -> some View {
        #if os(watchOS)
        Text("Not used on watchOS")
        #else
        @Bindable var store = store
        @Bindable var router = router
        NavigationSplitView {
            AdaptiveSidebarView(selectedTab: $router.selectedTab)
        } content: {
            // 中间列：根据 Tab 显示不同的二级列表
            switch router.selectedTab {
            case .knowledge:
                SidebarView(heroNamespace: heroNamespace, selection: $router.sidebarSelection)
            default:
                Color.appBackground
            }
        } detail: {
            // 详情列：显示主要内容
            AdaptiveDetailView(selectedTab: $router.selectedTab, selection: $router.sidebarSelection, heroNamespace: heroNamespace)
        }
        .tint(tintColor)
        .sheet(isPresented: $store.showPerfDashboard) {
            PerformanceDashboardView(service: store.performanceService)
        }
        .sheet(isPresented: $showCommandPalette) {
            CommandPaletteView()
                .presentationDetents([.height(DesignSystem.Metrics.commandPaletteHeight)])
                .presentationBackground(.clear)
        }
        .background {
            Button(Localized.tr("tab.search")) { showCommandPalette.toggle() }
                .keyboardShortcut("k", modifiers: .command)
                .opacity(0)
        }
        #endif
    }
    
    // MARK: - iOS 18+ Modern TabView (Bottom TabBar — consistent on iPhone & iPad)
    @available(iOS 18.0, macOS 15.0, macCatalyst 18.0, *)
    @ViewBuilder
    private func modernTabView(tintColor: Color) -> some View {
        #if os(watchOS)
        Text("Not used on watchOS")
        #else
        @Bindable var store = store
        @Bindable var router = router
        TabView(selection: $router.selectedTab) {
            Tab(AppTab.knowledge.displayTitle, systemImage: AppTab.knowledge.icon, value: AppTab.knowledge) {
                knowledgeTabContent
            }

            Tab(AppTab.chat.displayTitle, systemImage: AppTab.chat.icon, value: AppTab.chat) {
                chatTabContent
            }

            Tab(AppTab.ingest.displayTitle, systemImage: AppTab.ingest.icon, value: AppTab.ingest) {
                ingestTabContent
            }

            Tab(AppTab.search.displayTitle, systemImage: AppTab.search.icon, value: AppTab.search) {
                searchTabContent
            }

            Tab(AppTab.graph.displayTitle, systemImage: AppTab.graph.icon, value: AppTab.graph) {
                graphTabContent
            }
        }
        .tint(tintColor)
        .onOpenURL { url in
            if deepLinkService.handleURL(url) {
                consumeDeepLink()
            }
        }
        .sheet(isPresented: $store.showPerfDashboard) {
            PerformanceDashboardView(service: store.performanceService)
        }
        .sheet(isPresented: $showCommandPalette) {
            CommandPaletteView()
                .presentationDetents([.height(DesignSystem.Metrics.commandPaletteHeight)])
                .presentationBackground(.clear)
        }
        .background {
            Button(L10n.Common.tr("action")) {
                showCommandPalette.toggle()
            }
            .keyboardShortcut("k", modifiers: .command)
            .opacity(0)
        }
        #endif
    }
    
    // MARK: - iOS 17 Legacy TabView (Bottom TabBar)
    @ViewBuilder
    private func legacyTabView(tintColor: Color) -> some View {
        #if os(watchOS)
        Text("Not used on watchOS")
        #else
        @Bindable var store = store
        @Bindable var router = router
        TabView(selection: $router.selectedTab) {
            knowledgeTabContent
                .tabItem {
                    Label(AppTab.knowledge.displayTitle, systemImage: AppTab.knowledge.icon)
                }
                .accessibilityIdentifier("Knowledge")
                .tag(AppTab.knowledge)

            chatTabContent
                .accessibilityIdentifier("Chat")
                .tabItem {
                    Label(AppTab.chat.displayTitle, systemImage: AppTab.chat.icon)
                }
                .tag(AppTab.chat)


            ingestTabContent
                .accessibilityIdentifier("Ingest")
                .tabItem {
                    Label(AppTab.ingest.displayTitle, systemImage: AppTab.ingest.icon)
                }
                .tag(AppTab.ingest)

            searchTabContent
                .accessibilityIdentifier("Search")
                .tabItem {
                    Label(AppTab.search.displayTitle, systemImage: AppTab.search.icon)
                }
                .tag(AppTab.search)

            graphTabContent
                .accessibilityIdentifier("Graph")
                .tabItem {
                    Label(AppTab.graph.displayTitle, systemImage: AppTab.graph.icon)
                }
                .tag(AppTab.graph)
        }
        .tint(tintColor)
        .onOpenURL { url in
            if deepLinkService.handleURL(url) {
                consumeDeepLink()
            }
        }
        .sheet(isPresented: $store.showPerfDashboard) {
            PerformanceDashboardView(service: store.performanceService)
        }
        .sheet(isPresented: $showCommandPalette) {
            CommandPaletteView()
                .presentationDetents([.height(DesignSystem.Metrics.commandPaletteHeight)])
                .presentationBackground(.clear)
        }
        .background {
            Button(L10n.Common.tr("action")) {
                showCommandPalette.toggle()
            }
            .keyboardShortcut("k", modifiers: .command)
            .opacity(0)
        }
        #endif
    }
    
    /// Knowledge tab 内容，使用 @ViewBuilder 根据 languageForceUpdate 条件刷新
    /// 这样可以避免在 TabView 层级使用 .id() 导致 Menu 崩溃
    @ViewBuilder
    private var knowledgeTabContent: some View {
        @Bindable var router = router
        if appEnv.screenClass == .compact {
            NavigationStack(path: $router.path) {
                SidebarView(heroNamespace: heroNamespace, selection: $router.sidebarSelection) // 选本后进入侧边栏菜单 (含所有页面、知识合成等)
                    .id(router.languageForceUpdate)
                    .navigationDestination(for: AppRoute.self) { route in
                        ViewFactory.makeView(for: route)
                    }
                    .navigationDestination(for: SidebarSelection.self) { selection in
                        ViewFactory.makeView(for: selection.asRoute())
                    }
                    .navigationDestination(for: KnowledgePage.self) { page in
                        PageDetailView(page: page)
                    }
            }
        } else {
            NavigationView(selectedTab: $router.selectedTab, heroNamespace: heroNamespace)
                .id(router.languageForceUpdate)
        }
    }
    
    /// Chat tab 内容
    @ViewBuilder
    private var chatTabContent: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            ChatView(selectedTab: $router.selectedTab)
                .id(router.languageForceUpdate)
                .navigationDestination(for: AppRoute.self) { route in
                    ViewFactory.makeView(for: route)
                }
        }
    }
    
    /// Graph tab 内容，languageForceUpdate 时强制刷新
    @ViewBuilder
    private var graphTabContent: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            GraphContainerView(heroNamespace: heroNamespace, selectedTab: $router.selectedTab)
                .id(router.languageForceUpdate)
                .navigationDestination(for: AppRoute.self) { route in
                    ViewFactory.makeView(for: route)
                }
        }
    }
    
    /// Search tab 内容，languageForceUpdate 时强制刷新
    @ViewBuilder
    private var searchTabContent: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            SearchView()
                .id(router.languageForceUpdate)
                .navigationDestination(for: AppRoute.self) { route in
                    ViewFactory.makeView(for: route)
                }
        }
    }

    /// Ingest tab 内容，languageForceUpdate 时强制刷新
    @ViewBuilder
    private var ingestTabContent: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            IngestView(selectedTab: $router.selectedTab)
                .id(router.languageForceUpdate)
                .navigationDestination(for: AppRoute.self) { route in
                ViewFactory.makeView(for: route)
            }
        }
    }

    private func consumeDeepLink() {
        guard let link = deepLinkService.consumeDeepLink() else { return }
        switch link {
        case .openPage(let id): router.navigateToPage(id: id)
        case .openPageByTitle(let t):
            Task {
                if let p = await store.pageByTitle(t) {
                    await MainActor.run { router.navigateToPage(id: p.id) }
                }
            }
        case .search(let q): store.searchStore.searchText = q
        default: break
        }
    }
}

#Preview {
    ContentView()
        .environment(AppStore())
        .environmentObject(ThemeManager())
        .environmentObject(LLMService.shared)
}

// MARK: - Coach Mark Overlay
struct CoachMarkOverlay: View {
    let type: AppStore.CoachMarkType
    @Binding var selectedTab: AppTab
    let onDismiss: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(DesignSystem.coachMarkBackgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture { dismissWithAnimation() }
            
            VStack(spacing: DesignSystem.giant) {
                // 图标
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.appAccent, .appSource], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: DesignSystem.Gallery.splashIconSize, height: DesignSystem.Gallery.splashIconSize)
                        .shadow(color: .appAccent.opacity(DesignSystem.disabledOpacity), radius: DesignSystem.medium, y: DesignSystem.small + DesignSystem.atomic)
                    
                    Image(systemName: iconName)
                        .font(.system(size: DesignSystem.Metrics.titleFontSize * DesignSystem.Metrics.coachMarkIconScale, weight: .bold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .opacity(isAnimating ? 1.0 : 0)
                
                VStack(spacing: DesignSystem.medium) {
                    Text(Localized.tr(titleKey))
                        .font(.title3.bold())
                        .foregroundStyle(.appText)
                    
                    Text(Localized.tr(descKey))
                        .font(.subheadline)
                        .foregroundStyle(.appSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .offset(y: isAnimating ? 0 : DesignSystem.loosePadding)
                .opacity(isAnimating ? 1.0 : 0)
                
                Button(action: performAction) {
                    Text(Localized.tr(actionKey))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, DesignSystem.Metrics.coachMarkActionHorizontalPadding)
                        .padding(.vertical, DesignSystem.medium)
                        .background(
                            Capsule()
                                .fill(Color.appAccent)
                        )
                }
                .scaleEffect(isAnimating ? 1.0 : 0.9)
                .opacity(isAnimating ? 1.0 : 0)
                
                Button(action: dismissWithAnimation) {
                    Text(L10n.Common.tr("skip"))
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                }
                .padding(.top, DesignSystem.tiny)
            }
            .padding(DesignSystem.giant + DesignSystem.Metrics.heroValueSize * 0.5)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.largeRadius + DesignSystem.Metrics.coachMarkRadiusOffset)
                    .fill(Color.appCard)
                    .shadow(color: .black.opacity(DesignSystem.glassOpacity * 2), radius: DesignSystem.Metrics.coachMarkShadowRadius, x: 0, y: DesignSystem.Metrics.coachMarkShadowY)
            )
            .padding(DesignSystem.giant)
        }
        .onAppear {
            withAnimation(.spring(response: DesignSystem.Animation.standardDuration, dampingFraction: DesignSystem.Animation.standardDamping * 0.875)) {
                isAnimating = true
            }
        }
    }
    
    private var iconName: String {
        switch type {
        case .graphDiscovery: return "circle.hexagongrid.fill"
        }
    }
    
    private var titleKey: String {
        switch type {
        case .graphDiscovery: return "coachmark.graphDiscovery.title"
        }
    }
    
    private var descKey: String {
        switch type {
        case .graphDiscovery: return "coachmark.graphDiscovery.desc"
        }
    }
    
    private var actionKey: String {
        switch type {
        case .graphDiscovery: return "coachmark.graphDiscovery.action"
        }
    }
    
    private func performAction() {
        HapticFeedback.shared.trigger(.success)
        switch type {
        case .graphDiscovery:
            withAnimation {
                selectedTab = .graph
            }
        }
        dismissWithAnimation()
    }
    
    private func dismissWithAnimation() {
        withAnimation(.easeIn(duration: DesignSystem.Animation.fastDuration)) { // 0.2
            isAnimating = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + DesignSystem.Animation.fastDuration) { // 0.2
            onDismiss()
        }
    }

}
