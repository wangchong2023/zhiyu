// NavigateAction.swift
//
// 作者: Wang Chong
// 功能说明: 本文件定义了跨层级的导航动作封装，支持在不直接持有 NavigationPath 的情况下触发页面跳转。
// 核心职责：
// 1. 提供 NavigateAction 环境值。
// 2. 封装对 WikiPage 实体的导航触发逻辑。
// MARK: [PR-03] 统一导航交互抽象，解耦视图与路由状态
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
