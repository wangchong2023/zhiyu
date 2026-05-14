// LLMIngestService.swift
//
// 作者: Wang Chong
// 功能说明: LLM 智能摄入服务，处理原始内容的结构化提取、摘要生成及标签建议。
// MARK: [SR-02] 智能编译 (Smart Ingest) 链路与知识提取
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// LLM 智能摄入服务
/// 负责对新摄入的原始文本进行语义分析，并提取结构化知识元数据。
final class LLMIngestService: Sendable {
    private let client: any LLMClientProtocol
    private let model: String
    private let contextBuilder: LLMContextBuilder

    init(client: any LLMClientProtocol, model: String, contextBuilder: LLMContextBuilder) {
        self.client = client
        self.model = model
        self.contextBuilder = contextBuilder
    }

    // MARK: - 智能摄入 (Smart Ingest)

    /// 对原始内容进行智能编译，提取摘要、标签、关联建议等
    func smartIngest(title: String, rawContent: String, pages: [KnowledgePage]) async throws -> SmartIngestResult {
        let prompt = contextBuilder.buildIngestPrompt(title: title, rawContent: rawContent, pages: pages)
        let body: [String: Any] = [
            "model": model,
            "messages": [["role": "user", "content": prompt]],
            "temperature": 0.4
        ]

        let response = try await client.sendRequest(body: body)
        let content = LLMResponseProcessor.extractContent(from: response) ?? ""

        if let result = LLMResponseProcessor.parseSmartIngest(content) {
            return result
        }
        throw LLMError.invalidResponse
    }
}
