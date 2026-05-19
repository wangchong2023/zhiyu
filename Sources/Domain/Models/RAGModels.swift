// RAGModels.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：[Infra] RAG 领域模型定义：包含分块（PageChunk）与向量（PageEmbedding）。
// 版本: 1.1
// 修改记录:
//   - 2026-05-15: 补全父子块 (Parent-Child) 与索引偏移元数据支持。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import GRDB

/// 知识分块模型：用于 RAG 检索的原子单位
public struct PageChunk: Identifiable, Codable, FetchableRecord, MutablePersistableRecord, Sendable {
    public static let databaseTableName: String = AppConstants.Storage.Tables.pageChunks
    
    public var id: String        // 格式: pageID_index 或特定前缀
    public var pageID: UUID
    public var parentID: String?  // 父块 ID (用于层级索引)
    public var chunkType: String  // "regular", "summary", "qa_pair"
    public var content: String
    public var anchorPath: String? // 语义层级路径 (例如: "核心原理 > 量子力学")
    public var index: Int         // 排序索引
    public var startIndex: Int    // 在原始文本中的偏移量
    public var embedding: Data?   // 序列化的向量数据
    public var createdAt: Date
    public var updatedAt: Date
    
    public enum CodingKeys: String, CodingKey {
        case id
        case pageID = "page_id"
        case parentID = "parent_id"
        case chunkType = "chunk_type"
        case content
        case anchorPath = "anchor_path"
        case index = "chunk_index"
        case startIndex = "start_index"
        case embedding
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public enum Columns {
        static let id = Column("id")
        static let pageID = Column("page_id")
        static let parentID = Column("parent_id")
        static let chunkType = Column("chunk_type")
        static let content = Column("content")
        static let anchorPath = Column("anchor_path")
        static let index = Column("chunk_index")
        static let startIndex = Column("start_index")
        static let embedding = Column("embedding")
        static let createdAt = Column("created_at")
        static let updatedAt = Column("updated_at")
    }
    
    public init(
        id: String,
        pageID: UUID,
        parentID: String? = nil,
        chunkType: String = "regular",
        content: String,
        anchorPath: String? = nil,
        index: Int,
        startIndex: Int = 0,
        embedding: Data? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.pageID = pageID
        self.parentID = parentID
        self.chunkType = chunkType
        self.content = content
        self.anchorPath = anchorPath
        self.index = index
        self.startIndex = startIndex
        self.embedding = embedding
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// 页面级向量映射模型
public struct PageEmbedding: Identifiable, Codable, FetchableRecord, MutablePersistableRecord, Sendable {
    public static let databaseTableName: String = AppConstants.Storage.Tables.pageEmbeddings
    
    public var id: UUID          // 对应 KnowledgePage.id
    public var vector: [Float]
    public var modelName: String
    
    public enum Columns {
        static let id = Column("id")
        static let vector = Column("vector_blob")
        static let modelName = Column("model_name")
    }
    
    public init(id: UUID, vector: [Float], modelName: String) {
        self.id = id
        self.vector = vector
        self.modelName = modelName
    }
    
    // GRDB 序列化支持
    public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.modelName] = modelName
        let data = vector.withUnsafeBufferPointer { Data(buffer: $0) }
        container[Columns.vector] = data
    }
    
    public init(row: Row) throws {
        id = row[Columns.id]
        modelName = row[Columns.modelName]
        let data: Data = row[Columns.vector]
        vector = data.withUnsafeBytes { pointer in
            Array(UnsafeBufferPointer(start: pointer.baseAddress?.assumingMemoryBound(to: Float.self), count: data.count / MemoryLayout<Float>.size))
        }
    }
}
