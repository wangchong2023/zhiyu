//
//  ChatRunner.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/24.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：提供专属的大语言模型单轮/多轮对话与流式文本推理业务能力。
//

import Foundation
import Combine

/// 大语言模型对话专属运行器 (ChatRunner)
/// 实现 LLMChatServiceProtocol，负责多轮对话、流式推理以及通用内容生成。
@MainActor
final class ChatRunner: LLMChatServiceProtocol, @unchecked Sendable {
    
    // MARK: - 依赖注入
    
    @ObservationIgnored @Inject private var configManager: LLMConfigManager
    @ObservationIgnored @Inject private var analytics: AIAnalyticsService
    
    // MARK: - 内部属性
    
    /// 上下文构建器
    private let contextBuilder = LLMContextBuilder()
    
    /// 核心对话子服务
    private var chatService: LLMChatService?
    
    var isEnabled: Bool {
        configManager.isEnabled
    }
    
    // MARK: - 初始化
    
    init() {
        updateSubServices()
        
        // 绑定配置中心刷新事件
        configManager.setRefreshHandler { [weak self] in
            self?.updateSubServices()
        }
    }
    
    private func updateSubServices() {
        let client = LLMClient(baseURL: configManager.baseURL, apiKey: configManager.apiKey)
        self.chatService = LLMChatService(client: client, model: configManager.model)
    }
    
    // MARK: - LLMChatServiceProtocol 契约方法
    
    /// 通用单次一问一答文本推理生成接口
    func generate(prompt: String, systemPrompt: String) async throws -> String {
        guard configManager.isEnabled, !configManager.apiKey.isEmpty else { throw LLMError.notConfigured }
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

        // 审计调用时长与 Token 开销
        analytics.recordUsage(model: configManager.model, response: response, latency: latency)

        guard let content = LLMUtils.extractContent(from: response) else {
            throw LLMError.invalidResponse
        }
        return content
    }
    
    /// 执行核心 RAG (检索增强生成) 问答
    func chat(query: String, history: [ChatMessageDTO], pages: [any KnowledgePageRepresentable]) async throws -> ChatMessageDTO {
        guard configManager.isEnabled, let chatService = self.chatService else { throw LLMError.notConfigured }
        let sanitizedQuery = PromptSanitizer.shared.sanitize(query)

        // 1. 在 UI 层启动任务中心异步进度条
        let taskID = TaskCenter.shared.addTask(type: .ai, name: "AI Chat", target: sanitizedQuery)
        TaskCenter.shared.updateTask(taskID, status: .running(progress: 0.2, stage: .embedding))
        
        // 2. 检索向量库及 FTS5 混合语义，构建保护双链的语义上下文
        let (context, sources) = await contextBuilder.buildRelevantContext(query: sanitizedQuery)
        SourceStore.shared.updateSources(sources)
        
        // 3. 执行语义重排，精简检索召回的冗余分块
        TaskCenter.shared.updateTask(taskID, status: .running(progress: 0.5, stage: .retrieval))
        
        // 获取 Reranker 服务以进行语义重排
        let reranker = ServiceContainer.shared.resolve((any LLMRetrievalServiceProtocol).self)
        let rankedPages = (try? await reranker.rerank(query: sanitizedQuery, candidates: pages)) ?? pages
        
        // 🛡️ 安全加固：对召回上下文执行 DLP 图像过滤，并注入金沙箱隔离包装
        let sandboxedContext = PromptSanitizer.shared.wrapInSandbox(context)
        let systemPrompt = contextBuilder.buildSystemPrompt(pages: rankedPages) + "\n\n" + sandboxedContext
  
        // 4. 调用大模型，记录耗时指标并触发 RAG 自评估
        TaskCenter.shared.updateTask(taskID, status: .running(progress: 0.8, stage: .synthesis))
        let startTime = Date()
        let response = try await chatService.chat(systemPrompt: systemPrompt, query: sanitizedQuery, history: history)
        let latency = Int(Date().timeIntervalSince(startTime) * 1000)
 
        analytics.recordRAGMetrics(query: sanitizedQuery, response: response, context: context, systemPrompt: systemPrompt, modelName: configManager.model, latency: latency)
        
        TaskCenter.shared.completeTask(id: taskID)
        return ChatMessageDTO(role: .assistant, content: response)
    }
    
    /// 执行基于 AsyncStream 的高性能流式打字机问答
    func chatStream(query: String, history: [ChatMessageDTO], pages: [any KnowledgePageRepresentable]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task { @MainActor in
                guard configManager.isEnabled, let chatService = self.chatService else {
                    continuation.finish(throwing: LLMError.notConfigured)
                    return
                }
 
                let sanitizedQuery = PromptSanitizer.shared.sanitize(query)
                let taskID = TaskCenter.shared.addTask(type: .ai, name: "AI Chat Stream", target: sanitizedQuery)
                
                defer {
                    TaskCenter.shared.completeTask(id: taskID)
                }
 
                do {
                    // 1. 构建混合上下文，更新引用源
                    let (context, sources) = await contextBuilder.buildRelevantContext(query: sanitizedQuery)
                    SourceStore.shared.updateSources(sources)
                    
                    // 2. 排序候选文档
                    let reranker = ServiceContainer.shared.resolve((any LLMRetrievalServiceProtocol).self)
                    let rankedPages = (try? await reranker.rerank(query: sanitizedQuery, candidates: pages)) ?? pages
                    
                    // 🛡️ 安全加固：对召回上下文执行 DLP 图像过滤，并注入金沙箱隔离包装
                    let sandboxedContext = PromptSanitizer.shared.wrapInSandbox(context)
                    let systemPrompt = contextBuilder.buildSystemPrompt(pages: rankedPages) + "\n\n" + sandboxedContext
 
                    var fullResponse = ""
                    // 3. 消费打字机流片段
                    for try await chunk in chatService.streamChat(systemPrompt: systemPrompt, query: sanitizedQuery, history: history) {
                        fullResponse += chunk
                        continuation.yield(chunk)
                    }
 
                    // 4. 异步归档 RAG 精准度元数据以做治理评估
                    analytics.recordRAGMetrics(query: sanitizedQuery, response: fullResponse, context: context, systemPrompt: systemPrompt, modelName: configManager.model, latency: 0)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
