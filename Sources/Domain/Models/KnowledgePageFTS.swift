// KnowledgePageFTS.swift
//
// 作者: Wang Chong
// 功能说明: [L1.5] 领域中心层：[Shared] FTS5 搜索索引模型：用于全文检索加速。
// 版本: 1.0
// 日期: 2026-05-15
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import GRDB

/// 全文搜索索引模型 (FTS5)
public struct KnowledgePageFTS: Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName: String = AppConstants.Storage.Tables.pagesFTS
    
    public var id: String
    public var title: String
    public var content: String
    public var tags: String?
    public var aliases: String?
    
    public init(id: String, title: String, content: String, tags: String? = nil, aliases: String? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.tags = tags
        self.aliases = aliases
    }
}
