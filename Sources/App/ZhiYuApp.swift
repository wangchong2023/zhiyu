// ZhiYuApp.swift
//
// 作者: Wang Chong
// 功能说明: [L3] 应用调度层：本文件是“知识灵动 (Knowledge Management)”应用程序的顶层入口点。
// 它负责协调整个应用的生命周期，并执行以下核心任务：
// 1. 基础设施注入：初始化 Logger, SQLiteStore, SecurityManager 等底层服务。
// 2. 依赖注入管理：利用 ServiceContainer 实现跨模块解耦。
// 3. UI 根容器：渲染 ContentView 并管理 SplashView 闪屏页面的切换逻辑。
// 版本: 1.2
// 修改记录:
//   - 2026-05-16: 架构补全：补全环境对象注入并实现 Toast 全局覆盖。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

@main
struct ZhiYuApp: App {
    /// 状态持有：App 全局环境（负责所有后台服务的生命周期）
    @State private var appEnv = AppEnvironment.shared
    
    /// 状态持有：主题管理器
    @StateObject private var themeManager = ThemeManager.shared
    
    /// 状态持有：闪屏页可见性
    @State private var hasSeenSplash = false
    
    /// 引导状态持有
    @StateObject private var onboardingService = OnboardingService()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // 主内容视图：注入所有必需的环境对象
                ContentView()
                    .environment(appEnv) // 注入环境持有者自身，修复 SettingsView 崩溃
                    .environment(AuthService.shared)
                    .environment(VaultService.shared)
                    .environment(appEnv.store)
                    .environment(appEnv.store.aiWorkflowStore)
                    .environment(appEnv.store.aiInsightStore)
                    .environment(appEnv.store.searchStore)
                    .environment(appEnv.store.tagStore)
                    .environment(appEnv.store.settingsStore)
                    .environment(appEnv.llmConfig)
                    .environment(appEnv.router)
                    .environment(appEnv.ingestStore)
                    .environment(appEnv.synthesisStore)
                    .environmentObject(themeManager)
                    .environmentObject(appEnv.llmService)
                    .environmentObject(onboardingService)
                    .environmentObject(MedalService.shared)
                    .environment(\.locale, Localized.currentLocale)

                // 启动闪屏层：覆盖在主视图之上
                if !hasSeenSplash {
                    SplashView(onDismiss: {
                        guard !hasSeenSplash else { return }
                        print("🎬 [Splash] 执行退出动画...")
                        withAnimation(.easeInOut(duration: DesignSystem.Animation.slowDuration)) {
                            hasSeenSplash = true
                            NotificationCenter.default.post(name: .splashDismissed, object: nil)
                        }
                    })
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .preferredColorScheme(themeManager.colorSchemeMode.preferredColorScheme)
            .tint(themeManager.accentColor)
            .animation(.easeInOut(duration: 0.6), value: hasSeenSplash)
            .appToast()
        }
        #if os(macOS)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(L10n.Creation.newPage) {
                    NotificationCenter.default.post(name: .createNewPage, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        #endif
    }
}
