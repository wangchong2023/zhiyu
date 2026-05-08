// VectorIndexer.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了向量索引处理器（VectorIndexer），负责将分块后的文本转化为向量并入库。
// 作为 RAG 流程中的最后一个核心环节，它封装了对 EmbeddingManager 的调用，并管理向量库的更新逻辑。
// 核心职责：
// 1. 批量向量化：接收文本块列表，调用本地/远程 Embedding 模型生成向量。
// 2. 索引维护：在向量数据库中同步更新或创建对应的索引节点。
// 3. 性能优化：支持后台并发处理，避免阻塞主线程。
// 版本: 1.0
// 修改记录:
//   - 2026-05-06: 初始创建，实现 RAG 流程的模块化解耦
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
