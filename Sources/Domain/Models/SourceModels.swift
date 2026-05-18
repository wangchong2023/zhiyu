// SourceModels.swift
//
// 作者: Wang Chong
// 功能说明: [L1.5] 领域层：信源模型，对标 NotebookLM 的信源引用机制
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// AI 引用信源模型
public struct KnowledgeSource: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let pageID: UUID      // 关联的原文页面 ID
    public let title: String     // 页面标题
    public let snippet: String   // 引用的文本片段
    public let anchorPath: String? // 语义路径 (如: "原理 > 分块算法")
    public let score: Double     // 相似度或置信度分数 (0.0 - 1.0)
    public let timestamp: Date
    
    public init(id: UUID = UUID(), pageID: UUID, title: String, snippet: String, anchorPath: String? = nil, score: Double, timestamp: Date = Date()) {
        self.id = id
        self.pageID = pageID
        self.title = title
        self.snippet = snippet
        self.anchorPath = anchorPath
        self.score = score
        self.timestamp = timestamp
    }
}
