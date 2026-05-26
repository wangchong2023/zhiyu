//
//  UserProfileMenu.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：属于 Menus 模块，提供相关的结构体或工具支撑。
//
import SwiftUI

struct UserProfileMenu: View {
    @Environment(AuthService.self) var authService
    @Environment(AppStore.self) var store
    @Environment(Router.self) var router
    @EnvironmentObject var onboardingService: OnboardingService
    @EnvironmentObject var themeManager: ThemeManager
    
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
        .sheet(isPresented: $showAbout) { aboutStack }
        #else
        // iOS, iPadOS, macOS (Catalyst) 等非 watch 平台统一使用原生 Menu，提供 0 延迟的即时响应体感
        Menu {
            Button(action: {
                HapticFeedback.shared.trigger(.selection)
                // 预留 80 毫秒微小延时让系统下拉菜单启动收起动画，规避与 Sheet 弹出转场重叠冲突，实现极速秒开
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    router.isShowingSettingsSheet = true
                }
            }) {
                Label(L10n.Common.settings, systemImage: DesignSystem.Icons.settings)
            }
            
            Button(action: {
                HapticFeedback.shared.trigger(.selection)
                // 同步采用异步微延迟，彻底规避原生动画引擎冲突
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    showStats = true
                }
            }) {
                Label(L10n.Common.usage, systemImage: "chart.bar.fill")
            }
            
            Button(action: {
                HapticFeedback.shared.trigger(.selection)
                store.securityService.lock()
                store.requestRelayout()
            }) {
                Label(L10n.Common.lock, systemImage: DesignSystem.Icons.lock)
            }
            
            Divider()
            
            Button(role: .destructive, action: {
                HapticFeedback.shared.trigger(.selection)
                authService.logout()
            }) {
                Label(L10n.Common.logout, systemImage: DesignSystem.Icons.logout)
            }
        } label: {
            profileLabel
        }
        .buttonStyle(.plain) // 消除系统在 Toolbar 选项中默认添加的 bordered 灰色背景
        .sheet(isPresented: $showAbout) { aboutStack.environment(store).environmentObject(themeManager) }
        .sheet(isPresented: $showStats) {
            NavigationStack {
                SystemStatsView()
            }
            .environment(store)
            .environmentObject(themeManager)
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
