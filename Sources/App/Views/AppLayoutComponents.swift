// AppLayoutComponents.swift
//
// 作者: Wang Chong
// 功能说明: [L3] 应用调度层：本文件包含 ContentView 的视图构建组件，用于实现导航解耦。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

extension ContentView {
    
    // MARK: - Main Containers
    
    @ViewBuilder
    func mainContainer(tintColor: Color) -> some View {
        if AuthSession.shared.isLoggedIn || AuthSession.shared.isGuest {
            Group {
                if vaultService.selectedVaultID != nil {
                    mainContent(tintColor: tintColor)
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                } else {
                    NavigationStack {
                        NotebookHubView()
                            .id(router.languageForceUpdate)
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
    func mainContent(tintColor: Color) -> some View {
        @Bindable var store = store
        @Bindable var router = router
        ZStack {
            Group {
                if appEnv.screenClass != .compact {
                    adaptiveSplitView(tintColor: tintColor)
                } else {
                    #if DEBUG
                    if ProcessInfo.processInfo.environment["UITesting"] == "true" ||
                       ProcessInfo.processInfo.arguments.contains("--uitesting") {
                        legacyTabView(tintColor: tintColor)
                    } else if #available(iOS 18.0, macOS 15.0, macCatalyst 18.0, *) {
                        modernTabView(tintColor: tintColor)
                    } else {
                        legacyTabView(tintColor: tintColor)
                    }
                    #else
                    if #available(iOS 18.0, macOS 15.0, macCatalyst 18.0, *) {
                        modernTabView(tintColor: tintColor)
                    } else {
                        legacyTabView(tintColor: tintColor)
                    }
                    #endif
                }
            }
            .sheet(isPresented: $store.showCreateSheet) {
                CreatePageView()
            }
            
            
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
    func adaptiveSplitView(tintColor: Color) -> some View {
        #if os(watchOS)
        Text("Not used on watchOS")
        #else
        @Bindable var store = store
        @Bindable var router = router
        NavigationSplitView {
            AdaptiveSidebarView(selectedTab: $router.selectedTab)
        } content: {
            switch router.selectedTab {
            case .knowledge:
                SidebarView(heroNamespace: heroNamespace, selection: $router.sidebarSelection)
            default:
                Color.appBackground
            }
        } detail: {
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
            Button(L10n.Common.Tab.search) { showCommandPalette.toggle() }
                .keyboardShortcut("k", modifiers: .command)
                .opacity(0)
        }
        #endif
    }
    
    // MARK: - TabViews
    
    @available(iOS 18.0, macOS 15.0, macCatalyst 18.0, *)
    @ViewBuilder
    func modernTabView(tintColor: Color) -> some View {
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
            Tab(AppTab.synthesis.displayTitle, systemImage: AppTab.synthesis.icon, value: AppTab.synthesis) {
                synthesisTabContent
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
            Button(L10n.Common.action) {
                showCommandPalette.toggle()
            }
            .keyboardShortcut("k", modifiers: .command)
            .opacity(0)
        }
        #endif
    }
    
    @ViewBuilder
    func legacyTabView(tintColor: Color) -> some View {
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

            synthesisTabContent
                .accessibilityIdentifier("Synthesis")
                .tabItem {
                    Label(AppTab.synthesis.displayTitle, systemImage: AppTab.synthesis.icon)
                }
                .tag(AppTab.synthesis)

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
            Button(L10n.Common.action) {
                showCommandPalette.toggle()
            }
            .keyboardShortcut("k", modifiers: .command)
            .opacity(0)
        }
        #endif
    }
    
    // MARK: - Tab Contents
    
    @ViewBuilder
    var knowledgeTabContent: some View {
        @Bindable var router = router
        if appEnv.screenClass == .compact {
            NavigationStack(path: $router.path) {
                SidebarView(heroNamespace: heroNamespace, selection: $router.sidebarSelection)
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
    
    @ViewBuilder
    var chatTabContent: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            ChatView(selectedTab: $router.selectedTab)
                .id(router.languageForceUpdate)
                .navigationDestination(for: AppRoute.self) { route in
                    ViewFactory.makeView(for: route)
                }
        }
    }
    
    @ViewBuilder
    var graphTabContent: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            GraphContainerView(heroNamespace: heroNamespace, selectedTab: $router.selectedTab)
                .id(router.languageForceUpdate)
                .navigationDestination(for: AppRoute.self) { route in
                    ViewFactory.makeView(for: route)
                }
        }
    }
    
    @ViewBuilder
    var synthesisTabContent: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            SynthesisView(selection: $router.sidebarSelection, selectedTab: $router.selectedTab)
                .id(router.languageForceUpdate)
                .navigationDestination(for: AppRoute.self) { route in
                    ViewFactory.makeView(for: route)
                }
        }
    }

    @ViewBuilder
    var ingestTabContent: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            IngestView(selectedTab: $router.selectedTab)
                .id(router.languageForceUpdate)
                .navigationDestination(for: AppRoute.self) { route in
                ViewFactory.makeView(for: route)
            }
        }
    }

    func consumeDeepLink() {
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
