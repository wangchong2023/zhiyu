//
//  KnowledgePageProcessor.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：领域层协议定义（Repository、Service、Strategy 等抽象）。
//
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
