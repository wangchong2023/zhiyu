//
//  StubLinkService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/30.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：提供 watchOS 端轻量的双向引用与链接适配桩服务。
//

import Foundation

/// watchOS 适配的轻量双向链接服务桩 (StubLinkService)
/// 规避 watchOS 端引入 RAG / 向量库等重型后台模块，仅在内存中进行简单的标题对比
public final class StubLinkService: LinkServiceProtocol {
    
    /// 构造函数
    public init() {}
    
    /// 根据标题或别名查找页面 (不区分大小写)
    /// - Parameters:
    ///   - title: 目标标题
    ///   - pages: 搜索数据集范围
    /// - Returns: 匹配到的知识页面实体，若无返回 nil
    public func pageByTitle(_ title: String, in pages: [KnowledgePage]) async -> KnowledgePage? {
        pages.first { $0.title.lowercased() == title.lowercased() }
    }
    
    /// 执行页面重命名前的双向引用自动更新调整 (在 watchOS 下仅简单修改当前页标题)
    /// - Parameters:
    ///   - page: 被修改的原始页面对象
    ///   - newTitle: 拟设定的新页面标题
    ///   - pages: 整个知识库的当前全量页面数据集
    /// - Returns: 被修改后的新页面对象列表
    public func prepareRename(page: KnowledgePage, to newTitle: String, in pages: [KnowledgePage]) async -> [KnowledgePage] {
        var updated = page
        updated.title = newTitle
        updated.updatedAt = Date()
        return [updated]
    }
}
