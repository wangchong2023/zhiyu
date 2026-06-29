//
//  RouterProtocol.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：Protocols。定义智宇路由管理的抽象契约。
//
import Foundation
import Observation

#if canImport(SwiftUI)
import SwiftUI
#endif

/// 智宇全局路由管理器协议
/// 集中管理导航状态，支持解耦跳转与状态持久化
@MainActor
protocol RouterProtocol: AnyObject, Observable {
    #if canImport(SwiftUI)
    /// 全局导航路径 (用于 NavigationStack)
    var path: NavigationPath { get set }
    #endif

    /// 强制 UI 刷新标识（主要用于多语言切换）
    var languageForceUpdate: Bool { get }

    /// 是否正在显示设置面板
    var isShowingSettingsSheet: Bool { get set }

    /// 是否正在显示人工智能参数设置面板
    var isShowingAISettingsSheet: Bool { get set }

    /// 用于在跳转至 AI 对话时自动发送的预设提示词
    var pendingInitialChatPrompt: String? { get set }

    #if !os(watchOS)
    /// 侧边栏当前选中项
    var sidebarSelection: SidebarSelection? { get set }

    /// 当前选中的主 Tab
    var selectedTab: AppTab { get set }

    /// 统一跳转入口
    /// - Parameter route: 目标路由
    func navigate(to route: AppRoute)

    /// 便捷跳转：指定工具
    func navigateToTool(_ tool: ToolItem)
    #endif

    /// 便捷跳转：指定页面
    func navigateToPage(id: UUID)
    
    /// 返回上一级
    func pop()
    
    /// 返回到根视图
    func popToRoot()
    
    /// 触发全局语言刷新
    func triggerLanguageRefresh()
    
    /// 关闭当前显示的 sheet
    func dismissSheet()
}

// MARK: - SwiftUI Support

#if canImport(SwiftUI)
import SwiftUI

extension EnvironmentValues {
    // Router 在 ModuleRegistrar 中注册，早于任何 SwiftUI 视图创建，因此 resolve 安全
    @Entry var router: any RouterProtocol = ServiceContainer.shared.resolve((any RouterProtocol).self)
}
#endif
