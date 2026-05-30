//
//  PluginEventBus.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/30.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：属于 Protocols 模块，提供相关的结构体或工具支撑。
//
import Foundation

/// 插件事件总线协议 (L1.5-Domain)
/// 抽象插件事件发布能力，使 Domain 层无需直接依赖 L1 PluginRegistry
@MainActor
public protocol PluginEventBus: Sendable {

    /// 发射一个领域相关的总线事件，所有挂载监听的插件回调都会被触发
    /// - Parameters:
    ///   - event: 通用事件字面量名称
    ///   - data: 与事件关联的非结构化动态数据负载
    func emitEvent(_ event: String, data: Any?)
}
