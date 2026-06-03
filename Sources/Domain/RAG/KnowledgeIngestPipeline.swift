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
        embeddingProvider: any EmbeddingProvider
    ) async throws -> String {
        
        // 0. 提取阶段
        await updateProgress(stage: .extraction, progress: 0.05, log: L10n.Ingest.Status.starting)

        // 1. 语义增强阶段
        let enrichedContent = try await performEnrichment(content: content, llm: llm)
        
        // 2. 切分及反向提问等任务 (并发)
        let allEnrichedChunks = try await performConcurrentProcessing(content: enrichedContent, pageID: pageID, llm: llm)
        
        // 3. 向量索引阶段
        try await performEmbedding(chunks: allEnrichedChunks, pageID: pageID, embeddingProvider: embeddingProvider)
        
        return enrichedContent
    }

    // MARK: - Pipeline Steps

    private func performEnrichment(content: String, llm: (any LLMServiceProtocol)?) async throws -> String {
        guard let llm = llm else { return content }
        
        try Task.checkCancellation()
        await updateProgress(stage: .enrichment, progress: 0.15, log: L10n.Ingest.Status.aiEnriching)
        return await enricher.enrich(content, llm: llm)
    }

    private func performConcurrentProcessing(content: String, pageID: UUID, llm: (any LLMServiceProtocol)?) async throws -> [PageChunk] {
        try Task.checkCancellation()
        
        return await withTaskGroup(of: [PageChunk].self) { group in
            
            // 摘要任务
            if let llm = llm {
                group.addTask {
                    return await self.generateSummaryChunk(content: content, pageID: pageID, llm: llm)
                }
            }
            
            // 分块与 Q&A
            await self.updateProgress(stage: .chunking, progress: 0.40, log: L10n.Ingest.Status.chunking)
            
            let parentConfig = TextChunkerProcessor.Config(chunkSize: 1000, chunkOverlap: 200, separators: TextChunkerProcessor.default.separators)
            let parentChunks = self.chunker.split(text: content, config: parentConfig)
            
            for (pIndex, pChunk) in parentChunks.enumerated() {
                group.addTask {
                    do {
                        try Task.checkCancellation()
                        await TaskCenter.shared.addIngestSubLog(L10n.Ingest.Status.processingChunk)
                        return try await self.processParentChunk(pChunk, pIndex: pIndex, pageID: pageID, llm: llm)
                    } catch {
                        return []
                    }
                }
            }
            
            var finalChunks: [PageChunk] = []
            for await batch in group {
                finalChunks.append(contentsOf: batch)
            }
            return finalChunks
        }
    }

    private func generateSummaryChunk(content: String, pageID: UUID, llm: any LLMServiceProtocol) async -> [PageChunk] {
        do {
            try Task.checkCancellation()
            await TaskCenter.shared.addIngestSubLog(L10n.Ingest.Status.generatingSummary)
            let summaryPrompt = PromptRegistry.Ingest.summary(content: String(content.prefix(2000)))
            if let summary = try? await llm.generate(prompt: summaryPrompt, systemPrompt: L10n.AI.Prompt.ingestManagementAssistant) {
                try Task.checkCancellation()
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
        } catch {}
        return []
    }

    private func performEmbedding(chunks: [PageChunk], pageID: UUID, embeddingProvider: any EmbeddingProvider) async throws {
        try Task.checkCancellation()
        await updateProgress(stage: .embedding, progress: 0.75, log: L10n.Ingest.Status.vectorizing)
        
        let indexer = VectorIndexer(embeddingProvider: embeddingProvider)
        await indexer.index(pageID: pageID, chunks: chunks)
        
        await updateProgress(stage: .embedding, progress: 1.0, log: L10n.Ingest.Status.completed)
    }

    // MARK: - Private Helpers

    private func updateProgress(stage: TaskStage, progress: Double, log: String) async {
        if let task = await TaskCenter.shared.tasks.first(where: { $0.type == .ingest }) {
            await TaskCenter.shared.updateTask(task.id, status: .running(progress: progress, stage: stage))
        }
        await TaskCenter.shared.addIngestSubLog(log)
    }

    /// 处理单个父分块，生成子分块与反向 Q&A 块
    private func processParentChunk(
        _ pChunk: TextChunkerProcessor.Chunk, 
        pIndex: Int, 
        pageID: UUID, 
        llm: (any LLMServiceProtocol)?
    ) async throws -> [PageChunk] {
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
            anchorPath: pChunk.anchorPath,
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
                anchorPath: pChunk.anchorPath,
                index: cIndex,
                startIndex: cChunk.startIndex,
                embedding: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            chunkBatch.append(childRecord)
        }

        // 3. 反向提问 (Reverse Q&A)
        if let llm = llm, !Task.isCancelled {
            let qaPrompt = PromptRegistry.Ingest.reverseQA(content: pChunk.text)
            if let qaResponse = try? await llm.generate(prompt: qaPrompt, systemPrompt: L10n.AI.Prompt.ingestDiscoveryAssistant), !Task.isCancelled {
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
