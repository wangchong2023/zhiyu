//
//  KnowledgeStoreProtocol.swift
//  ZhiYu
//
//  系统层级：[L1.5] 领域层
//  核心职责：Protocols。提供跨层依赖倒置的领域协议契约。
//

import Foundation

/// 知识页面处理器注册协议 (L1.5-Domain)
/// 抽象插件系统对知识页面处理器的注册/注销能力，使 L1 无需直接依赖 L2 KnowledgeStore
@MainActor
public protocol KnowledgeStoreProtocol: Sendable {

    /// 注册Processor
    /// /// - Parameter processor: processor
    /// /// - Parameter pluginID: pluginID
    func registerProcessor(_ processor: any KnowledgePageProcessor, pluginID: String?)

    /// 注销Processors
    func unregisterProcessors(for pluginID: String)
}
