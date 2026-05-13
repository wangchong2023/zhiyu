// EmbeddingManager.swift
//
// 作者: Wang Chong
// 功能说明: 向量管理中心，负责向量的异步计算、持久化同步以及基于 Accelerate 框架的高性能检索。
// 版本: 1.1
// 修改记录:
//   - 2026-05-05: 升级文档规范，优化线程安全访问逻辑
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import NaturalLanguage
import Accelerate

/// 向量管理中心
/// 负责向量的异步计算、持久化同步以及基于 Accelerate 框架的高性能检索。
actor EmbeddingManager {
    private let repository: KnowledgePageStore
    private let embeddingModel: NLEmbedding?
    private let modelName = AppConstants.AI.defaultEmbeddingModel

    // 内存缓存
    private var vectorCache: [UUID: [Float]] = [:] // 页面级缓存
    private var chunkVectorCache: [String: [Float]] = [:] // 分块级向量缓存
    private var chunkMetadata: [String: PageChunk] = [:] // 分块元数据缓存

    /// 获取所有页面嵌入向量
    var allEmbeddings: [UUID: [Float]] {
        return vectorCache
    }

    init(repository: KnowledgePageStore) {
        self.repository = repository
        self.embeddingModel = NLEmbedding.sentenceEmbedding(for: .simplifiedChinese) ?? NLEmbedding.sentenceEmbedding(for: .english)
    }

    /// 异步加载初始缓存
    func loadInitialCache() {
        // 1. 加载页面级向量
        if let embeddings = try? repository.fetchAllEmbeddings() {
            vectorCache = embeddings
        }

        // 2. 加载分块级向量
        if let chunks = try? repository.fetchAllChunksWithEmbeddings() {
            for chunk in chunks {
                if let data = chunk.embedding {
                    let count = data.count / MemoryLayout<Float>.size
                    let vector = data.withUnsafeBytes { pointer in
                        Array(UnsafeBufferPointer(start: pointer.baseAddress?.assumingMemoryBound(to: Float.self), count: count))
                    }
                    chunkVectorCache[chunk.id] = vector
                    chunkMetadata[chunk.id] = chunk
                }
            }
        }
    }

    // MARK: - 异步同步逻辑

    /// 同步所有待更新的页面向量
    func syncEmbeddings(pages: [KnowledgePage]) async {
        guard let model = self.embeddingModel else { return }

        for page in pages {
            if vectorCache[page.id] == nil {
                let text = "\(page.title)\n\(page.content.prefix(1000))"
                if let vector = model.vector(for: text) {
                    let floatVector = vector.map { Float($0) }
                    try? self.repository.saveEmbedding(id: page.id, vector: floatVector, modelName: self.modelName)
                    self.vectorCache[page.id] = floatVector
                }
            }
        }
    }

    /// 当单个页面更新时触发
    func updateEmbedding(for page: KnowledgePage) async {
        guard let model = self.embeddingModel else { return }
        let text = "\(page.title)\n\(page.content.prefix(1000))"

        if let vector = model.vector(for: text) {
            let floatVector = vector.map { Float($0) }
            try? self.repository.saveEmbedding(id: page.id, vector: floatVector, modelName: self.modelName)
            self.vectorCache[page.id] = floatVector
        }
    }

    /// 批量索引页面分块（支持异步向量化与持久化）
    func indexChunks(pageID: UUID, chunks: [PageChunk]) async {
        guard let model = self.embeddingModel else { return }

        var processedChunks: [PageChunk] = []
        for chunk in chunks {
            var updatedChunk = chunk
            // 为分块内容生成向量
            if let vector = model.vector(for: chunk.content) {
                let floatVector = vector.map { Float($0) }
                updatedChunk.embedding = Data(bytes: floatVector, count: floatVector.count * MemoryLayout<Float>.size)
            }
            processedChunks.append(updatedChunk)
        }

        // 批量持久化到数据库
        try? self.repository.saveChunks(pageID: pageID, chunks: processedChunks)

        // 更新内存缓存
        for chunk in processedChunks {
            if let data = chunk.embedding {
                let count = data.count / MemoryLayout<Float>.size
                let vector = data.withUnsafeBytes { pointer in
                    Array(UnsafeBufferPointer(start: pointer.baseAddress?.assumingMemoryBound(to: Float.self), count: count))
                }
                chunkVectorCache[chunk.id] = vector
                chunkMetadata[chunk.id] = chunk
            }
        }
    }

    // MARK: - 高性能检索 (Accelerate 加速)

    /// 为一组分块文本生成向量
    func vectorizeChunks(chunks: [String]) -> [[Float]] {
        guard let model = embeddingModel else { return [] }
        return chunks.map { text in
            let v = model.vector(for: text)
            return v?.map { Float($0) } ?? [Float](repeating: 0, count: 512)
        }
    }

    /// 使用 Accelerate 框架进行向量余弦相似度检索
    func search(query: String, topK: Int = AppConfig.AI.topKResults) async -> [(id: UUID, score: Float)] {
        guard let qv = vectorize(text: query) else { return [] }

        let keys = Array(vectorCache.keys)
        let cache = vectorCache
        let results = await performParallelSearch(queryVector: qv, keys: keys, cache: cache)

        return results.filter { $0.1 > AppConfig.AI.similarityThreshold }
            .sorted { $0.1 > $1.1 }
            .prefix(topK)
            .map { $0 }
    }

    /// 多路召回搜索 (Multi-Query + RRF 融合)
    func multiQuerySearch(query: String, topK: Int = AppConfig.AI.topKResults) async -> [(chunk: PageChunk, score: Float)] {
        // 1. 查询扩展
        let llmService = ServiceContainer.shared.resolve(LLMService.self)
        let variations = await llmService.expandQuery(query)
        let allQueries = [query] + variations

        // 2. 并行获取所有查询的检索结果
        var allResults: [[(id: String, score: Float)]] = []
        for q in allQueries {
            if let qv = vectorize(text: q) {
                let results = await searchChunks(queryVector: qv, topK: 50)
                allResults.append(results)
            }
        }

        // 3. RRF 融合
        let fusedResults = computeRRF(allResults)

        // 4. 映射回分块数据
        return fusedResults.prefix(topK).compactMap { id, score in
            guard let chunk = chunkMetadata[id] else { return nil }
            return (chunk, score)
        }
    }

    /// HyDE (Hypothetical Document Embeddings) 搜索
    func hydeSearch(query: String, topK: Int = AppConfig.AI.topKResults) async -> [(chunk: PageChunk, score: Float)] {
        let llmService = ServiceContainer.shared.resolve(LLMService.self)

        // 1. 生成假设性回答
        let hypoDoc = await llmService.generateHypotheticalDocument(query: query)

        // 2. 对假设性回答进行向量检索
        guard let qv = vectorize(text: hypoDoc) else { return [] }
        let results = await searchChunks(queryVector: qv, topK: topK)

        return results.compactMap { id, score -> (PageChunk, Float)? in
            guard let chunk = chunkMetadata[id] else { return nil }
            return (chunk, score)
        }
    }

    /// Self-Reflection (Rerank) 搜索
    func selfReflectionSearch(query: String, candidates: [(chunk: PageChunk, score: Float)]) async -> [(chunk: PageChunk, score: Float)] {
        let llmService = ServiceContainer.shared.resolve(LLMService.self)

        // 使用 LLM 进行语义重排序
        let rankedChunks = await llmService.rerankChunks(query: query, chunks: candidates.map { $0.chunk })

        // 重新分配分数（根据重排后的顺序）
        return rankedChunks.enumerated().map { index, chunk in
            let score = 1.0 - (Float(index) / Float(rankedChunks.count))
            return (chunk, score)
        }
    }

    /// 综合高级检索策略
    func advancedSearch(query: String, topK: Int = AppConfig.AI.topKResults) async -> [(chunk: PageChunk, score: Float)] {
        // 1. 多路召回获取候选集
        let mqResults = await multiQuerySearch(query: query, topK: 30)

        // 2. HyDE 获取候选集
        let hydeResults = await hydeSearch(query: query, topK: 10)

        // 3. 结果合并与去重
        var combinedMap: [String: (chunk: PageChunk, score: Float)] = [:]
        for res in (mqResults + hydeResults) {
            if let existing = combinedMap[res.chunk.id] {
                combinedMap[res.chunk.id] = (res.chunk, max(existing.score, res.score))
            } else {
                combinedMap[res.chunk.id] = res
            }
        }

        let candidates = Array(combinedMap.values).sorted { $0.score > $1.score }

        // 4. Self-Reflection 重排序
        return await selfReflectionSearch(query: query, candidates: candidates.prefix(15).map { $0 })
            .prefix(topK)
            .map { $0 }
    }

    // MARK: - 内部检索核心

    private func vectorize(text: String) -> [Float]? {
        guard let model = embeddingModel else { return nil }
        let vector = model.vector(for: text)
        return vector?.map { Float($0) }
    }

    private func searchChunks(queryVector: [Float], topK: Int) async -> [(id: String, score: Float)] {
        let keys = Array(chunkVectorCache.keys)
        let cache = chunkVectorCache
        let results = await performParallelSearch(queryVector: queryVector, keys: keys, cache: cache)
        return results.sorted { $0.1 > $1.1 }.prefix(topK).map { $0 }
    }

    private func performParallelSearch<K: Sendable>(queryVector: [Float], keys: [K], cache: [K: [Float]]) async -> [(K, Float)] {
        let keysCount = keys.count
        guard keysCount > 0 else { return [] }

        // 将计算逻辑移出 actor 以允许并发执行
        return await Task.detached(priority: .userInitiated) {
            let rawResults = UnsafeMutablePointer<(K, Float)>.allocate(capacity: keysCount)
            let wrappedResults = EmbeddingPointerWrapper(ptr: rawResults)

            DispatchQueue.concurrentPerform(iterations: keysCount) { index in
                let key = keys[index]
                if let vector = cache[key] {
                    let score = Self.cosineSimilarity(vector, queryVector)
                    wrappedResults.ptr[index] = (key, score)
                }
            }

            var list: [(K, Float)] = []
            for i in 0..<keysCount {
                list.append(rawResults[i])
            }
            rawResults.deallocate()
            return list
        }.value
    }

    /// RRF (Reciprocal Rank Fusion) 融合算法
    /// score = sum(1 / (k + rank))
    private func computeRRF(_ allResults: [[(id: String, score: Float)]], k: Float = 60.0) -> [(id: String, score: Float)] {
        var scores: [String: Float] = [:]

        for results in allResults {
            for (rank, res) in results.enumerated() {
                let rrfScore = 1.0 / (k + Float(rank + 1))
                scores[res.id, default: 0] += rrfScore
            }
        }

        return scores.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }

    /// 计算两个向量的余弦相似度
    static func cosineSimilarity(_ v1: [Float], _ v2: [Float]) -> Float {
        guard v1.count == v2.count else { return 0 }

        var dotProduct: Float = 0
        vDSP_dotpr(v1, 1, v2, 1, &dotProduct, vDSP_Length(v1.count))

        var v1SumSq: Float = 0
        vDSP_svesq(v1, 1, &v1SumSq, vDSP_Length(v1.count))

        var v2SumSq: Float = 0
        vDSP_svesq(v2, 1, &v2SumSq, vDSP_Length(v2.count))

        let denominator = sqrt(v1SumSq) * sqrt(v2SumSq)
        guard denominator > 0 else { return 0 }
        return dotProduct / denominator
    }
}

// MARK: - Helper Types

struct EmbeddingPointerWrapper<T>: @unchecked Sendable {
    let ptr: UnsafeMutablePointer<(T, Float)>
}
