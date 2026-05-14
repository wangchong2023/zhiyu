// VectorIndexer.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了向量索引处理器，负责将分块后的文本转化为向量并执行持久化索引。
// MARK: [SR-02] 向量数据库 (Vector DB) 存储与 RAG 链路闭环
// MARK: [PR-02] 混合检索 (RAG) 链路耗时优化
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 向量索引处理器
final class VectorIndexer {

    private let embeddingManager: EmbeddingManager

    init(embeddingManager: EmbeddingManager) {
        self.embeddingManager = embeddingManager
    }

    /// 执行多维向量索引
    /// - Parameters:
    ///   - pageID: 关联的页面 ID
    ///   - chunks: 待处理的 PageChunk 列表
    func index(pageID: UUID, chunks: [PageChunk]) async {
        guard !chunks.isEmpty else { return }
        await embeddingManager.indexChunks(pageID: pageID, chunks: chunks)
    }
}
