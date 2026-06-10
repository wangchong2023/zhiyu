//
//  PageLink.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：核心领域模型定义（KnowledgePage、PageLink、PluginRecord 等）。
//
import Foundation

/// 知识图谱链接模型
public struct PageLink: Codable, Hashable, Sendable {
    
    public var sourceID: UUID
    public var targetID: UUID
    public var context: String?
    public var createdAt: Date
    
    public enum CodingKeys: String, CodingKey {
        case sourceID = "source_id"
        case targetID = "target_id"
        case context
        case createdAt = "created_at"
    }
    
    public init(sourceID: UUID, targetID: UUID, context: String? = nil, createdAt: Date = Date()) {
        self.sourceID = sourceID
        self.targetID = targetID
        self.context = context
        self.createdAt = createdAt
    }
}
