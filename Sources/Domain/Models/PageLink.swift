// PageLink.swift
//
// 作者: Wang Chong
// 功能说明: [L1.5] 领域中心层：[Shared] 知识链接模型：定义页面间的双向引用关系。
// 版本: 1.0
// 日期: 2026-05-15
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import GRDB

/// 知识图谱链接模型
public struct PageLink: Codable, Hashable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName: String = AppConstants.Storage.Tables.links
    
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
    
    public enum Columns {
        static let sourceID = Column("source_id")
        static let targetID = Column("target_id")
        static let context = Column("context")
        static let createdAt = Column("created_at")
    }
    
    public init(sourceID: UUID, targetID: UUID, context: String? = nil, createdAt: Date = Date()) {
        self.sourceID = sourceID
        self.targetID = targetID
        self.context = context
        self.createdAt = createdAt
    }
}
