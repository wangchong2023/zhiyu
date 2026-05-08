// ZhiYuApp.swift
//
// 作者: Wang Chong
// 功能说明: 本文件是“知识灵动 (Knowledge Management)”应用程序的顶层入口点。
// 它负责协调整个应用的生命周期，并执行以下核心任务：
// 1. 基础设施注入：初始化 Logger, SQLiteStore, SecurityManager 等底层服务。
// 2. 依赖注入管理：利用 ServiceContainer 实现跨层级服务的解耦与注册。
// 3. 状态树初始化：构建 AppStore 及各类子 Store，驱动 SwiftUI 声明式 UI 的数据流。
// 4. 全局交互定义：配置窗口组、启动闪屏逻辑、全局主题管理及 macOS 原生快捷键命令。
// 版本: 1.2
// 修改记录:
//   - 2026-05-02: 初始架构创建。
//   - 2026-05-05: 升级全工程文档规范，规范化 DI 注入流程与生命周期注释。
// 版权: Copyright © 2026 Wang Chong. All rights reserved.

import SwiftUI

/// 应用程序主入口
/// 负责管理顶层状态树与全局服务生命周期
@main
@MainActor
struct ZhiYuApp: App {
    // ── 顶层状态持有者 ──
    @State private var store: AppStore
    @State private var ingestStore = IngestStore()
    @State private var router = AppRouter.shared
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var llmService = LLMService()
    @State private var synthesisStore = SynthesisStore()
    @AppStorage("hasSeenSplash") private var hasSeenSplash = false
    
    /// 初始化应用环境
    /// 在此阶段完成 L0-L2 层的模块化依赖注入与服务挂载
    init() {
        // 1. 按照分层顺序执行模块化注册
        CoreModuleRegistrar.register(in: ServiceContainer.shared)
        StorageModuleRegistrar.register(in: ServiceContainer.shared)
        DomainModuleRegistrar.register(in: ServiceContainer.shared)
        
        // 2. 初始化核心 AI 服务状态（用于 SwiftUI 状态持有）
        let llm = LLMService.shared
        _llmService = StateObject(wrappedValue: llm)
        
        // 3. 在所有基础服务就绪后，初始化顶层 Store
        _store = State(wrappedValue: AppStore())
        
        // 4. 配置全局 UI 样式
        #if canImport(UIKit)
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(Color.appAccent)
        #endif
        
        print("🚀 [ZHIYU-LIFECYCLE] App Initialized via Modular Registrars at \(Date())")
    }

    /// 应用主场景定义
    var body: some Scene {
        WindowGroup {
            ZStack {
                // 主内容视图：注入所有必需的环境对象
                ContentView()
                    .environment(store)
                    .environment(store.aiWorkflowStore)
                    .environment(synthesisStore)
                    .environment(store.searchStore)
                    .environment(store.settingsStore)
                    .environment(ingestStore)
                    .environment(router)
                    .environmentObject(themeManager)
                    .environmentObject(llmService)
                    .preferredColorScheme(themeManager.colorSchemeMode.preferredColorScheme)
                    .tint(themeManager.accentColor)

                // 启动闪屏层：覆盖在主视图之上
                if !hasSeenSplash {
                    SplashView(onDismiss: {
                        if hasSeenSplash { return } // 防重触发
                        withAnimation(.easeInOut(duration: 0.6)) {
                            print("🔍 [NAV-DIAG] Splash dismissed. Posting notification.")
                            hasSeenSplash = true
                            // 通知系统闪屏已结束，可开始执行一些重型初始化任务
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
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(Localized.tr("creation.newPage")) {
                    NotificationCenter.default.post(name: .createNewPage, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}