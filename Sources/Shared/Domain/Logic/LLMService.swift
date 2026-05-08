// LLMService.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了知识管理系统的核心 AI 大模型服务层（LLMService），作为系统与生成式 AI 交互的中心枢纽与编排器。
// 该服务通过高度解耦的架构设计，整合了配置管理、上下文构建、历史持久化及多协议子服务，主要功能点如下：
// 1. 多维度业务支持：实现了对话、流式响应、智能导入（Smart Ingest）、关联发现及查询重写等核心 RAG 流程。
// 2. 状态驱动与响应：通过 Combine 订阅配置变更及系统级清理事件（AppEventBus），确保 UI 与底层服务的物理一致性。
// 3. 架构解耦：作为 facade 模式的实现，将具体任务分发至 LLMChatService、LLMRefactorService 等专项服务。
// 版本: 1.3
// 修改记录:
//   - 2026-05-05: 完整重构以实现 LLMServiceProtocol，修复功能丢失问题，集成全局清理事件。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Combine

/// AI 大模型调度服务 (L1 服务层)
@MainActor
final class LLMService: ObservableObject, LLMServiceProtocol, @unchecked Sendable {

    static let shared = LLMService()

    // MARK: - UI 状态属性 (与 LLMConfigStore 同步)
    @Published var provider: LLMProvider { 
        didSet { 
            if oldValue != provider {
                configStore.provider = provider
                updateSubServices()
            }
        } 
    }
    @Published var apiKey: String { 
        didSet { 
            if oldValue != apiKey {
                configStore.apiKey = apiKey
                updateSubServices()
            }
        } 
    }
    @Published var baseURL: String { 
        didSet { 
            if oldValue != baseURL {
                configStore.baseURL = baseURL
                updateSubServices()
            }
        } 
    }
    @Published var model: String { 
        didSet { 
            if oldValue != model {
                configStore.model = model
                updateSubServices()
            }
        } 
    }
    @Published var isEnabled: Bool { 
        didSet { 
            if oldValue != isEnabled {
                configStore.isEnabled = isEnabled
                // 状态变更时也尝试刷新服务，确保子服务可用性与开关同步
                updateSubServices()
            }
        } 
    }
    @Published var autoScan: Bool { 
        didSet { if oldValue != autoScan { configStore.autoScan = autoScan } } 
    }
    @Published var autoRefactor: Bool { 
        didSet { if oldValue != autoRefactor { configStore.autoRefactor = autoRefactor } } 
    }

    // 运行时状态
    @Published var isProcessing = false
    @Published var streamingContent = ""
    @Published var chatHistory: [ChatMessage] = []

    var isReady: Bool {
        isEnabled && !apiKey.isEmpty
    }

    // MARK: - 内部组件
    private let configStore: LLMConfigStore
    private let contextBuilder: LLMContextBuilder
    private let historyStore: ChatHistoryStore
    private var refactorService: LLMRefactorService?
    private var chatService: LLMChatService?

    private var cancellables = Set<AnyCancellable>()

    // MARK: - 初始化
    init() {
        self.configStore = LLMConfigStore()
        self.historyStore = ChatHistoryStore()
        self.contextBuilder = LLMContextBuilder()

        // 从持久化配置中初始化属性
        self._provider = .init(initialValue: configStore.provider)
        self._apiKey = .init(initialValue: configStore.apiKey)
        self._baseURL = .init(initialValue: configStore.baseURL)
        self._model = .init(initialValue: configStore.model)
        self._isEnabled = .init(initialValue: configStore.isEnabled)
        self._autoScan = .init(initialValue: configStore.autoScan)
        self._autoRefactor = .init(initialValue: configStore.autoRefactor)

        // 加载历史消息
        self.chatHistory = historyStore.messages

        // 初始化专项服务
        updateSubServices()

        // 设置订阅与事件监听
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        // 1. 同步配置存储层的变更
        configStore.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                // 注意：objectWillChange 触发时值尚未更新，因此我们延迟一个周期读取最新值
                DispatchQueue.main.async {
                    if self.configStore.provider != self.provider { self.provider = self.configStore.provider }
                    if self.configStore.apiKey != self.apiKey { self.apiKey = self.configStore.apiKey }
                    if self.configStore.baseURL != self.baseURL { self.baseURL = self.configStore.baseURL }
                    if self.configStore.model != self.model { self.model = self.configStore.model }
                    if self.configStore.isEnabled != self.isEnabled { self.isEnabled = self.configStore.isEnabled }
                    if self.configStore.autoScan != self.autoScan { self.autoScan = self.configStore.autoScan }
                    if self.configStore.autoRefactor != self.autoRefactor { self.autoRefactor = self.configStore.autoRefactor }
                    // 值同步后刷新子服务
                    self.updateSubServices()
                }
            }
            .store(in: &cancellables)

        // 2. 订阅全局清理事件
        AppEventBus.shared.subscribe()
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                if case .clearAllDataRequested = event {
                    self?.clearChatHistory()
                }
            }
            .store(in: &cancellables)
    }

    private func updateSubServices() {
        let client = makeClient()
        self.refactorService = LLMRefactorService(client: client, model: model)
        self.chatService = LLMChatService(client: client, model: model)
    }

    private func makeClient() -> LLMClient {
        LLMClient(baseURL: baseURL, apiKey: apiKey)
    }

    // MARK: - LLMChatServiceProtocol

    func generate(prompt: String, systemPrompt: String) async throws -> String {
        guard isEnabled, !apiKey.isEmpty else { throw LLMError.notConfigured }
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": prompt]
            ],
            "temperature": AppConfig.AI.defaultTemperature
        ]

        let startTime = Date()
        let response = try await makeClient().sendRequest(body: body)
        let latency = Int(Date().timeIntervalSince(startTime) * 1000)

        // 核心监控：异步记录调用日志 (Token + Latency)
        recordUsageIfPossible(response: response, latency: latency)

        guard let choice = (response["choices"] as? [[String: Any]])?.first,
              let message = choice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw LLMError.invalidResponse
        }
        return content
    }

    /// 从响应中提取并记录 LLM 调用详情
    private func recordUsageIfPossible(response: [String: Any], latency: Int = 0) {
        guard let usage = response["usage"] as? [String: Any],
              let prompt = usage["prompt_tokens"] as? Int,
              let completion = usage["completion_tokens"] as? Int,
              let modelUsed = response["model"] as? String else {
            return
        }

        // 异步写入数据库，不阻塞生成流程
        Task.detached(priority: .background) {
            let store = ServiceContainer.shared.resolve(KnowledgePageStore.self)
            try? store.recordLLMCall(model: modelUsed, prompt: prompt, completion: completion, latency: latency)
        }
    }

    func chat(query: String, pages: [KnowledgePage]) async throws -> ChatMessage {
        guard isEnabled, !apiKey.isEmpty, let chatService else { throw LLMError.notConfigured }

        let userMessage = ChatMessage(role: .user, content: query)
        self.chatHistory.append(userMessage)
        historyStore.append(userMessage)

        isProcessing = true
        defer { isProcessing = false }

        // 1. 异步获取相关上下文 (多路召回)
        let context = await contextBuilder.buildRelevantContext(query: query)

        // 2. 对候选页面进行重排序 (Rerank)
        let rankedPages = (try? await rerank(query: query, candidates: pages)) ?? pages
        let systemPrompt = contextBuilder.buildSystemPrompt(pages: rankedPages) + "\n\n" + context

        let startTime = Date()
        let response = try await chatService.chat(systemPrompt: systemPrompt, query: query, history: Array(historyStore.recent(AppConstants.AI.maxChatHistorySize)))
        let latency = Int(Date().timeIntervalSince(startTime) * 1000)

        let assistantMessage = ChatMessage(role: .assistant, content: response)

        self.chatHistory.append(assistantMessage)
        historyStore.append(assistantMessage)
        historyStore.persistToDisk()

        // 3. 异步记录监控与评估 (18, 19)
        let modelName = self.model // 提前捕获以避免 Actor 隔离限制
        Task.detached(priority: .background) {
            let store = ServiceContainer.shared.resolve(KnowledgePageStore.self)
            // 估算 Token (使用 AppConfig 比例)
            let promptTokens = (systemPrompt.count + query.count) / AppConstants.AI.charactersPerToken
            let completionTokens = response.count / AppConstants.AI.charactersPerToken
            try? store.recordLLMCall(model: modelName, prompt: promptTokens, completion: completionTokens, latency: latency)

            let evalService = ServiceContainer.shared.resolve(RAGEvaluationService.self)
            _ = await evalService.evaluate(query: query, answer: response, context: context)
        }

        return assistantMessage
    }

    /// UI 兼容别名
    func sendChatMessage(query: String, pages: [KnowledgePage]) async throws {
        _ = try await chat(query: query, pages: pages)
    }

    func cancelCurrentRequest() {
        isProcessing = false
        // 实际取消逻辑需要委托给 LLMClient 的 URLSessionTask
    }

    func chatStream(query: String, pages: [KnowledgePage]) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream(String.self) { continuation in
            Task {
                guard isEnabled, !apiKey.isEmpty, let chatService else {
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

    // MARK: - LLMKnowledgeServiceProtocol

    func smartIngest(title: String, rawContent: String, pages: [KnowledgePage]) async throws -> SmartIngestResult {
        guard isEnabled, !apiKey.isEmpty else { throw LLMError.notConfigured }
        let prompt = contextBuilder.buildIngestPrompt(title: title, rawContent: rawContent, pages: pages)
        let response = try await generate(prompt: prompt, systemPrompt: "")

        if let result = LLMResponseProcessor.parseSmartIngest(response) {
            return result
        }
        throw LLMError.invalidResponse
    }

    func discoverPotentialLinks(content: String, existingTitles: [String]) async throws -> [String] {
        guard let refactorService else { return [] }
        return try await refactorService.discoverPotentialLinks(content: content, existingTitles: existingTitles)
    }

    func foldContent(existingContent: String, newContent: String, title: String) async throws -> String {
        guard let refactorService else { return existingContent + "\n\n" + newContent }
        return try await refactorService.foldContent(existingContent: existingContent, newContent: newContent, title: title)
    }

    func analyzeForRefactoring(pages: [KnowledgePage]) async throws -> [RefactorSuggestion] {
        guard isEnabled, !apiKey.isEmpty else { return [] }
        let prompt = "Analyze these pages for refactoring (merging, splitting, or link improvement): " + pages.map { $0.title }.joined(separator: ", ")
        let response = try await generate(prompt: prompt, systemPrompt: "Return JSON array of RefactorSuggestion")
        return LLMResponseProcessor.parseRefactorSuggestions(response)
    }

    // MARK: - 连通性测试

    struct ValidationResult {
        let isSuccess: Bool
        let latencyMS: Int
        let errorCode: String?
        let errorMessage: String?
    }

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

    // MARK: - LLMRetrievalServiceProtocol

    func rewriteQuery(_ query: String) async -> String {
        guard isEnabled, !apiKey.isEmpty else { return query }
        let prompt = contextBuilder.buildRewritePrompt(query: query)
        return (try? await generate(prompt: prompt, systemPrompt: "")) ?? query
    }

    func expandQuery(_ query: String) async -> [String] {
        guard isEnabled, !apiKey.isEmpty else { return [query] }
        let prompt = PromptService.shared.queryExpansionPrompt + "\n\nOriginal Query: \(query)"
        do {
            let response = try await generate(prompt: prompt, systemPrompt: "Return JSON array only.")
            let variations = LLMResponseProcessor.parseJSONArray(response)
            return variations.isEmpty ? [query] : variations
        } catch {
            return [query]
        }
    }

    func rerank(query: String, candidates: [KnowledgePage]) async throws -> [KnowledgePage] {
        guard isEnabled, !candidates.isEmpty else { return candidates }

        let titles = candidates.map { "\($0.title) (ID: \($0.id))" }.joined(separator: "\n")
        let prompt = PromptService.shared.rerankPrompt + "\n\nQuery: \(query)\n\nCandidates:\n\(titles)"

        let response = try await generate(prompt: prompt, systemPrompt: "")
        let rankedIDs = LLMResponseProcessor.parseJSONArray(response)

        // 根据返回的 ID 重新排序
        var result = candidates
        result.sort { a, b in
            let idxA = rankedIDs.firstIndex(of: a.id.uuidString) ?? 999
            let idxB = rankedIDs.firstIndex(of: b.id.uuidString) ?? 999
            return idxA < idxB
        }
        return result
    }

    /// 为 HyDE 策略生成假设性文档
    func generateHypotheticalDocument(query: String) async -> String {
        guard isEnabled, !apiKey.isEmpty else { return query }
        let prompt = "请针对以下问题写一个简短但专业的假设性回答（不要包含前导词），这将用于向量检索优化：\n\n问题：\(query)"
        let systemPrompt = "你是一个知识库助手，擅长生成精准的学术或技术性回答。"
        return (try? await generate(prompt: prompt, systemPrompt: systemPrompt)) ?? query
    }

    /// 对分块进行重排序 (Self-Reflection / Rerank)
    func rerankChunks(query: String, chunks: [PageChunk]) async -> [PageChunk] {
        guard isEnabled, !chunks.isEmpty else { return chunks }

        // 限制重排序的数量，避免 Token 爆炸
        let candidates = chunks.prefix(10)
        let context = candidates.enumerated().map { "[\($0)] \($1.content)" }.joined(separator: "\n\n")

        let prompt = """
        查询: \(query)

        候选文本块:
        \(context)

        请根据相关性对上述块进行排序。仅返回排序后的索引数组，例如 [2, 0, 1]。
        """

        do {
            let response = try await generate(prompt: prompt, systemPrompt: "你是一个精准的 Rerank 引擎。仅返回 JSON 数组。")
            let rankedIndices = LLMResponseProcessor.parseJSONArray(response).compactMap { Int($0) }

            var result: [PageChunk] = []
            for index in rankedIndices where index < candidates.count {
                result.append(candidates[index])
            }

            // 补全未命中的块
            let resultIDs = Set(result.map { $0.id })
            for chunk in chunks where !resultIDs.contains(chunk.id) {
                result.append(chunk)
            }

            return result
        } catch {
            return chunks
        }
    }

    // MARK: - 清理逻辑

    func clearChatHistory() {
        chatHistory.removeAll()
        historyStore.clear()
        objectWillChange.send()
    }
}
