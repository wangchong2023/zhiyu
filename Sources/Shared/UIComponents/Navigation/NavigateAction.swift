//
//  NavigateAction.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：可复用 UI 组件库：编辑器、卡片、加载态、空状态等通用视图。
//
import SwiftUI

/// 跨视图层级触发导航的动作闭包
/// 允许子视图在不持有全局路径引用的情况下，通过环境值发起页面跳转。
struct NavigateAction: Sendable {
    private let action: @Sendable (KnowledgePage) -> Void
    
    init(action: @escaping @Sendable (KnowledgePage) -> Void) {
        self.action = action
    }
    
    /// 执行导航动作
    /// - Parameter page: 目标知识页面
    func callAsFunction(_ page: KnowledgePage) {
        action(page)
    }
}

// MARK: - Environment Key

struct NavigateActionKey: EnvironmentKey {
    static let defaultValue = NavigateAction(action: { _ in })
}

extension EnvironmentValues {
    /// 导航动作环境值
    var navigate: NavigateAction {
        get { self[NavigateActionKey.self] }
        set { self[NavigateActionKey.self] = newValue }
    }
}
