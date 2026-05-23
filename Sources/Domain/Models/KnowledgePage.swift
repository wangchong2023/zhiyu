//
//  KnowledgePage.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：属于 Models 模块，提供相关的结构体或工具支撑。
//
import Foundation
import GRDB

// MARK: - Knowledge Page
/// 知识管理系统核心数据模型
public struct KnowledgePage: Identifiable, Codable, Hashable, FetchableRecord, PersistableRecord, Sendable, KnowledgePageRepresentable {
    public static let databaseTableName: String = AppConstants.Storage.Tables.pages
    
    public enum CodingKeys: String, CodingKey {
        case id, title, content, aliases, tags, status, confidence, sources
        case pageType = "page_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case customIcon = "custom_icon"
        case relatedPageIDs = "related_page_ids"
        case isPinned = "is_pinned"
        case contentHash = "content_hash"
        case sourceURL = "source_url"
        case rawTextSnippet = "raw_snippet"
        case fileSize = "file_size"
        case sourceType = "source_type"
        case lamportTimestamp = "lamport_timestamp"
    }
    
    /// 唯一标识符
    public var id: UUID
    
    /// 页面标题
    public var title: String
    
    /// 页面类型 (concept, entity, source, etc.)
    public var pageType: PageType
    
    /// 用户自定义图标 (SF Symbol 名称)，若为 nil 则使用类型默认图标
    public var customIcon: String?
    
    /// Markdown 原始内容
    public var content: String
    
    /// 别名列表
    public var aliases: [String]
    
    /// 标签列表
    public var tags: [String]
    
    /// 页面处理状态
    public var status: PageStatus
    
    /// AI 提取内容的置信度
    public var confidence: Confidence
    
    /// 原始资料来源 ID 引用列表
    public var sources: [String]
    
    /// 关联页面 ID 列表
    public var relatedPageIDs: [UUID]
    
    /// 是否已置顶
    public var isPinned: Bool
    
    /// 内容哈希，用于检测变更
    public var contentHash: String?
    
    /// 创建时间
    public var createdAt: Date
    
    /// 更新时间
    public var updatedAt: Date
    
    // MARK: - 分布式冲突解决 (LWW 策略)
    /// 逻辑时钟，用于解决多端同步冲突
    public var lamportTimestamp: Int64
    
    // MARK: - 溯源字段 (Karpathy 模式)
    /// 原始资料链接 (网页或 YouTube)
    public var sourceURL: String?
    /// 原始资料片段，用于校验
    public var rawTextSnippet: String?
    /// 文件大小 (字节)
    public var fileSize: Int64?
    /// 来源类型 (pdf, text, doc, etc.)
    public var sourceType: String?
    
    /// 显示图标：优先使用自定义图标，否则使用页面类型默认图标
    public var displayIcon: String {
        customIcon ?? pageType.icon
    }

    public init(
        id: UUID = UUID(),
        title: String,
        pageType: PageType = .concept,
        customIcon: String? = nil,
        content: String = "",
        aliases: [String] = [],
        tags: [String] = [],
        status: PageStatus = .active,
        confidence: Confidence = .medium,
        sources: [String] = [],
        relatedPageIDs: [UUID] = [],
        isPinned: Bool = false,
        contentHash: String? = nil,
        sourceURL: String? = nil,
        rawTextSnippet: String? = nil,
        fileSize: Int64? = nil,
        sourceType: String? = nil,
        lamportTimestamp: Int64? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.pageType = pageType
        self.customIcon = customIcon
        self.content = content
        self.aliases = aliases
        self.tags = tags
        self.status = status
        self.confidence = confidence
        self.sources = sources
        self.relatedPageIDs = relatedPageIDs
        self.isPinned = isPinned
        self.contentHash = contentHash
        self.sourceURL = sourceURL
        self.rawTextSnippet = rawTextSnippet
        self.fileSize = fileSize ?? Int64(content.utf8.count)
        self.sourceType = sourceType
        self.lamportTimestamp = lamportTimestamp ?? Int64(createdAt.timeIntervalSince1970 * 1000)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Database Schema (Type-Safe Industrial Standard)
    /// 定义数据库列名，遵循 ColumnExpression 协议。
    /// 业界方案：利用枚举 rawValue 映射列名，实现编译期静态检查。
    enum Columns: String, ColumnExpression {
        case id
        case title
        case pageType = "page_type"
        case content
        case aliases
        case tags
        case status
        case confidence
        case sources
        case relatedPageIDs = "related_page_ids"
        case isPinned = "is_pinned"
        case contentHash = "content_hash"
        case customIcon = "custom_icon"
        case sourceURL = "source_url"
        case rawTextSnippet = "raw_snippet"
        case fileSize = "file_size"
        case sourceType = "source_type"
        case lamportTimestamp = "lamport_timestamp"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// 执行 LWW (Last Write Wins) 冲突合并
    /// - Parameter remote: 远程或同步过来的版本
    /// - Returns: 合并后的最终版本
    public func merge(with remote: KnowledgePage) -> KnowledgePage {
        // 核心规则：时间戳大的胜出
        if remote.lamportTimestamp > self.lamportTimestamp {
            return remote
        } else if remote.lamportTimestamp < self.lamportTimestamp {
            return self
        } else {
            // 时间戳一致时，以更新时间为准
            return remote.updatedAt > self.updatedAt ? remote : self
        }
    }
    
    /// 执行 [[知识链接]] 提取
    public var outgoingLinks: [String] {
        AppLinkProcessor.extractOutgoingLinks(from: content)
    }
    
    /// 计算字数 (支持中英混排)
    /// 逻辑：中文按字符计费；英文按单词计数。
    public var wordCount: Int {
        var count = 0
        var inEnglishWord = false
        
        for char in content {
            if char.isCJKCharacter {
                if inEnglishWord {
                    count += 1
                    inEnglishWord = false
                }
                count += 1
            } else if char.isLetter || char.isNumber {
                inEnglishWord = true
            } else if inEnglishWord {
                count += 1
                inEnglishWord = false
            }
        }
        if inEnglishWord { count += 1 }
        return count
    }
    
    /// 是否为存根页面 (内容过少)
    public var isStub: Bool {
        content.count < 100
    }
    
    /// 获取存储文件夹名称
    public var folderName: String {
        switch pageType {
        case .entity: return "entities"
        case .concept: return "concepts"
        case .source: return "sources"
        case .comparison: return "comparisons"
        case .map: return "maps"
        case .raw: return "raw"
        }
    }

    /// 隐私敏感判定
    public var isPrivate: Bool {
        getAllTags().contains("private")
    }

    /// 获取所有标签（包括元数据标签和内容中的 #标签）
    public func getAllTags() -> [String] {
        var allTags = Set(tags)
        // 简单提取内容中的 #标签 (如 #tag1 #tag2)
        let pattern = "#([\\w\\u4e00-\\u9fa5]+)"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let nsText = content as NSString
            let matches = regex.matches(in: content, range: NSRange(location: 0, length: nsText.length))
            for match in matches {
                if match.numberOfRanges > 1 {
                    allTags.insert(nsText.substring(with: match.range(at: 1)))
                }
            }
        }
        return Array(allTags)
    }
}

// MARK: - GRDB 数组持久化支持
// 工业级做法：通过 JSON 序列化存储数组类型。
extension Array: @retroactive DatabaseValueConvertible where Element: Codable {
    public var databaseValue: DatabaseValue {
        guard let data = try? JSONEncoder().encode(self),
              let string = String(data: data, encoding: .utf8) else {
            return .null
        }
        return string.databaseValue
    }
    
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> [Element]? {
        guard let string = String.fromDatabaseValue(dbValue),
              let data = string.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
}

// 必须显式声明父协议遵循
extension Array: @retroactive SQLExpressible where Element: Codable { }
extension Array: @retroactive StatementBinding where Element: Codable { }

extension Array: @retroactive StatementColumnConvertible where Element: Codable {
    public init?(sqliteStatement: SQLiteStatement, index: Int32) {
        let dbValue = DatabaseValue(sqliteStatement: sqliteStatement, index: CInt(index))
        if let array = Self.fromDatabaseValue(dbValue) {
            self = array
        } else {
            return nil
        }
    }
}

