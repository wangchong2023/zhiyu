//
//  ContentView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 应用层
//  核心职责：构建 Content 界面的 UI 视图层组件。
//
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
            
            // 全局新手引导蒙层：确保在工作台及主界面均能正常展示与交互
            OnboardingOverlay(service: onboardingService)
            
            // 全局安全锁定覆盖层：覆盖所有笔记本及工作台视图
            if store.securityService.isLocked {
                LockOverlayView()
                    .transition(AnyTransition.opacity.combined(with: .scale(scale: 1.0 * DesignSystem.Metrics.lockOverlayScaleMultiplier)))
                    .zIndex(DesignSystem.ZIndex.lockOverlay)
            }
        }
        .sheet(isPresented: $router.isShowingSettingsSheet) {
            SettingsView()
                .applySettingsPresentationSizing(screenClass: appEnv.screenClass)
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
                withAnimation(DesignSystem.Animation.Config.prominentSpring) {
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

// MARK: - View Extension for Compatibility

extension View {
    /// 兼容 iOS 18 弹窗尺寸适配修饰符
    @ViewBuilder
    func applyPresentationSizing() -> some View {
        #if os(iOS)
        if #available(iOS 18.0, *) {
            self.presentationSizing(.form)
        } else {
            self
                .frame(minWidth: 540, minHeight: 680)
                .presentationDetents([.large])
        }
        #else
        self.frame(minWidth: 540, minHeight: 680)
        #endif
    }
    
    /// 设置页面专用的自适应宽屏弹窗尺寸修饰符
    /// - Parameter screenClass: 屏幕类型
    @ViewBuilder
    func applySettingsPresentationSizing(screenClass: ScreenClass) -> some View {
        if screenClass == .compact {
            // 手机/紧凑尺寸下，不做多余限制，让系统自动以标准半屏/全屏形式拉起
            self
        } else {
            // iPad 与 Mac 大屏下，强行拓宽界面到 850+ 宽度，为双栏左右分栏提供完美的呈现空间
            #if os(macOS)
            self.frame(width: 900, height: 680)
            #else
            self
                .frame(minWidth: 850, minHeight: 650)
                .presentationDetents([.large])
            #endif
        }
    }
}
