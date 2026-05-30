//
//  PageLink+GRDB.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/30.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：属于 Extensions 模块，提供相关的结构体或工具支撑。
//
import GRDB
import Foundation

// MARK: - GRDB 协议遵循
extension PageLink: FetchableRecord, PersistableRecord {}

// MARK: - Database Table Name
extension PageLink {
    public static let databaseTableName = AppConstants.Storage.Tables.links
}

// MARK: - Database Schema
extension PageLink {
    enum Columns {
        static let sourceID = Column("source_id")
        static let targetID = Column("target_id")
        static let context = Column("context")
        static let createdAt = Column("created_at")
    }
}
