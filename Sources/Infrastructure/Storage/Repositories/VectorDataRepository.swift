//
//  VectorDataRepository.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：属于 Repositories 模块，提供相关的结构体或工具支撑。
//
import Foundation
import GRDB

/// [Infra] 向量存储实现
final class VectorDataRepository: VectorRepository, @unchecked Sendable {
    private let dbWriter: any DatabaseWriter

    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }

    // MARK: - 向量映射 (Embeddings)

    func saveEmbedding(id: UUID, vector: [Float], modelName: String) async throws {
        _ = try await dbWriter.write { db in
            var entry = PageEmbedding(id: id, vector: vector, modelName: modelName)
            try entry.save(db)
        }
    }

    func fetchAllEmbeddings() async throws -> [UUID: [Float]] {
        try await dbWriter.read { db in
            let records = try PageEmbedding.fetchAll(db)
            var dict: [UUID: [Float]] = [:]
            for record in records {
                dict[record.id] = record.vector
            }
            return dict
        }
    }

    // MARK: - 语义分块 (Chunks)

    func fetchChunks(for pageID: UUID) async throws -> [PageChunk] {
        try await dbWriter.read { db in
            try PageChunk
                .filter(PageChunk.Columns.pageID == pageID)
                .fetchAll(db)
        }
    }

    func fetchAllChunksWithEmbeddings() async throws -> [PageChunk] {
        try await dbWriter.read { db in
            try PageChunk
                .filter(PageChunk.Columns.embedding != nil)
                .fetchAll(db)
        }
    }

    func saveChunks(_ chunks: [PageChunk], for pageID: UUID) async throws {
        _ = try await dbWriter.write { db in
            // 物理删除旧分块，确保索引最新
            try PageChunk
                .filter(PageChunk.Columns.pageID == pageID)
                .deleteAll(db)
            
            for var chunk in chunks {
                chunk.pageID = pageID
                chunk.createdAt = Date()
                chunk.updatedAt = Date()
                try chunk.insert(db)
            }
        }
    }

    func deleteChunks(for pageID: UUID) async throws {
        _ = try await dbWriter.write { db in
            try PageChunk
                .filter(PageChunk.Columns.pageID == pageID)
                .deleteAll(db)
        }
    }

    func cleanupOrphanedChunks() async throws -> Int {
        try await dbWriter.write { db in
            // 使用 Query Interface 的 subquery 方式替代原始 SQL
            let pages = KnowledgePage.select(KnowledgePage.Columns.id)
            let deletedCount = try PageChunk
                .filter(!pages.contains(PageChunk.Columns.pageID))
                .deleteAll(db)
            return deletedCount
        }
    }
}
