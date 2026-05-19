// KnowledgePageProcessor.swift
//
// 作者: Wang Chong
// 功能说明: [L1.5] 领域中心层：知识页面处理器协议，允许第三方插件或系统模块在保存前对页面进行动态干预。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 知识页面处理器协议 (L1.5-Domain)
/// 允许通过注入自定义逻辑对页面内容进行动态修改或增强（例如：自动打标签、敏感词过滤、格式标准化）。
public protocol KnowledgePageProcessor: Sendable {
    /// 处理器唯一标识
    var id: String { get }
    
    /// 处理器显示名称
    var name: String { get }
    
    /// 执行页面处理逻辑
    /// - Parameter page: 原始页面对象
    /// - Returns: 处理后的页面对象
    func process(page: KnowledgePage) async throws -> KnowledgePage
}
