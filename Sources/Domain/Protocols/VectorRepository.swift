// VectorRepository.swift
//
// 作者: Wang Chong
// 功能说明: [L1.5] 领域中心层：向量存储仓库协议，定义了分块存储、向量持久化及清理逻辑。
// 版本: 1.3
// 修改记录:
//   - 2026-05-16: 契约下沉：从 L1 迁移至 L1.5 领域层，实现依赖倒置。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// [Domain] 向量与分块仓储协议
public protocol VectorRepository: Sendable {
    // MARK: - 语义分块 (Chunks)
    
    /// 保存页面的分块数据
    func saveChunks(_ chunks: [PageChunk], for pageID: UUID) async throws
    
    /// 获取特定页面的所有分块
    func fetchChunks(for pageID: UUID) async throws -> [PageChunk]
    
    /// 获取知识库中所有具备向量嵌入的分块 (用于冷启动缓存)
    func fetchAllChunksWithEmbeddings() async throws -> [PageChunk]
    
    /// 删除特定页面的所有分块
    func deleteChunks(for pageID: UUID) async throws
    
    /// 清理孤立分块 (即其所属页面已删除的分块)
    func cleanupOrphanedChunks() async throws -> Int

    // MARK: - 页面级向量 (Embeddings)
    
    /// 保存页面级向量嵌入
    func saveEmbedding(id: UUID, vector: [Float], modelName: String) async throws
    
    /// 获取知识库中所有页面的向量嵌入 (用于冷启动缓存)
    func fetchAllEmbeddings() async throws -> [UUID: [Float]]
}
