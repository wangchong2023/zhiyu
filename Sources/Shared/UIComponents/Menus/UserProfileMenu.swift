// UserProfileMenu.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了全系统通用的用户个人资料菜单（UserProfileMenu）。
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
    
    @State private var showSettings = false
    @State private var showAbout = false
    @State private var showWatchMenu = false
    
    var body: some View {
        #if os(watchOS)
        Button(action: { showWatchMenu = true }) {
            profileLabel
        }
        .sheet(isPresented: $showWatchMenu) {
            List {
                Button(action: { showSettings = true; showWatchMenu = false }) {
                    Label(L10n.Common.tr("settings"), systemImage: "gearshape.fill")
                }
                Button(action: { store.securityService.lock(); showWatchMenu = false }) {
                    Label(L10n.Common.tr("lock"), systemImage: "lock.fill")
                }
                Button(role: .destructive, action: { authService.logout(); showWatchMenu = false }) {
                    Label(L10n.Auth.tr("logout"), systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .sheet(isPresented: $showSettings) { settingsStack }
        .sheet(isPresented: $showAbout) { aboutStack }
        #else
        Menu {
            Button(action: { showSettings = true }) {
                Label(L10n.Common.tr("settings"), systemImage: "gearshape.fill")
            }
            
            Button(action: {
                HapticFeedback.shared.trigger(.selection)
                store.securityService.lock()
                store.requestRelayout() // 强制触发 UI 状态评估
            }) {
                Label(L10n.Common.tr("lock"), systemImage: "lock.fill")
            }
            
            Button(action: {
                HapticFeedback.shared.trigger(.selection)
                onboardingService.reset()
                onboardingService.nextStep()
                store.pendingCoachMark = .graphDiscovery
                store.requestRelayout() // 强制触发 UI 状态评估
            }) {
                Label(L10n.Common.tr("help"), systemImage: "questionmark.circle")
            }
            
            Divider()
            
            Button(role: .destructive, action: { authService.logout() }) {
                Label(L10n.Auth.tr("logout"), systemImage: "rectangle.portrait.and.arrow.right")
            }
        } label: {
            profileLabel
        }
        .buttonStyle(.plain)  // 消除 SwiftUI 在 Toolbar 中给 Menu 自动添加的 bordered 白色背景
        .sheet(isPresented: $showSettings) { settingsStack }
        .sheet(isPresented: $showAbout) { aboutStack }
        #endif
    }
    
    private var profileLabel: some View {
        Group {
            if authService.isGuest {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: DesignSystem.bodyFontSize, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: DesignSystem.headlineFontSize, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .foregroundStyle(.appAccent)
        .frame(width: DesignSystem.Action.minTouchTarget, height: DesignSystem.Action.minTouchTarget)
        .contentShape(Circle())
    }
    
    private var settingsStack: some View {
        NavigationStack {
            SettingsView(onboardingService: onboardingService)
        }
    }
    
    private var aboutStack: some View {
        NavigationStack {
            AboutView()
        }
    }
}
