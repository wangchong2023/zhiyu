// LLMChatService.swift
//
// 作者: Wang Chong
// 功能说明: LLM 对话专向服务，处理对话请求构建、多轮历史管理及流式解析。
// MARK: [SR-02] 核心对话链路与 RAG 上下文集成
// 版本: 1.2
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// LLM 对话服务
/// 负责将系统提示词、用户查询及历史记录转换为 API 请求，并解析响应。
final class LLMChatService: Sendable {
    private let client: any LLMClientProtocol
    private let model: String

    init(client: any LLMClientProtocol, model: String) {
        self.client = client
        self.model = model
    }

    // MARK: - 请求构造

    /// 构建标准对话消息数组
    private func buildChatMessages(systemPrompt: String, query: String, history: [ChatMessage]) -> [[String: Any]] {
        let fullSystemPrompt = systemPrompt + PromptService.shared.languageInstruction
        var messages: [[String: Any]] = [["role": "system", "content": fullSystemPrompt]]
        
        // 注入历史记录
        for msg in history {
            messages.append(["role": msg.role.rawValue, "content": msg.content])
        }
        
        // 注入当前查询
        messages.append(["role": "user", "content": query])
        return messages
    }

    /// 构造非流式请求体
    private func makeChatRequestBody(systemPrompt: String, query: String, history: [ChatMessage]) -> [String: Any] {
        [
            "model": model,
            "messages": buildChatMessages(systemPrompt: systemPrompt, query: query, history: history),
            "temperature": AppConfig.AI.defaultTemperature,
            "max_tokens": 2000
        ]
    }

    /// 构造流式请求体
    private func makeStreamingRequestBody(systemPrompt: String, query: String, history: [ChatMessage]) -> [String: Any] {
        var body = makeChatRequestBody(systemPrompt: systemPrompt, query: query, history: history)
        body["stream"] = true
        return body
    }

    // MARK: - 对话执行

    /// 执行单次非流式对话
    func chat(systemPrompt: String, query: String, history: [ChatMessage]) async throws -> String {
        let requestBody = makeChatRequestBody(systemPrompt: systemPrompt, query: query, history: history)
        let response = try await client.sendRequest(body: requestBody)
        
        guard let content = LLMResponseProcessor.extractContent(from: response) else {
            throw LLMError.invalidResponse
        }
        return content
    }

    private struct SendableBody: @unchecked Sendable {
        let dict: [String: Any]
    }

    /// 执行流式对话，返回异步抛出流
    func streamChat(systemPrompt: String, query: String, history: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        let requestBody = makeStreamingRequestBody(systemPrompt: systemPrompt, query: query, history: history)
        let localClient = self.client
        
        let safeBody = SendableBody(dict: requestBody)
        let (stream, continuation) = AsyncThrowingStream<String, Error>.makeStream()
        
        let task = Task {
            do {
                let bytes = try await localClient.sendStreamingRequest(body: safeBody.dict)
                for try await chunk in SSEParser.parse(bytes: bytes) {
                    if Task.isCancelled { break }
                    continuation.yield(chunk)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
        
        continuation.onTermination = { @Sendable _ in
            task.cancel()
        }
        
        return stream
    }
}
