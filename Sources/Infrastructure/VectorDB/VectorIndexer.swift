//
//  VectorIndexer.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：向量数据库：嵌入管理、向量索引、相似度搜索。
//
import Foundation

/// 向量索引处理器
final class VectorIndexer {

    private let embeddingProvider: any EmbeddingProvider

    init(embeddingProvider: any EmbeddingProvider) {
        self.embeddingProvider = embeddingProvider
    }

    /// 执行多维向量索引
    /// - Parameters:
    ///   - pageID: 关联的页面 ID
    ///   - chunks: 待处理的 PageChunk 列表
    func index(pageID: UUID, chunks: [PageChunk]) async {
        guard !chunks.isEmpty else { return }
        await embeddingProvider.indexChunks(pageID: pageID, chunks: chunks)
    }
}

