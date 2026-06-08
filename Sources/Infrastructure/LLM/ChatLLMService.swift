//
//  ChatLLMService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：实现 ChatLLM 模块的核心业务逻辑服务。
//
import Foundation
import Combine

/// 大模型对话与文本生成基础设施服务
/// 遵循并实现 `LLMChatServiceProtocol` 契约，支持响应式状态变化。
@MainActor
public final class ChatLLMService: NSObject, LLMChatServiceProtocol, @unchecked Sendable {
    /// 配置管理器，热重载 API 参数
    @ObservationIgnored @Inject private var configManager: LLMConfigManager
    
    /// AI 吞吐指标记录器
    @ObservationIgnored @Inject private var analytics: AIAnalyticsService
    
    /// 指示当前大模型服务是否使能开启
    public var isEnabled: Bool {
        configManager.isEnabled
    }
    
    /// 初始化对话服务
    public override init() {
        super.init()
    }
    
    /// 执行一问一答生成推理
    ///
    /// - Parameters:
    ///   - prompt: 提示词
    ///   - systemPrompt: 系统设定
    /// - Returns: 生成纯文本结果
    public func generate(prompt: String, systemPrompt: String, maxTokens: Int = BusinessConstants.AI.maxOutputTokens) async throws -> String {
        guard isEnabled, !configManager.apiKey.isEmpty else {
            throw LLMError.notConfigured
        }
        let client = LLMClient(baseURL: configManager.baseURL, apiKey: configManager.apiKey)
        let sanitizedPrompt = PromptSanitizer.shared.sanitize(prompt)
        let body: [String: Any] = [
            "model": configManager.model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": sanitizedPrompt]
            ],
            "temperature": AppConfig.AI.defaultTemperature
        ]
        
        let startTime = Date()
        let response = try await client.sendRequest(body: body)
        let latency = Int(Date().timeIntervalSince(startTime) * 1000)
        
        analytics.recordUsage(model: configManager.model, response: response, latency: latency)
        
        guard let content = LLMUtils.extractContent(from: response) else {
            throw LLMError.invalidResponse
        }
        return content
    }
    
    /// 执行核心会话对话
    ///
    /// - Parameters:
    ///   - query: 查询问句
    ///   - history: 历史纪录
    ///   - pages: 关联的知识背景页面
    /// - Returns: 会话响应数据
    public func chat(query: String, history: [ChatMessageDTO], pages: [any KnowledgePageRepresentable]) async throws -> ChatMessageDTO {
        guard isEnabled, !configManager.apiKey.isEmpty else {
            throw LLMError.notConfigured
        }
        let client = LLMClient(baseURL: configManager.baseURL, apiKey: configManager.apiKey)
        let chatService = LLMChatService(client: client, model: configManager.model)
        
        // 1. 对 query 进行消毒过滤
        let sanitizedQuery = PromptSanitizer.shared.sanitize(query)
        
        // 2. 组装系统提示词与相关页面上下文
        let contextBuilder = LLMContextBuilder()
        let (context, _) = await contextBuilder.buildRelevantContext(query: sanitizedQuery)
        let sandboxedContext = PromptSanitizer.shared.wrapInSandbox(context)
        let systemPrompt = contextBuilder.buildSystemPrompt(pages: pages) + "\n\n" + sandboxedContext
        
        // 3. 调用底层的 chatService 执行物理会话
        let content = try await chatService.chat(systemPrompt: systemPrompt, query: sanitizedQuery, history: history)
        
        return ChatMessageDTO(
            id: UUID(),
            role: .assistant,
            content: content,
            timestamp: Date(),
            relatedPageIDs: pages.map { $0.id }
        )
    }
    
    /// 执行流式会话对话，支持打字机吐字渲染
    ///
    /// - Parameters:
    ///   - query: 查询问句
    ///   - history: 历史纪录
    ///   - pages: 关联的知识背景页面
    /// - Returns: 流式字符串抛出流
    public func chatStream(query: String, history: [ChatMessageDTO], pages: [any KnowledgePageRepresentable]) -> AsyncThrowingStream<String, Error> {
        guard isEnabled, !configManager.apiKey.isEmpty else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: LLMError.notConfigured)
            }
        }
        
        let client = LLMClient(baseURL: configManager.baseURL, apiKey: configManager.apiKey)
        let chatService = LLMChatService(client: client, model: configManager.model)
        let sanitizedQuery = PromptSanitizer.shared.sanitize(query)
        
        let (stream, continuation) = AsyncThrowingStream<String, Error>.makeStream()
        
        // 1. 使用后台异步任务生成上下文与启动流式返回
        Task {
            do {
                let contextBuilder = LLMContextBuilder()
                let (context, _) = await contextBuilder.buildRelevantContext(query: sanitizedQuery)
                let sandboxedContext = PromptSanitizer.shared.wrapInSandbox(context)
                let systemPrompt = contextBuilder.buildSystemPrompt(pages: pages) + "\n\n" + sandboxedContext
                
                let sseStream = chatService.streamChat(systemPrompt: systemPrompt, query: sanitizedQuery, history: history)
                for try await chunk in sseStream {
                    continuation.yield(chunk)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
        
        return stream
    }
}
