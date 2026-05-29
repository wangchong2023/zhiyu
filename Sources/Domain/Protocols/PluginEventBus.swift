//
//  PluginEventBus.swift
//  ZhiYu
//
//  系统层级：[L1.5] 领域层
//  核心职责：Protocols。提供跨层依赖倒置的领域协议契约。
//

import Foundation

/// 插件事件总线协议 (L1.5-Domain)
/// 抽象插件事件发布能力，使 Domain 层无需直接依赖 L1 PluginRegistry
@MainActor
public protocol PluginEventBus: Sendable {

    /// emitEvent
    /// /// - Parameter event: event
    /// /// - Parameter data: data
    func emitEvent(_ event: String, data: Any?)
}
