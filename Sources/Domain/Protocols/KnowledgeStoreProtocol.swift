//
//  KnowledgeStoreProtocol.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/30.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：定义 KnowledgeStore 模块的抽象契约接口。
//
import Foundation

/// 知识页面处理器注册协议 (L1.5-Domain)
/// 抽象插件系统对知识页面处理器的注册/注销能力，使 L1 无需直接依赖 L2 KnowledgeStore
@MainActor
public protocol KnowledgeStoreProtocol: Sendable {

    /// 挂载或注入一个遵循标准的文档处理器实例
    /// - Parameters:
    ///   - processor: 需要介入文档摄取或渲染生命周期的处理器
    ///   - pluginID: 发起注册的源插件 ID（用于后续卸载追溯，核心功能传入 nil）
    func registerProcessor(_ processor: any KnowledgePageProcessor, pluginID: String?)

    /// 取消挂载某个外部插件带来的全部动态处理器，防止内存或业务泄漏
    /// - Parameter pluginID: 目标插件 ID
    func unregisterProcessors(for pluginID: String)
}