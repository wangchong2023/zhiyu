//
//  VectorIndexer.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：属于 VectorDB 模块，提供相关的结构体或工具支撑。
//
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
