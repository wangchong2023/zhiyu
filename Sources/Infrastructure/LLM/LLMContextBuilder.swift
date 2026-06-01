//
//  LLMContextBuilder.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：属于 LLM 模块，提供相关的结构体或工具支撑。
//
import Foundation

// MARK: - LLM Context Builder
/// 构建系统提示词并为 LLM 查询检索相关知识库上下文。
final class LLMContextBuilder: Sendable {

    // MARK: - Configuration Constants
    /// Max entities listed in the system prompt overview.
    private static let maxEntityOverview = BusinessConstants.RAG.maxEntityOverview
    /// Max concepts listed in the system prompt overview.
    private static let maxConceptOverview = BusinessConstants.RAG.maxConceptOverview
    /// Max sources listed in the system prompt overview.
    private static let maxSourceOverview = BusinessConstants.RAG.maxSourceOverview
    /// Max recent pages shown in the system prompt overview.
    private static let maxRecentOverview = BusinessConstants.RAG.maxRecentOverview
    /// Content preview length per page in system prompt.
    private static let contentPreviewLength = BusinessConstants.RAG.contentPreviewLength
    /// Max pages included in the relevant context for a query.
    private static let maxContextPages = BusinessConstants.RAG.maxContextPages
    /// Content preview length per page in query context.
    private static let contextPreviewLength = BusinessConstants.RAG.contextPreviewLength

    // MARK: - System Prompt
    /// 构建SystemPrompt
    /// - Parameter pages: pages
    /// - Returns: 字符串
    func buildSystemPrompt(pages: [any KnowledgePageRepresentable]) -> String {
        var prompt = """
        \(L10n.AI.LLM.Prompt.role)

        \(L10n.Chat.welcomeDesc)：
        \(L10n.AI.LLM.Prompt.duty1)
        \(L10n.AI.LLM.Prompt.duty2)
        \(L10n.AI.LLM.Prompt.duty3)
        \(L10n.AI.LLM.Prompt.duty4)

        \(L10n.AI.LLM.Ingest.compileRules)
        \(L10n.AI.LLM.Prompt.rule1)
        \(L10n.AI.LLM.Prompt.rule2)
        \(L10n.AI.LLM.Prompt.rule3)
        \(L10n.AI.LLM.Prompt.rule4)

        \(L10n.AI.LLM.Prompt.overview)
        """

        // 总结知识库内容作为上下文
        let concretePages = pages.compactMap { $0 as? KnowledgePage }
        let activePages = concretePages.filter { $0.status == .active || $0.status == .stub }
        let totalPages = activePages.count
        let entities = activePages.filter { $0.pageType == .entity }
        let concepts = activePages.filter { $0.pageType == .concept }
        let sources = activePages.filter { $0.pageType == .source }

        prompt += "\n- \(L10n.AI.LLM.Prompt.totalPages): \(totalPages)"
        prompt += "\n- \(L10n.AI.LLM.Prompt.entityCount): \(entities.count), \(L10n.AI.LLM.Prompt.conceptCount): \(concepts.count), \(L10n.AI.LLM.Prompt.sourceCount): \(sources.count)"
        prompt += "\n\n\(L10n.AI.LLM.Prompt.entityList)"
        for entity in entities.prefix(Self.maxEntityOverview) {
            prompt += "\n- [[\(entity.title)]]: \(String(entity.content.prefix(Self.contentPreviewLength)))"
        }
        prompt += "\n\n\(L10n.AI.LLM.Prompt.conceptList)"
        for concept in concepts.prefix(Self.maxConceptOverview) {
            prompt += "\n- [[\(concept.title)]]: \(String(concept.content.prefix(Self.contentPreviewLength)))"
        }
        prompt += "\n\n\(L10n.AI.LLM.Prompt.sourceList)"
        for source in sources.prefix(Self.maxSourceOverview) {
            prompt += "\n- [[\(source.title)]]"
        }

        // Add recent changes
        let recent = activePages.sorted { $0.updatedAt > $1.updatedAt }.prefix(Self.maxRecentOverview)
        if !recent.isEmpty {
            prompt += "\n\n\(L10n.AI.LLM.Prompt.recentUpdates)"
            for page in recent {
                prompt += "\n- \(page.title) (\(page.updatedAt.formatted(.dateTime.month().day())))"
            }
        }

        return prompt
    }

    /// 使用多路召回 (Multi-Query) 和向量搜索获取高度相关的知识片段。
    /// - Returns: (格式化后的 Prompt 字符串, 提取出的信源数据对象列表)
    func buildRelevantContext(query: String) async -> (context: String, sources: [KnowledgeSource]) {
        let embeddingProvider = ServiceContainer.shared.resolve((any EmbeddingProvider).self)

        // 1. 执行多路召回
        let searchResults = await embeddingProvider.multiQuerySearch(query: query, topK: AppConfig.AI.topKResults)

        guard !searchResults.isEmpty else {
            return ("\(L10n.AI.LLM.Prompt.relevantPages)\n\(L10n.Common.Global.noData)\n", [])
        }

        // 2. 智能压缩逻辑 (Compression)
        let maxContextLength = AppConfig.AI.maxContextLength
        var currentLength = 0
        var compressedResults: [(chunk: PageChunk, score: Float)] = []

        for res in searchResults.sorted(by: { $0.score > $1.score }) {
            let chunkLen = res.chunk.content.count
            if currentLength + chunkLen > maxContextLength {
                if res.chunk.chunkType == "summary" || res.score > 0.8 {
                    compressedResults.append(res)
                    currentLength += chunkLen
                }
                if currentLength > maxContextLength + 500 { break } 
            } else {
                compressedResults.append(res)
                currentLength += chunkLen
            }
        }

        // 3. 聚合分块上下文并提取 Source 模型
        var context = "\(L10n.AI.LLM.Prompt.relevantPages)\n"
        var sources: [KnowledgeSource] = []
        let groupedResults = Dictionary(grouping: compressedResults) { $0.chunk.pageID }

        for (pageID, results) in groupedResults {
            let store = ServiceContainer.shared.resolve(KnowledgePageRepository.self)
            if let page = try? await store.fetch(id: pageID) {
                context += "\n---\n## \(page.title) [\(L10n.AI.LLM.Prompt.typeLabel): \(page.pageType.displayName)]\n"

                for (chunk, score) in results.sorted(by: { $0.score > $1.score }) {
                    let relevanceLabel = L10n.AI.Prompt.relevanceScore
                    let typeLabel = L10n.AI.Prompt.chunkType
                    context += "\n> [\(relevanceLabel): \(String(format: "%.4f", score)) | \(typeLabel): \(chunk.chunkType)]\n"
                    context += chunk.content
                    context += "\n"
                    
                    // 构建 Source 模型
                    sources.append(KnowledgeSource(
                        pageID: page.id,
                        title: page.title,
                        snippet: chunk.content,
                        anchorPath: chunk.anchorPath,
                        score: Double(score)
                    ))
                }
            }
        }

        return (context, sources)
    }

    // MARK: - Ingest Prompt Builder
    /// 构建导入摄取Prompt
    /// - Parameter title: title
    /// - Parameter rawContent: rawContent
    /// - Parameter pages: pages
    /// - Returns: 字符串
    func buildIngestPrompt(title: String, rawContent: String, pages: [any KnowledgePageRepresentable]) -> String {
        let existingTitles = pages.map(\.title).joined(separator: ", ")

        return """
        \(L10n.AI.LLM.Ingest.compileInstruction)

        \(L10n.AI.LLM.Ingest.compileRules)
        \(L10n.AI.LLM.Ingest.rule1)
        \(L10n.AI.LLM.Ingest.rule2)
        \(L10n.AI.LLM.Ingest.rule3)
        \(L10n.AI.LLM.Ingest.rule4)
        \(L10n.AI.LLM.Ingest.rule5)
        \(L10n.AI.LLM.Ingest.rule6)

        \(L10n.AI.LLM.Ingest.existingPages)：\(existingTitles)

        \(L10n.AI.LLM.Ingest.rawTitle)：\(title)

        \(L10n.AI.LLM.Ingest.rawContent)
        \(rawContent)

        ---
        ## 结构化规范 (Schema Rules)
        对于识别出的不同类型，请务必遵守以下内容结构和提取要求：

        1. **实体 (entity)**: 提取明确定义，列出核心属性。必须发现并建立与其他实体的双向链接。
        2. **概念 (concept)**: 重点解释底层原理和应用场景。内容要求高度概括且专业。

        请严格按照以下 JSON 格式输出结果：
        {
          "compiledContent": "\(L10n.AI.LLM.Ingest.jsonCompiledContent)",
          "suggestedTags": ["\(L10n.AI.LLM.Ingest.jsonSuggestedTags)1", "\(L10n.AI.LLM.Ingest.jsonSuggestedTags)2"],
          "suggestedType": "entity|concept|source|comparison|map",
          "relatedTitles": [],
          "summary": "\(L10n.AI.LLM.Ingest.jsonSummary)"
        }
        """
    }

    // MARK: - Query Rewrite Builder
    /// 构建RewritePrompt
    /// - Parameter query: query
    /// - Returns: 字符串
    func buildRewritePrompt(query: String) -> String {
        """
        \(L10n.AI.Prompt.QueryRewrite.instruction)
        \(L10n.AI.Prompt.QueryRewrite.rules)
        1. \(L10n.AI.Prompt.QueryRewrite.rule1)
        2. \(L10n.AI.Prompt.QueryRewrite.rule2)
        3. \(L10n.AI.Prompt.QueryRewrite.rule3)
        4. \(L10n.AI.Prompt.QueryRewrite.rule4)
        \(L10n.AI.Prompt.QueryRewrite.userQuery): \(query)
        \(L10n.AI.Prompt.QueryRewrite.footer)

        """
    }
}

// MARK: - Chat History Store
/// Manages chat message persistence with UserDefaults.
final class ChatHistoryStore: ObservableObject {
    var messages: [ChatMessageDTO] = []

    private let historyKey = "zhiyu_chat_history"

    init() {
        load()
    }

    /// 追加
    /// - Parameter message: message
    func append(_ message: ChatMessageDTO) {
        messages.append(message)
        persistToDisk()
    }

    /// 追加Batch
    /// - Parameter newMessages: newMessages
    func appendBatch(_ newMessages: [ChatMessageDTO]) {
        messages.append(contentsOf: newMessages)
        persistToDisk()
    }

    /// 清除
    func clear() {
        messages.removeAll()
        persistToDisk()
    }

    /// Explicitly persist current state to disk (public for external sync).
    func persistToDisk() {
        if let data = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    /// Returns the last N messages (typically for LLM context window).
    func recent(_ count: Int) -> ArraySlice<ChatMessageDTO> {
        messages.suffix(count)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let history = try? JSONDecoder().decode([ChatMessageDTO].self, from: data) {
            messages = history
        }
    }
}
