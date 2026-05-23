//
//  KnowledgeIngestPipeline.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：属于 RAG 模块，提供相关的结构体或工具支撑。
//
import Foundation

/// 知识摄入管道 - RAG 流程的统一入口
actor KnowledgeIngestPipeline {

    /// 共享实例
    static let shared = KnowledgeIngestPipeline()

    private let enricher = AIContentEnricher.shared
    private let chunker = TextChunkerProcessor()

    private init() {}

    /// 执行完整的 Advanced RAG 摄入流程
    /// 包含：语义增强 -> 全局摘要 -> 父子块切分 -> 反向提问 (Q&A) -> 向量化
    func process(
        content: String,
        pageID: UUID,
        llm: (any LLMServiceProtocol)?,
        embeddingManager: EmbeddingManager
    ) async -> String {
        // 阶段 1: 语义增强 (AI Content Enrichment)
        let enrichedContent: String
        if let llm = llm {
            enrichedContent = await enricher.enrich(content, llm: llm)
        } else {
            enrichedContent = content
        }

        // 使用并发任务组处理后续阶段
        let allEnrichedChunks = await withTaskGroup(of: [PageChunk].self) { group in

            // 任务 A: 全局摘要索引 (Summary Indexing)
            if let llm = llm {
                group.addTask {
                    let summaryPrompt = PromptRegistry.Ingest.summary(content: String(enrichedContent.prefix(2000)))
                    if let summary = try? await llm.generate(prompt: summaryPrompt, systemPrompt: L10n.AI.Prompt.ingestManagementAssistant) {
                        return [PageChunk(
                            id: "sum_\(pageID.uuidString)",
                            pageID: pageID,
                            parentID: nil,
                            chunkType: "summary",
                            content: summary,
                            index: 0,
                            startIndex: 0,
                            embedding: nil,
                            createdAt: Date(),
                            updatedAt: Date()
                        )]
                    }
                    return []
                }
            }

            // 阶段 3: 层级分块与反向提问 (并行处理每个父块)
            let parentConfig = TextChunkerProcessor.Config(chunkSize: 1000, chunkOverlap: 200, separators: TextChunkerProcessor.default.separators)
            let parentChunks = self.chunker.split(text: enrichedContent, config: parentConfig)

            for (pIndex, pChunk) in parentChunks.enumerated() {
                group.addTask {
                    await self.processParentChunk(pChunk, pIndex: pIndex, pageID: pageID, llm: llm)
                }
            }

            // 合并所有结果
            var finalChunks: [PageChunk] = []
            for await batch in group {
                finalChunks.append(contentsOf: batch)
            }
            return finalChunks
        }

        // 阶段 5: 向量索引 (Vector Indexing)
        let indexer = VectorIndexer(embeddingManager: embeddingManager)
        await indexer.index(pageID: pageID, chunks: allEnrichedChunks)

        return enrichedContent
    }

    // MARK: - Private Helpers

    /// 处理单个父分块，生成子分块与反向 Q&A 块
    private func processParentChunk(
        _ pChunk: TextChunkerProcessor.Chunk, 
        pIndex: Int, 
        pageID: UUID, 
        llm: (any LLMServiceProtocol)?
    ) async -> [PageChunk] {
        var chunkBatch: [PageChunk] = []
        let parentChunkID = "p_\(pageID.uuidString)_\(pIndex)"
        let childConfig = TextChunkerProcessor.Config(chunkSize: 300, chunkOverlap: 50, separators: TextChunkerProcessor.default.separators)

        // 1. 保存父块
        let parentRecord = PageChunk(
            id: parentChunkID,
            pageID: pageID,
            parentID: nil,
            chunkType: "regular",
            content: pChunk.text,
            anchorPath: pChunk.anchorPath, // 注入语义路径
            index: pIndex,
            startIndex: pChunk.startIndex,
            embedding: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        chunkBatch.append(parentRecord)

        // 2. 生成子块
        let children = self.chunker.split(text: pChunk.text, config: childConfig)
        for (cIndex, cChunk) in children.enumerated() {
            let childRecord = PageChunk(
                id: "\(parentChunkID)_c\(cIndex)",
                pageID: pageID,
                parentID: parentChunkID,
                chunkType: "child",
                content: cChunk.text,
                anchorPath: pChunk.anchorPath, // 子块继承父块的语义路径
                index: cIndex,
                startIndex: cChunk.startIndex,
                embedding: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            chunkBatch.append(childRecord)
        }

        // 3. 反向提问 (Reverse Q&A)
        if let llm = llm {
            let qaPrompt = PromptRegistry.Ingest.reverseQA(content: pChunk.text)
            if let qaResponse = try? await llm.generate(prompt: qaPrompt, systemPrompt: L10n.AI.Prompt.ingestDiscoveryAssistant) {
                let questions = qaResponse.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                for (qIndex, question) in questions.prefix(3).enumerated() {
                    let qaRecord = PageChunk(
                        id: "qa_\(parentChunkID)_\(qIndex)",
                        pageID: pageID,
                        parentID: parentChunkID,
                        chunkType: "qa_pair",
                        content: question,
                        index: qIndex,
                        startIndex: pChunk.startIndex,
                        embedding: nil,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    chunkBatch.append(qaRecord)
                }
            }
        }

        return chunkBatch
    }
}
