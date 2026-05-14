// ZhiYuApp.swift
//
// 作者: Wang Chong
// 功能说明: 本文件是“知识灵动 (Knowledge Management)”应用程序的顶层入口点。
// 它负责协调整个应用的生命周期，并执行以下核心任务：
// 1. 基础设施注入：初始化 Logger, SQLiteStore, SecurityManager 等底层服务。
// 2. 依赖注入管理：利用 ServiceContainer 实现跨层级服务的解耦与注册。
// 3. 状态树初始化：构建 AppStore 及各类子 Store，驱动 SwiftUI 声明式 UI 的数据流。
// 4. 全局交互定义：配置窗口组、启动闪屏逻辑、全局主题管理及 macOS 原生快捷键命令。
// 版本: 1.3
// 修改记录:
//   - 2026-05-13: [SR-04] 重构应用环境管理，引入 AppEnvironment 与全局 Router。
// 版权: Copyright © 2026 Wang Chong. All rights reserved.

import SwiftUI

#if !os(watchOS)
@main
#endif
@MainActor
struct ZhiYuApp: App {
    // ── 顶层环境持有者 ──
    @State private var appEnv: AppEnvironment = AppEnvironment.shared
    @AppStorage("hasSeenSplash") private var hasSeenSplash = false
    
    /// 初始化应用
    init() {
        // AppEnvironment.shared 会在首次访问时完成 L0-L2 的注入与 Store 初始化
        _ = AppEnvironment.shared
    }

    /// 应用主场景定义
    var body: some Scene {
        WindowGroup {
            ZStack {
                // 主内容视图：注入所有必需的环境对象
                ContentView()
                    .environment(AuthService.shared)
                    .environment(VaultService.shared)
                    .environment(appEnv.store)
                    .environment(appEnv.store.aiWorkflowStore)
                    .environment(appEnv.synthesisStore)
                    .environment(appEnv.store.searchStore)
                    .environment(appEnv.store.settingsStore)
                    .environment(appEnv.ingestStore)
                    .environment(appEnv.router)
                    .environmentObject(appEnv.themeManager)
                    .environmentObject(appEnv.llmService)
                    .environment(\.locale, Localized.currentLocale)
                    .preferredColorScheme(appEnv.themeManager.colorSchemeMode.preferredColorScheme)
                    .tint(appEnv.themeManager.accentColor)

                // 启动闪屏层：覆盖在主视图之上
                if !hasSeenSplash {
                    SplashView(onDismiss: {
                        if hasSeenSplash { return }
                        withAnimation(.easeInOut(duration: 0.6)) {
                            hasSeenSplash = true
                            NotificationCenter.default.post(name: NSNotification.Name("splashDismissed"), object: nil)
                        }
                    })
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.6), value: hasSeenSplash)
        }
        // macOS / iPadOS 原生快捷键指令组
        #if !os(watchOS)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(Localized.tr("creation.newPage")) {
                    NotificationCenter.default.post(name: .createNewPage, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        #endif
    }
}
