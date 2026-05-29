//
//  PageLink+GRDB.swift
//  ZhiYu
//
//  系统层级：[L1] 基础设施层
//  核心职责：Storage。为 Domain 模型提供 GRDB 持久化协议扩展。
//

import GRDB
import Foundation

// MARK: - GRDB 协议遵循
extension PageLink: FetchableRecord, PersistableRecord {}

// MARK: - Database Schema
extension PageLink {
    enum Columns {
        static let sourceID = Column("source_id")
        static let targetID = Column("target_id")
        static let context = Column("context")
        static let createdAt = Column("created_at")
    }
}
