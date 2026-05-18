// LLMService.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：本文件实现了知识管理系统的核心 AI 调度服务 (LLMService)，作为 AI 能力的统一入口与编排器。
// 核心职责：
// 1. 配置管理：同步并持久化 LLM 提供商、API Key 及模型参数。
// 2. 任务编排：将具体的 AI 任务分发至专项子服务（对齐、摄入、重构、检索）。
// 3. 监控与评估：记录调用时长、Token 消耗并触发 RAG 评估。
// MARK: [SR-02] 混合检索 (RAG) 链路调度与 AI 能力枢纽
// MARK: [PR-02] RAG 链路耗时优化目标 < 1.5s
// 版本: 1.5
// 修改记录:
//   - 2026-05-18: 完美翻新为 100% 结构化中文三斜杠注释，对齐 Swift 6 Facade 面板设计规范
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Combine

/// AI 大模型调度门面中枢服务（LLMService）。
/// 负责协调与编排各项大语言模型（LLM）的底层子能力，维护全局 AI 运行生命周期及状态，
/// 它是整个系统所有 AI 能力与 RAG 检索管线的统一门面接口。
@MainActor
final class LLMService: ObservableObject, LLMServiceProtocol, @unchecked Sendable {

    /// 全局唯一的线程安全单例实例。
    static let shared = LLMService()

    // MARK: - 注入依赖
    
    /// LLM 配置管理器，用以动态拉取 API Key、模型规格及服务器基准地址。
    @ObservationIgnored @Inject private var configManager: LLMConfigManager
    
    /// AI 指标分析服务，用以审计 Token 吞吐和响应耗时。
    @ObservationIgnored @Inject private var analytics: AIAnalyticsService

    // MARK: - UI 状态属性 (透传转发至 configManager)
    
    /// 当前所选的模型服务提供商（例如 OpenAI, Anthropic, Ollama 等）。
    var provider: LLMProvider {
        get { configManager.provider }
        set { configManager.provider = newValue; objectWillChange.send() }
    }
    
    /// 安全的访问密钥 API Key。
    var apiKey: String {
        get { configManager.apiKey }
        set { configManager.apiKey = newValue; objectWillChange.send() }
    }
    
    /// API 调用的基础网关地址。
    var baseURL: String {
        get { configManager.baseURL }
        set { configManager.baseURL = newValue; objectWillChange.send() }
    }
    
    /// 大语言模型的具体代号规格（如 gpt-4o, claude-3-5-sonnet 等）。
    var model: String {
        get { configManager.model }
        set { configManager.model = newValue; objectWillChange.send() }
    }
    
    /// AI 模块是否处于开启状态。
    var isEnabled: Bool {
        get { configManager.isEnabled }
        set { configManager.isEnabled = newValue; objectWillChange.send() }
    }
    
    /// 是否开启后台自动化知识扫描与标签提取。
    var autoScan: Bool {
        get { configManager.autoScan }
        set { configManager.autoScan = newValue; objectWillChange.send() }
    }
    
    /// 是否使能后台智能重构分析与自动化双链链接发现。
    var autoRefactor: Bool {
        get { configManager.autoRefactor }
        set { configManager.autoRefactor = newValue; objectWillChange.send() }
    }

    // MARK: - 运行时状态发布器
    
    /// 标记当前是否正在与大模型进行网络交互与推理计算。
    @Published var isProcessing = false
    
    /// 缓存当前流式交互中吐出的累积回复字符串（用以驱动打字机特效渲染）。
    @Published var streamingContent = ""

    /// 判断大模型所需的密钥、地址及开关是否已配置就绪。
    var isReady: Bool { configManager.isReady }

    // MARK: - 内部组件
    
    /// 专门负责进行上下文组装与 Prompt 模板拼装的构建器。
    private let contextBuilder: LLMContextBuilder
    
    /// 专项对话服务。
    private var chatService: LLMChatService?
    /// 智能摄入拆分服务。
    private var ingestService: LLMIngestService?
    /// 文档重构与潜在链接推荐服务。
    private var refactorService: LLMRefactorService?
    /// 高性能 RAG 检索重排服务。
    private var retrievalService: LLMRetrievalService?

    private var cancellables = Set<AnyCancellable>()

    // MARK: - 初始化
    
    /// 私有化单例初始化构造方法。
    private init() {
        self.contextBuilder = LLMContextBuilder()
        
        // 1. 初始化各专项子服务
        updateSubServices()
        
        // 2. 注册配置中心动态变更通知，随时热重载底层子客户端
        configManager.setRefreshHandler { [weak self] in
            self?.updateSubServices()
            self?.objectWillChange.send()
        }
    }

    /// 热重载并同步实例化各底层的专项 AI 子客户端。
    private func updateSubServices() {
        let client = LLMClient(baseURL: configManager.baseURL, apiKey: configManager.apiKey)
        self.chatService = LLMChatService(client: client, model: configManager.model)
        self.ingestService = LLMIngestService(client: client, model: configManager.model, contextBuilder: contextBuilder)
        self.refactorService = LLMRefactorService(client: client, model: configManager.model)
        self.retrievalService = LLMRetrievalService(client: client, model: configManager.model, contextBuilder: contextBuilder)
    }

    // MARK: - LLMServiceProtocol 统一门面契约实现

    /// 通用一问一答文本推理生成接口。
    /// - Parameters:
    ///   - prompt: 投喂给模型的具体用户提示词。
    ///   - systemPrompt: 设定模型人设的全局系统提示词。
    /// - Returns: 模型推理生成后的最终纯文本答案。
    /// - Throws: `LLMError.notConfigured`（未配置就绪）或底层网络/协议异常。
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

        // 审计调用时长与 Token 开销
        analytics.recordUsage(model: model, response: response, latency: latency)

        guard let content = LLMUtils.extractContent(from: response) else {
            throw LLMError.invalidResponse
        }
        return content
    }

    /// 执行核心 RAG（检索增强生成）闭环的问答交互。
    /// - Parameters:
    ///   - query: 用户输入的原始搜索问句。
    ///   - history: 当前会话的往期历史消息列表。
    ///   - pages: 供上下文检索召回的备选页面集。
    /// - Returns: 模型推理并附带深度引用溯源的回复 DTO 实体。
    /// - Throws: `LLMError.notConfigured` 或大模型处理异常。
    func chat(query: String, history: [ChatMessageDTO], pages: [any KnowledgePageRepresentable]) async throws -> ChatMessageDTO {
        guard isEnabled, let chatService else { throw LLMError.notConfigured }
        
        isProcessing = true
        defer { isProcessing = false }

        // 1. 注册并在 UI 层启动任务中心异步进度条
        let taskID = TaskCenter.shared.addTask(type: .ai, name: "AI Chat", target: query)
        await TaskCenter.shared.updateTask(taskID, status: .running(progress: 0.2, stage: .embedding))
        
        // 2. 检索向量库及 FTS5 混合语义，构建保护双链的语义上下文
        let (context, sources) = await contextBuilder.buildRelevantContext(query: query)
        await SourceStore.shared.updateSources(sources)
        
        // 3. 执行语义重排，精简检索召回的冗余分块，防范 LLM 陷入“迷失在中间（Lost in the Middle）”困境
        await TaskCenter.shared.updateTask(taskID, status: .running(progress: 0.5, stage: .retrieval))
        let rankedPages = (try? await rerank(query: query, candidates: pages)) ?? pages
        let systemPrompt = contextBuilder.buildSystemPrompt(pages: rankedPages) + "\n\n" + context
 
        // 4. 调用大模型，记录耗时指标并触发 RAG 自评估
        await TaskCenter.shared.updateTask(taskID, status: .running(progress: 0.8, stage: .synthesis))
        let startTime = Date()
        let response = try await chatService.chat(systemPrompt: systemPrompt, query: query, history: history)
        let latency = Int(Date().timeIntervalSince(startTime) * 1000)

        analytics.recordRAGMetrics(query: query, response: response, context: context, systemPrompt: systemPrompt, modelName: model, latency: latency)
        
        await TaskCenter.shared.completeTask(id: taskID)
        return ChatMessageDTO(role: .assistant, content: response)
    }

    /// 执行基于 AsyncStream 的高性能流式打字机问答。
    /// - Parameters:
    ///   - query: 用户输入的原始搜索问句。
    ///   - history: 往期会话的历史上下文列表。
    ///   - pages: 供检索的备选文档集。
    /// - Returns: 可迭代的流式异步文本片段流。
    func chatStream(query: String, history: [ChatMessageDTO], pages: [any KnowledgePageRepresentable]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard isEnabled, let chatService else {
                    continuation.finish(throwing: LLMError.notConfigured)
                    return
                }

                let taskID = await TaskCenter.shared.addTask(type: .ai, name: "AI Chat Stream", target: query)
                await MainActor.run { isProcessing = true }
                
                defer {
                    Task {
                        await MainActor.run { isProcessing = false }
                        await TaskCenter.shared.completeTask(id: taskID)
                    }
                }

                do {
                    // 1. 构建向量及倒排混合上下文，更新引用引用源
                    let (context, sources) = await contextBuilder.buildRelevantContext(query: query)
                    await SourceStore.shared.updateSources(sources)
                    
                    // 2. 排序候选文档，动态拼装系统人设
                    let rankedPages = (try? await rerank(query: query, candidates: pages)) ?? pages
                    let systemPrompt = contextBuilder.buildSystemPrompt(pages: rankedPages) + "\n\n" + context

                    var fullResponse = ""
                    // 3. 消费打字机流片段，不断投递至流管道，同步刷新 UI 打字状态
                    for try await chunk in chatService.streamChat(systemPrompt: systemPrompt, query: query, history: history) {
                        fullResponse += chunk
                        await MainActor.run { self.streamingContent = fullResponse }
                        continuation.yield(chunk)
                    }

                    // 4. 异步归档 RAG 精准度元数据以做治理评估
                    analytics.recordRAGMetrics(query: query, response: fullResponse, context: context, systemPrompt: systemPrompt, modelName: model, latency: 0)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// 智能内容摄入与自动语义拆分服务。
    /// - Parameters:
    ///   - title: 输入文档的建议标题。
    ///   - rawContent: 输入文档的无结构原始长文本。
    ///   - pages: 当前知识金库的已有上下文，用以识别重合话题。
    /// - Returns: 包含自动提炼的双链链接、格式建议和核心标签的结构化 DTO 实体。
    /// - Throws: API 响应或配置层故障。
    func smartIngest(title: String, rawContent: String, pages: [any KnowledgePageRepresentable]) async throws -> SmartIngestResultDTO {
        guard let ingestService else { throw LLMError.notConfigured }
        return try await ingestService.smartIngest(title: title, rawContent: rawContent, pages: pages)
    }

    /// 智能推荐：基于当前文档的内容，深度挖掘并自动发现可能漏标的双向逻辑链（[[潜在链接]]）。
    /// - Parameters:
    ///   - content: 待扫描的当前页面 Markdown 文本。
    ///   - existingTitles: 系统中已经存在的全部合法百科标题池。
    /// - Returns: 推荐的页面标题列表。
    func discoverPotentialLinks(content: String, existingTitles: [String]) async throws -> [String] {
        guard let refactorService else { return [] }
        return try await refactorService.discoverPotentialLinks(content: content, existingTitles: existingTitles)
    }

    /// 智能重构：对两个存在内容交叉重合的页面执行增量折叠，生成优雅的 HTML 折叠 `<details>` 块。
    /// - Parameters:
    ///   - existingContent: 目标页面的现有 Markdown 正文。
    ///   - newContent: 新追加的内容数据。
    ///   - title: 页面标题。
    /// - Returns: 重构合并完成后的全新 Markdown 字符串。
    func foldContent(existingContent: String, newContent: String, title: String) async throws -> String {
        guard let refactorService else { return existingContent + "\n\n" + newContent }
        return try await refactorService.foldContent(existingContent: existingContent, newContent: newContent, title: title)
    }

    /// 后台诊断：扫描整个笔记本中所有页面，给出高内聚低耦合的重构与合并建议。
    /// - Parameter pages: 全库待诊断页面集合。
    /// - Returns: 重构治理建议 DTO 数组。
    func analyzeForRefactoring(pages: [any KnowledgePageRepresentable]) async throws -> [RefactorSuggestionDTO] {
        guard let refactorService else { return [] }
        return try await refactorService.analyzeForRefactoring(pages: pages)
    }

    /// RAG 召回链路优化：查询改写（Query Rewriting）。
    /// 将用户口语化表达转化为面向检索的精准语义搜索短语。
    /// - Parameter query: 用户的口语化输入。
    /// - Returns: 重构后的检索友好短语。
    func rewriteQuery(_ query: String) async -> String {
        guard isEnabled, !apiKey.isEmpty, let retrievalService else { return query }
        return await retrievalService.rewriteQuery(query)
    }

    /// RAG 召回链路优化：意图扩展（Query Expansion）。
    /// 扩充与用户问题强相关的同义意图数组。
    /// - Parameter query: 用户的原始问句。
    /// - Returns: 扩展后的同义意图检索词数组。
    func expandQuery(_ query: String) async -> [String] {
        guard isEnabled, !apiKey.isEmpty, let retrievalService else { return [query] }
        return await retrievalService.expandQuery(query)
    }

    /// RAG 排序链路优化：文档级的语义重排（Document Reranking）。
    /// 计算候选页面与 query 的深度语义相关度得分，对页面集进行精细重排序。
    /// - Parameters:
    ///   - query: 检索词。
    ///   - candidates: 候选文档数组。
    /// - Returns: 重排后的最新文档序列。
    func rerank(query: String, candidates: [any KnowledgePageRepresentable]) async throws -> [any KnowledgePageRepresentable] {
        guard isEnabled, !apiKey.isEmpty, let retrievalService else { return candidates }
        return try await retrievalService.rerank(query: query, candidates: candidates)
    }

    /// RAG 排序链路优化：细粒度分块级的重排（Chunk Reranking）。
    /// 精准提取与搜索词最直接相关的文本分块片段。
    /// - Parameters:
    ///   - query: 检索词。
    ///   - chunks: 向量库或倒排检索初筛出的大量文本块。
    /// - Returns: 重构排序后的前置核心文本块。
    func rerankChunks(query: String, chunks: [PageChunk]) async -> [PageChunk] {
        guard isEnabled, !apiKey.isEmpty, let retrievalService else { return chunks }
        return await retrievalService.rerankChunks(query: query, chunks: chunks)
    }

    /// RAG 上下文增强：假设性文档生成 (HyDE)。
    /// 模拟生成包含回答线索的假设性文档，以此大幅提升向量匹配精准度。
    /// - Parameter query: 用户检索词。
    /// - Returns: 假设性文档正文内容。
    func generateHypotheticalDocument(query: String) async -> String {
        guard isEnabled, !apiKey.isEmpty, let retrievalService else { return query }
        return await retrievalService.generateHypotheticalDocument(query: query)
    }

    /// AI 模块连通性与响应测速测试。
    /// - Returns: 强类型验证结果，附带可用性和延迟毫秒数。
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

    // MARK: - 指标度量与合规记录

    /// 从响应荷载中解析计算 Token 消耗并异步记录至合规治理仓中。
    private func recordUsageIfPossible(response: [String: Any], latency: Int = 0) {
        guard let usage = response["usage"] as? [String: Any],
              let prompt = usage["prompt_tokens"] as? Int,
              let completion = usage["completion_tokens"] as? Int,
              let modelUsed = response["model"] as? String else { return }

        Task.detached(priority: .background) {
            let governance = ServiceContainer.shared.resolve((any GovernanceRepository).self)
            _ = try? await governance.logCall(model: modelUsed, promptTokens: prompt, completionTokens: completion, latencyMS: latency, status: AppConstants.Storage.defaultCallStatus)
            _ = try? await governance.logTokenUsage(model: modelUsed, promptTokens: prompt, completionTokens: completion)
        }
    }

    /// 异步且不在 UI 主线程挂载的归档 RAG 精准度元数据及自评估。
    private func asyncMetrics(query: String, response: String, context: String, systemPrompt: String, latency: Int) {
        let modelName = self.model
        Task.detached(priority: .background) {
            let governance = ServiceContainer.shared.resolve((any GovernanceRepository).self)
            let promptTokens = (systemPrompt.count + query.count) / BusinessConstants.AI.charactersPerToken
            let completionTokens = response.count / BusinessConstants.AI.charactersPerToken
            _ = try? await governance.logCall(model: modelName, promptTokens: promptTokens, completionTokens: completionTokens, latencyMS: latency, status: AppConstants.Storage.defaultCallStatus)
            _ = try? await governance.logTokenUsage(model: modelName, promptTokens: promptTokens, completionTokens: completionTokens)

            let evalService = ServiceContainer.shared.resolve(RAGEvaluationService.self)
            _ = await evalService.evaluate(query: query, answer: response, context: context)
        }
    }
}

// MARK: - 连通性支持子模型

extension LLMService {
    /// 代表大模型连通性检测响应的强类型实体 (ValidationResult)。
    struct ValidationResult {
        /// 连接是否畅通。
        let isSuccess: Bool
        /// 网关响应的总耗时（毫秒）。
        let latencyMS: Int
        /// 异常错误代码（如有）。
        let errorCode: String?
        /// 具体的错误解析文案。
        let errorMessage: String?
    }
}


