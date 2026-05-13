// LLMRetrievalService.swift
//
// 作者: Wang Chong
// 功能说明: LLM 检索增强服务，处理查询改写、意图扩展及搜索结果重排 (Rerank)。
// MARK: [SR-02] 混合检索 (RAG) 链路优化与语义重排
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// LLM 检索增强服务
/// 负责对原始查询进行优化，并对初步召回的结果执行语义精排。
final class LLMRetrievalService: Sendable {
    private let client: any LLMClientProtocol
    private let model: String
    private let contextBuilder: LLMContextBuilder

    init(client: any LLMClientProtocol, model: String, contextBuilder: LLMContextBuilder) {
        self.client = client
        self.model = model
        self.contextBuilder = contextBuilder
    }

    // MARK: - 查询优化 (Query Optimization)

    /// 将原始自然语言问题改写为更适合检索的格式
    func rewriteQuery(_ query: String) async -> String {
        let prompt = contextBuilder.buildRewritePrompt(query: query)
        let body: [String: Any] = [
            "model": model,
            "messages": [["role": "user", "content": prompt]],
            "temperature": 0.3
        ]
        
        do {
            let response = try await client.sendRequest(body: body)
            return LLMResponseProcessor.extractContent(from: response) ?? query
        } catch {
            return query
        }
    }

    /// 对查询进行意图扩展，生成多个变体以提升召回率
    func expandQuery(_ query: String) async -> [String] {
        let prompt = PromptService.shared.queryExpansionPrompt + "\n\nOriginal Query: \(query)"
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "Return JSON array of strings only."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.5
        ]
        
        do {
            let response = try await client.sendRequest(body: body)
            let content = LLMResponseProcessor.extractContent(from: response) ?? ""
            let variations = LLMResponseProcessor.parseJSONArray(content)
            return variations.isEmpty ? [query] : variations
        } catch {
            return [query]
        }
    }

    // MARK: - 重排 (Rerank)

    /// 对候选页面列表执行语义重排
    func rerank(query: String, candidates: [KnowledgePage]) async throws -> [KnowledgePage] {
        guard !candidates.isEmpty else { return candidates }

        let titles = candidates.map { "\($0.title) (ID: \($0.id))" }.joined(separator: "\n")
        let prompt = PromptService.shared.rerankPrompt + "\n\nQuery: \(query)\n\nCandidates:\n\(titles)"
        
        let body: [String: Any] = [
            "model": model,
            "messages": [["role": "user", "content": prompt]],
            "temperature": 0.2
        ]

        let response = try await client.sendRequest(body: body)
        let content = LLMResponseProcessor.extractContent(from: response) ?? ""
        let rankedIDs = LLMResponseProcessor.parseJSONArray(content)

        // 根据 LLM 返回的优先级顺序重新排序
        var result = candidates
        result.sort { a, b in
            let idxA = rankedIDs.firstIndex(of: a.id.uuidString) ?? 999
            let idxB = rankedIDs.firstIndex(of: b.id.uuidString) ?? 999
            return idxA < idxB
        }
        return result
    }

    /// 对文本分块执行 Rerank
    func rerankChunks(query: String, chunks: [PageChunk]) async -> [PageChunk] {
        guard !chunks.isEmpty else { return chunks }

        let candidates = chunks.prefix(10)
        let context = candidates.enumerated().map { "[\($0)] \($1.content)" }.joined(separator: "\n\n")

        let prompt = """
        查询: \(query)

        候选文本块:
        \(context)

        请根据相关性对上述块进行排序。仅返回排序后的索引数组，例如 [2, 0, 1]。
        """

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "你是一个精准的 Rerank 引擎。仅返回 JSON 数组。"],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.1
        ]

        do {
            let response = try await client.sendRequest(body: body)
            let content = LLMResponseProcessor.extractContent(from: response) ?? ""
            let rankedIndices = LLMResponseProcessor.parseJSONArray(content).compactMap { Int($0) }

            var result: [PageChunk] = []
            for index in rankedIndices where index < candidates.count {
                result.append(candidates[index])
            }

            // 补全未被排序选中的块
            let resultIDs = Set(result.map { $0.id })
            for chunk in chunks where !resultIDs.contains(chunk.id) {
                result.append(chunk)
            }

            return result
        } catch {
            return chunks
        }
    }

    // MARK: - 辅助文档生成

    /// 生成假设性回答文档 (HyDE 策略)
    func generateHypotheticalDocument(query: String) async -> String {
        let prompt = "请针对以下问题写一个简短但专业的假设性回答（不要包含前导词），这将用于向量检索优化：\n\n问题：\(query)"
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "你是一个知识库助手，擅长生成精准的学术或技术性回答。"],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]
        
        do {
            let response = try await client.sendRequest(body: body)
            return LLMResponseProcessor.extractContent(from: response) ?? query
        } catch {
            return query
        }
    }
}
