// LLMService.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了知识管理系统的核心 AI 调度服务 (LLMService)，作为 AI 能力的统一入口与编排器。
// 核心职责：
// 1. 配置管理：同步并持久化 LLM 提供商、API Key 及模型参数。
// 2. 任务编排：将具体的 AI 任务分发至专项子服务（对齐、摄入、重构、检索）。
// 3. 监控与评估：记录调用时长、Token 消耗并触发 RAG 评估。
// MARK: [SR-02] 混合检索 (RAG) 链路调度与 AI 能力枢纽
// MARK: [PR-02] RAG 链路耗时优化目标 < 1.5s
// 版本: 1.4
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Combine

/// AI 大模型调度服务 (L1 服务层)
/// 负责协调各项 AI 子能力，并维护全局 AI 配置与运行状态。
@MainActor
final class LLMService: ObservableObject, LLMServiceProtocol, @unchecked Sendable {

    static let shared = LLMService()

    // MARK: - UI 状态属性 (与 LLMConfigStore 同步)
    @Published var provider: LLMProvider { 
        didSet { if oldValue != provider { configStore.provider = provider; updateSubServices() } } 
    }
    @Published var apiKey: String { 
        didSet { if oldValue != apiKey { configStore.apiKey = apiKey; updateSubServices() } } 
    }
    @Published var baseURL: String { 
        didSet { if oldValue != baseURL { configStore.baseURL = baseURL; updateSubServices() } } 
    }
    @Published var model: String { 
        didSet { if oldValue != model { configStore.model = model; updateSubServices() } } 
    }
    @Published var isEnabled: Bool { 
        didSet { if oldValue != isEnabled { configStore.isEnabled = isEnabled; updateSubServices() } } 
    }
    @Published var autoScan: Bool { 
        didSet { if oldValue != autoScan { configStore.autoScan = autoScan } } 
    }
    @Published var autoRefactor: Bool { 
        didSet { if oldValue != autoRefactor { configStore.autoRefactor = autoRefactor } } 
    }

    // MARK: - 运行时状态
    /// 是否正在处理 AI 请求
    @Published var isProcessing = false
    /// 当前流式输出的增量内容
    @Published var streamingContent = ""
    /// 内存中的对话历史
    @Published var chatHistory: [ChatMessage] = []

    /// 服务是否已就绪（配置完整且开启）
    var isReady: Bool {
        isEnabled && !apiKey.isEmpty
    }

    // MARK: - 内部组件
    private let configStore: LLMConfigStore
    private let contextBuilder: LLMContextBuilder
    private let historyStore: ChatHistoryStore
    
    // 专项子服务
    private var chatService: LLMChatService?
    private var ingestService: LLMIngestService?
    private var refactorService: LLMRefactorService?
    private var retrievalService: LLMRetrievalService?

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    
    private init() {
        self.configStore = LLMConfigStore()
        self.historyStore = ChatHistoryStore()
        self.contextBuilder = LLMContextBuilder()

        // 从持久化配置中初始化发布属性
        self._provider = .init(initialValue: configStore.provider)
        self._apiKey = .init(initialValue: configStore.apiKey)
        self._baseURL = .init(initialValue: configStore.baseURL)
        self._model = .init(initialValue: configStore.model)
        self._isEnabled = .init(initialValue: configStore.isEnabled)
        self._autoScan = .init(initialValue: configStore.autoScan)
        self._autoRefactor = .init(initialValue: configStore.autoRefactor)

        // 加载历史消息
        self.chatHistory = historyStore.messages

        // 初始化子服务
        updateSubServices()
        // 绑定事件监听
        setupSubscriptions()
    }

    // MARK: - Private Methods

    private func setupSubscriptions() {
        // 订阅配置层变更，保持 UI 响应
        configStore.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.async { self.syncFromConfigStore() }
            }
            .store(in: &cancellables)

        // 订阅全局清理事件
        AppEventBus.shared.subscribe()
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                if case .clearAllDataRequested = event { self?.clearChatHistory() }
            }
            .store(in: &cancellables)
    }

    private func syncFromConfigStore() {
        if configStore.provider != provider { provider = configStore.provider }
        if configStore.apiKey != apiKey { apiKey = configStore.apiKey }
        if configStore.baseURL != baseURL { baseURL = configStore.baseURL }
        if configStore.model != model { model = configStore.model }
        if configStore.isEnabled != isEnabled { isEnabled = configStore.isEnabled }
        if configStore.autoScan != autoScan { autoScan = configStore.autoScan }
        if configStore.autoRefactor != autoRefactor { autoRefactor = configStore.autoRefactor }
        updateSubServices()
    }

    private func updateSubServices() {
        let client = LLMClient(baseURL: baseURL, apiKey: apiKey)
        self.chatService = LLMChatService(client: client, model: model)
        self.ingestService = LLMIngestService(client: client, model: model, contextBuilder: contextBuilder)
        self.refactorService = LLMRefactorService(client: client, model: model)
        self.retrievalService = LLMRetrievalService(client: client, model: model, contextBuilder: contextBuilder)
    }

    // MARK: - LLMServiceProtocol (Facade Implementations)

    /// 通用文本生成接口
    func generate(prompt: String, systemPrompt: String) async throws -> String {
        guard isEnabled, !apiKey.isEmpty else { throw LLMError.notConfigured }
        let client = LLMClient(baseURL: baseURL, apiKey: apiKey)
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": prompt]
            ],
            "temperature": AppConfig.AI.defaultTemperature
        ]

        let startTime = Date()
        let response = try await client.sendRequest(body: body)
        let latency = Int(Date().timeIntervalSince(startTime) * 1000)

        // 记录调用指标
        recordUsageIfPossible(response: response, latency: latency)

        guard let content = LLMResponseProcessor.extractContent(from: response) else {
            throw LLMError.invalidResponse
        }
        return content
    }

    /// 执行核心对话
    func chat(query: String, pages: [KnowledgePage]) async throws -> ChatMessage {
        guard isEnabled, let chatService else { throw LLMError.notConfigured }

        let perf = ServiceContainer.shared.resolve(PerformanceService.self)
        
        return try await perf.measureAsync("ragChain") {
            let userMessage = ChatMessage(role: .user, content: query)
            self.chatHistory.append(userMessage)
            historyStore.append(userMessage)

            isProcessing = true
            defer { isProcessing = false }

            // 1. 构建 RAG 上下文
            let context = await contextBuilder.buildRelevantContext(query: query)
            let rankedPages = (try? await rerank(query: query, candidates: pages)) ?? pages
            let systemPrompt = contextBuilder.buildSystemPrompt(pages: rankedPages) + "\n\n" + context

            // 2. 调用对话服务
            let startTime = Date()
            let response = try await chatService.chat(
                systemPrompt: systemPrompt, 
                query: query, 
                history: Array(historyStore.recent(AppConstants.AI.maxChatHistorySize))
            )
            let latency = Int(Date().timeIntervalSince(startTime) * 1000)

            let assistantMessage = ChatMessage(role: .assistant, content: response)
            self.chatHistory.append(assistantMessage)
            historyStore.append(assistantMessage)
            historyStore.persistToDisk()

            // 3. 异步性能记录与评估
            asyncMetrics(query: query, response: response, context: context, systemPrompt: systemPrompt, latency: latency)

            return assistantMessage
        }
    }

    /// 执行流式对话
    func chatStream(query: String, pages: [KnowledgePage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream(String.self) { continuation in
            Task {
                guard isEnabled, let chatService else {
                    continuation.finish(throwing: LLMError.notConfigured)
                    return
                }

                await MainActor.run {
                    isProcessing = true
                    streamingContent = ""
                    let userMsg = ChatMessage(role: .user, content: query)
                    self.chatHistory.append(userMsg)
                    historyStore.append(userMsg)
                }

                let context = await contextBuilder.buildRelevantContext(query: query)
                let rankedPages = (try? await rerank(query: query, candidates: pages)) ?? pages
                let systemPrompt = contextBuilder.buildSystemPrompt(pages: rankedPages) + "\n\n" + context
                let history = Array(historyStore.recent(AppConstants.AI.maxChatHistorySize))

                do {
                    for try await chunk in chatService.streamChat(systemPrompt: systemPrompt, query: query, history: history) {
                        await MainActor.run { streamingContent += chunk }
                        continuation.yield(chunk)
                    }

                    await MainActor.run {
                        let assistantMsg = ChatMessage(role: .assistant, content: streamingContent)
                        self.chatHistory.append(assistantMsg)
                        historyStore.append(assistantMsg)
                        historyStore.persistToDisk()
                        isProcessing = false
                    }
                    continuation.finish()
                } catch {
                    await MainActor.run { isProcessing = false }
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// 核心对话 (UI 兼容别名)
    func sendChatMessage(query: String, pages: [KnowledgePage]) async throws {
        _ = try await chat(query: query, pages: pages)
    }

    /// 取消当前正在进行的请求
    func cancelCurrentRequest() {
        isProcessing = false
        // TODO: [SR-02] 深度集成 LLMClient 的取消机制
    }

    /// 智能内容摄入
    func smartIngest(title: String, rawContent: String, pages: [KnowledgePage]) async throws -> SmartIngestResult {
        guard let ingestService else { throw LLMError.notConfigured }
        return try await ingestService.smartIngest(title: title, rawContent: rawContent, pages: pages)
    }

    /// 潜在链接发现
    func discoverPotentialLinks(content: String, existingTitles: [String]) async throws -> [String] {
        guard let refactorService else { return [] }
        return try await refactorService.discoverPotentialLinks(content: content, existingTitles: existingTitles)
    }

    /// 内容自动折叠
    func foldContent(existingContent: String, newContent: String, title: String) async throws -> String {
        guard let refactorService else { return existingContent + "\n\n" + newContent }
        return try await refactorService.foldContent(existingContent: existingContent, newContent: newContent, title: title)
    }

    /// 重构建议分析
    func analyzeForRefactoring(pages: [KnowledgePage]) async throws -> [RefactorSuggestion] {
        guard let refactorService else { return [] }
        return try await refactorService.analyzeForRefactoring(pages: pages)
    }

    /// 查询改写
    func rewriteQuery(_ query: String) async -> String {
        guard let retrievalService else { return query }
        return await retrievalService.rewriteQuery(query)
    }

    /// 意图扩展
    func expandQuery(_ query: String) async -> [String] {
        guard let retrievalService else { return [query] }
        return await retrievalService.expandQuery(query)
    }

    /// 语义重排
    func rerank(query: String, candidates: [KnowledgePage]) async throws -> [KnowledgePage] {
        guard let retrievalService else { return candidates }
        return try await retrievalService.rerank(query: query, candidates: candidates)
    }

    /// 文本分块重排
    func rerankChunks(query: String, chunks: [PageChunk]) async -> [PageChunk] {
        guard let retrievalService else { return chunks }
        return await retrievalService.rerankChunks(query: query, chunks: chunks)
    }

    /// 生成假设性文档 (HyDE)
    func generateHypotheticalDocument(query: String) async -> String {
        guard let retrievalService else { return query }
        return await retrievalService.generateHypotheticalDocument(query: query)
    }

    /// 连通性测试
    func validateAPIKey() async throws -> ValidationResult {
        let start = Date()
        do {
            _ = try await generate(prompt: "Hello", systemPrompt: "Keep it short.")
            let latency = Int(Date().timeIntervalSince(start) * 1000)
            return ValidationResult(isSuccess: true, latencyMS: latency, errorCode: nil, errorMessage: nil)
        } catch {
            let latency = Int(Date().timeIntervalSince(start) * 1000)
            return ValidationResult(isSuccess: false, latencyMS: latency, errorCode: "ERR", errorMessage: error.localizedDescription)
        }
    }

    // MARK: - Metrics & Recording

    private func recordUsageIfPossible(response: [String: Any], latency: Int = 0) {
        guard let usage = response["usage"] as? [String: Any],
              let prompt = usage["prompt_tokens"] as? Int,
              let completion = usage["completion_tokens"] as? Int,
              let modelUsed = response["model"] as? String else { return }

        Task.detached(priority: .background) {
            let store = ServiceContainer.shared.resolve(KnowledgePageStore.self)
            try? store.recordLLMCall(model: modelUsed, prompt: prompt, completion: completion, latency: latency)
        }
    }

    private func asyncMetrics(query: String, response: String, context: String, systemPrompt: String, latency: Int) {
        let modelName = self.model
        Task.detached(priority: .background) {
            let store = ServiceContainer.shared.resolve(KnowledgePageStore.self)
            let promptTokens = (systemPrompt.count + query.count) / AppConstants.AI.charactersPerToken
            let completionTokens = response.count / AppConstants.AI.charactersPerToken
            try? store.recordLLMCall(model: modelName, prompt: promptTokens, completion: completionTokens, latency: latency)

            let evalService = ServiceContainer.shared.resolve(RAGEvaluationService.self)
            _ = await evalService.evaluate(query: query, answer: response, context: context)
        }
    }

    func clearChatHistory() {
        chatHistory.removeAll()
        historyStore.clear()
        objectWillChange.send()
    }
}

// MARK: - Validation Support
extension LLMService {
    struct ValidationResult {
        let isSuccess: Bool
        let latencyMS: Int
        let errorCode: String?
        let errorMessage: String?
    }
}
