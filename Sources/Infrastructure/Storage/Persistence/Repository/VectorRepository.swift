// VectorRepository.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：[Infra] 向量仓库协议：负责分块（Chunks）与向量（Embeddings）的持久化。
// 实现 RAG 基础设施层与核心业务逻辑的解耦。
// 版本: 1.0
// 日期: 2026-05-15
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// [Infra] 向量仓库协议
/// 专门负责 page_chunks 和 page_embeddings 表的操作。
protocol VectorRepository: Sendable {
    
    // MARK: - 向量映射 (Embeddings)
    
    /// 获取所有页面的向量映射
    func fetchAllEmbeddings() async throws -> [UUID: [Float]]
    
    /// 保存单个页面的向量
    func saveEmbedding(id: UUID, vector: [Float], modelName: String) async throws
    
    // MARK: - 语义分块 (Chunks)
    
    /// 获取所有带有向量的分块
    func fetchAllChunksWithEmbeddings() async throws -> [PageChunk]
    
    /// 批量保存分块及其向量
    func saveChunks(pageID: UUID, chunks: [PageChunk]) async throws
    
    /// 删除特定页面的所有分块
    func deleteChunks(for pageID: UUID) async throws
    
    /// 清理孤立的分块（没有对应页面的分块）
    func cleanupOrphanedChunks() async throws -> Int
}
