//
//  ImportRecord.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/10.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：导入原始内容留存数据模型

import Foundation
import GRDB

/// 导入原始内容留存记录
public struct ImportRecord: Identifiable, Codable, FetchableRecord, MutablePersistableRecord, Sendable {
    public static let databaseTableName: String = AppConstants.Storage.Tables.importRecords

    public var id: String       // UUID 字符串
    public var category: String // link / file / manual / ocr / clipboard / voice
    public var title: String
    public var status: String   // pending / processing / done / failed
    public var rawText: String? // 文本类原始内容
    public var sourceURL: String?
    public var filePath: String? // 大文件磁盘路径
    public var fileSize: Int64?  // 文件大小（字节）
    public var pageID: String?   // 关联 KnowledgePage UUID
    public var vaultID: String?  // 关联 Vault UUID
    public var taskID: String?   // 关联 GlobalTask UUID
    public var createdAt: Date
    public var completedAt: Date?

    public enum CodingKeys: String, CodingKey, ColumnExpression {
        case id, category, title, status
        case rawText = "raw_text"
        case sourceURL = "source_url"
        case filePath = "file_path"
        case fileSize = "file_size"
        case pageID = "page_id"
        case vaultID = "vault_id"
        case taskID = "task_id"
        case createdAt = "created_at"
        case completedAt = "completed_at"
    }

    public init(
        id: String = UUID().uuidString,
        category: String,
        title: String,
        status: String = "pending",
        rawText: String? = nil,
        sourceURL: String? = nil,
        filePath: String? = nil,
        fileSize: Int64? = nil,
        pageID: String? = nil,
        vaultID: String? = nil,
        taskID: String? = nil,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.status = status
        self.rawText = rawText
        self.sourceURL = sourceURL
        self.filePath = filePath
        self.fileSize = fileSize
        self.pageID = pageID
        self.vaultID = vaultID
        self.taskID = taskID
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}

/// 导入分类枚举
public enum ImportCategory: String, CaseIterable, Sendable {
    case link = "link"
    case file = "file"
    case manual = "manual"
    case ocr = "ocr"
    case clipboard = "clipboard"
    case voice = "voice"
}
