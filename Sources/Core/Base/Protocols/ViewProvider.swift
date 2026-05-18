// ViewProvider.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：视图提供者协议，用于实现表现层的依赖倒置与插件化视图发现。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 视图提供者协议
/// 每个业务领域 (Sub-Domain) 实现此协议，负责构建其内部模块的视图。
/// 使用 AnyHashable 作为路由参数类型，使本协议保持平台无关性，
/// 避免对 App 层（L3）类型 AppRoute 的跨层依赖。
public protocol ViewProvider: Sendable {
    /// 根据路由构建对应的视图
    /// - Parameter route: 目标路由，使用 AnyHashable 保持平台无关性
    /// - Returns: 抹除类型后的视图，如果不属于该提供者范畴则返回 nil
    @MainActor
    func makeView(for route: AnyHashable) -> AnyView?
}
