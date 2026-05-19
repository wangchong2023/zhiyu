// UserProfileMenu.swift
//
// 作者: Wang Chong
// 功能说明: [Shared] 本文件实现了全系统通用的用户个人资料菜单（UserProfileMenu）。
// 该组件集成了：
// 1. 账户管理：显示当前登录状态并支持登出。
// 2. 安全控制：快捷锁定应用程序。
// 3. 系统设置：跳转至全局设置页面。
// 4. 交互引导：重新触发功能引导与新手教程。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

struct UserProfileMenu: View {
    @Environment(AuthService.self) var authService
    @Environment(AppStore.self) var store
    @Environment(Router.self) var router
    @EnvironmentObject var onboardingService: OnboardingService
    
    @State private var showAbout = false
    @State private var showWatchMenu = false
    @State private var showStats = false
    
    var body: some View {
        #if os(watchOS)
        Button(action: { showWatchMenu = true }) {
            profileLabel
        }
        .sheet(isPresented: $showWatchMenu) {
            List {
                Button(action: { showSettings = true; showWatchMenu = false }) {
                    Label(L10n.Common.settings, systemImage: DesignSystem.Icons.settings)
                }
                Button(action: { store.securityService.lock(); showWatchMenu = false }) {
                    Label(L10n.Common.lock, systemImage: DesignSystem.Icons.lock)
                }
                Button(role: .destructive, action: { authService.logout(); showWatchMenu = false }) {
                    Label(L10n.Common.logout, systemImage: DesignSystem.Icons.logout)
                }
            }
        }
        .sheet(isPresented: $showSettings) { settingsStack }
        .sheet(isPresented: $showAbout) { aboutStack }
        #else
        Button(action: {
            HapticFeedback.shared.trigger(.selection)
            showWatchMenu = true // 借用作为非 watchOS 下控制 popover 的状态变量
        }) {
            profileLabel
        }
        .buttonStyle(.plain)  // 消除 SwiftUI 在 Toolbar 中给 Menu 自动添加的 bordered 白色背景
        .popover(isPresented: $showWatchMenu, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                // 1. 系统设置
                Button(action: {
                    showWatchMenu = false
                    HapticFeedback.shared.trigger(.selection)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        router.isShowingSettingsSheet = true
                    }
                }) {
                    HStack(spacing: Spacing.standardPadding) {
                        Image(systemName: DesignSystem.Icons.settings)
                            .font(.system(size: 14))
                            .foregroundStyle(.appAccent)
                            .frame(width: 20, alignment: .center)
                        Text(L10n.Common.settings)
                            .font(.subheadline.bold())
                            .foregroundStyle(.appText)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                Divider()
                    .background(Color.appCard.opacity(0.3))
                
                // 2. 用量诊断
                Button(action: {
                    showWatchMenu = false
                    HapticFeedback.shared.trigger(.selection)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        showStats = true
                    }
                }) {
                    HStack(spacing: Spacing.standardPadding) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.appAccent)
                            .frame(width: 20, alignment: .center)
                        Text(L10n.Common.usage)
                            .font(.subheadline.bold())
                            .foregroundStyle(.appText)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                Divider()
                    .background(Color.appCard.opacity(0.3))
                
                // 3. 快速锁定
                Button(action: {
                    showWatchMenu = false
                    HapticFeedback.shared.trigger(.selection)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        store.securityService.lock()
                        store.requestRelayout() // 强制触发 UI 状态评估
                    }
                }) {
                    HStack(spacing: Spacing.standardPadding) {
                        Image(systemName: DesignSystem.Icons.lock)
                            .font(.system(size: 14))
                            .foregroundStyle(.appAccent)
                            .frame(width: 20, alignment: .center)
                        Text(L10n.Common.lock)
                            .font(.subheadline.bold())
                            .foregroundStyle(.appText)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                Divider()
                    .background(Color.appCard.opacity(0.3))
                
                // 4. 退出登录
                Button(action: {
                    showWatchMenu = false
                    HapticFeedback.shared.trigger(.selection)
                    authService.logout()
                }) {
                    HStack(spacing: Spacing.standardPadding) {
                        Image(systemName: DesignSystem.Icons.logout)
                            .font(.system(size: 14))
                            .foregroundStyle(.red)
                            .frame(width: 20, alignment: .center)
                        Text(L10n.Common.logout)
                            .font(.subheadline.bold())
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .frame(width: 155) // 精密控制气泡宽度为 155，在极其修长克制的同时，完美解除偏挤感，带来大气的呼吸空气感！
            .presentationCompactAdaptation(.popover) // 强制在 iOS iPhone/macOS Catalyst 平台全部以 Popover 指向气泡形式渲染，拒绝降级拉伸！
        }
        .sheet(isPresented: $showAbout) { aboutStack }
        .sheet(isPresented: $showStats) {
            NavigationStack {
                SystemStatsView()
            }
        }
        #endif
    }
    
    private var profileLabel: some View {
        Group {
            if authService.isGuest {
                Image(systemName: DesignSystem.Icons.personCrop)
                    .font(.system(size: DesignSystem.bodyFontSize, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
            } else {
                Image(systemName: DesignSystem.Icons.personCropFill)
                    .font(.system(size: DesignSystem.headlineFontSize, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .foregroundStyle(.appAccent)
        .frame(width: DesignSystem.Action.minTouchTarget, height: DesignSystem.Action.minTouchTarget)
        .contentShape(Circle())
    }
    
    private var aboutStack: some View {
        NavigationStack {
            AboutView()
        }
    }
}
