// VectorDataRepository.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：[Infra] 向量存储实现：负责 RAG 分块与向量检索数据的持久化。
// 遵循 VectorRepository 协议，采用 GRDB ORM 模式实现。
// 版本: 1.2
// 修改记录:
//   - 2026-05-16: 物理归位重构：更名为 VectorDataRepository。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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

    func fetchAllChunksWithEmbeddings() async throws -> [PageChunk] {
        try await dbWriter.read { db in
            try PageChunk
                .filter(PageChunk.Columns.embedding != nil)
                .fetchAll(db)
        }
    }

    func saveChunks(pageID: UUID, chunks: [PageChunk]) async throws {
        _ = try await dbWriter.write { db in
            // 物理删除旧分块，确保索引最新
            try PageChunk
                .filter(PageChunk.Columns.pageID == pageID)
                .deleteAll(db)
            
            for var chunk in chunks {
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
