// ContentView.swift
//
// 作者: Wang Chong
// 功能说明: [L3] 应用调度层：本文件实现了知识管理系统的全局根视图（ContentView）。
// 该视图现在作为一个纯粹的“导航调度中心”和生命周期协调者，具体的视图构建逻辑已拆分至 AppLayoutComponents.swift。
// 版本: 1.2
// 修改记录:
//   - 2026-05-16: 表现层精益重构：将 550+ 行文件拆解为原子化组件，核心行数压降至 100 行以内。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 应用程序根视图
/// 负责全局导航分发（Tab/SplitView）、安全遮罩及全局弹窗调度
@MainActor
struct ContentView: View {
    // MARK: - Environment & Dependencies
    @Environment(AppStore.self) var store
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(Router.self) var router
    @Environment(AuthService.self) var authService
    @Environment(VaultService.self) var vaultService
    
    @StateObject internal var tooltipManager = TooltipManager.shared
    @State internal var showCommandPalette = false
    @Namespace internal var heroNamespace
    @EnvironmentObject var onboardingService: OnboardingService
    @EnvironmentObject var medalService: MedalService
    
    @Inject internal var deepLinkService: DeepLinkService
    @Inject internal var appEnv: any AppEnvironmentProtocol
    
    @State internal var showSidebar = false 

    // MARK: - Body
    var body: some View {
        @Bindable var store = store
        @Bindable var router = router
        let tintColor = themeManager.accentColor
        
        ZStack {
            // 背景层
            themeManager.pageBackground()
                .ignoresSafeArea()
            
            // 主内容层
            mainContainer(tintColor: tintColor)
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name.toggleSidebar)) { _ in
                    withAnimation(.spring(response: DesignSystem.Animation.springResponse, dampingFraction: DesignSystem.Animation.springDamping)) {
                        showSidebar.toggle()
                    }
                }
            
            // iPhone 侧边栏抽屉层 (Compact Size Class Only)
            if showSidebar && appEnv.screenClass == .compact {
                sidebarOverlayLayer
            }
        }
        .sheet(isPresented: $router.isShowingSettingsSheet) {
            NavigationStack {
                SettingsView()
            }
        }
        .animation(DesignSystem.Animation.Config.prominentSpring, value: AuthSession.shared.isLoggedIn || AuthSession.shared.isGuest)
        .animation(DesignSystem.Animation.Config.prominentSpring, value: vaultService.selectedVaultID)
        .environmentObject(MedalService.shared)
    }
    
    // MARK: - Sub-layers
    
    @ViewBuilder
    private var sidebarOverlayLayer: some View {
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
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius, style: .continuous))
                .shadow(color: .black.opacity(DesignSystem.shadowOpacity), radius: DesignSystem.shadowRadius)
                .padding(.vertical, DesignSystem.Layout.sidebarOverlayVerticalPadding)
                .padding(.leading, DesignSystem.medium)
            Spacer()
        }
        .transition(.move(edge: .leading))
        .zIndex(DesignSystem.ZIndex.sidebarOverlay)
    }
}

#Preview {
    ContentView()
        .environment(AppStore())
        .environmentObject(ThemeManager())
}
