//
//  ZhiYuWatchApp.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：属于 Resources 模块，提供相关的结构体或工具支撑。
//
import SwiftUI

/// Apple Watch 应用程序入口
@main
struct AppWatchApp: App {
    /// 构造函数，在 watchOS App 启动时进行基础模块注册，保障系统 @Inject 的安全解析边界
    init() {
        WatchModuleRegistrar.register(in: ServiceContainer.shared)
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                WatchDictationView()
                WatchKnowledgeStatsView()
                WatchBriefingView()
            }
            .tabViewStyle(.verticalPage)
        }
    }
}
