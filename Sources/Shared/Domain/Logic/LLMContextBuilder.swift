// LLMContextBuilder.swift
//
// 作者: Wang Chong
// 功能说明: 构建系统提示词并为 LLM 查询检索相关知识库上下文。
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
//   - 更新: 2026-05-04
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

// MARK: - LLM Context Builder
/// 构建系统提示词并为 LLM 查询检索相关知识库上下文。
final class LLMContextBuilder: Sendable {

    // MARK: - Configuration Constants
    /// Max entities listed in the system prompt overview.
    private static let maxEntityOverview = AppConstants.RAG.maxEntityOverview
    /// Max concepts listed in the system prompt overview.
    private static let maxConceptOverview = AppConstants.RAG.maxConceptOverview
    /// Max sources listed in the system prompt overview.
    private static let maxSourceOverview = AppConstants.RAG.maxSourceOverview
    /// Max recent pages shown in the system prompt overview.
    private static let maxRecentOverview = AppConstants.RAG.maxRecentOverview
    /// Content preview length per page in system prompt.
    private static let contentPreviewLength = AppConstants.RAG.contentPreviewLength
    /// Max pages included in the relevant context for a query.
    private static let maxContextPages = AppConstants.RAG.maxContextPages
    /// Content preview length per page in query context.
    private static let contextPreviewLength = AppConstants.RAG.contextPreviewLength

    // MARK: - System Prompt
    func buildSystemPrompt(pages: [KnowledgePage]) -> String {
        var prompt = """
        \(Localized.tr("llm.prompt.role"))

        \(L10n.Chat.tr("welcomeDesc"))：
        \(Localized.tr("llm.prompt.duty1"))
        \(Localized.tr("llm.prompt.duty2"))
        \(Localized.tr("llm.prompt.duty3"))
        \(Localized.tr("llm.prompt.duty4"))

        \(Localized.tr("ingest.compileRules"))
        \(Localized.tr("llm.prompt.rule1"))
        \(Localized.tr("llm.prompt.rule2"))
        \(Localized.tr("llm.prompt.rule3"))
        \(Localized.tr("llm.prompt.rule4"))

        \(Localized.tr("llm.prompt.overview"))
        """

        // 总结知识库内容作为上下文
        let activePages = pages.filter { $0.status == .active || $0.status == .stub }
        let totalPages = activePages.count
        let entities = activePages.filter { $0.type == .entity }
        let concepts = activePages.filter { $0.type == .concept }
        let sources = activePages.filter { $0.type == .source }

        prompt += "\n- \(Localized.tr("llm.prompt.totalPages")): \(totalPages)"
        prompt += "\n- \(Localized.tr("llm.prompt.entityCount")): \(entities.count), \(Localized.tr("llm.prompt.conceptCount")): \(concepts.count), \(Localized.tr("llm.prompt.sourceCount")): \(sources.count)"
        prompt += "\n\n\(Localized.tr("llm.prompt.entityList"))"
        for entity in entities.prefix(Self.maxEntityOverview) {
            prompt += "\n- [[\(entity.title)]]: \(String(entity.content.prefix(Self.contentPreviewLength)))"
        }
        prompt += "\n\n\(Localized.tr("llm.prompt.conceptList"))"
        for concept in concepts.prefix(Self.maxConceptOverview) {
            prompt += "\n- [[\(concept.title)]]: \(String(concept.content.prefix(Self.contentPreviewLength)))"
        }
        prompt += "\n\n\(Localized.tr("llm.prompt.sourceList"))"
        for source in sources.prefix(Self.maxSourceOverview) {
            prompt += "\n- [[\(source.title)]]"
        }

        // Add recent changes
        let recent = activePages.sorted { $0.updated > $1.updated }.prefix(Self.maxRecentOverview)
        if !recent.isEmpty {
            prompt += "\n\n\(Localized.tr("llm.prompt.recentUpdates"))"
            for page in recent {
                prompt += "\n- \(page.title) (\(page.updated.formatted(.dateTime.month().day())))"
            }
        }

        return prompt
    }

    /// 使用多路召回 (Multi-Query) 和向量搜索获取高度相关的知识片段。
    func buildRelevantContext(query: String) async -> String {
        let embeddingManager = ServiceContainer.shared.resolve(EmbeddingManager.self)

        // 1. 执行多路召回
        let searchResults = await embeddingManager.multiQuerySearch(query: query, topK: AppConfig.AI.topKResults)

        guard !searchResults.isEmpty else {
            return "\(Localized.tr("llm.prompt.relevantPages"))\n\(Localized.tr("common.noData"))\n"
        }

        // 2. 智能压缩逻辑 (Compression)
        // 如果分块过多导致上下文过长，则优先使用摘要分块或执行截断
        let maxContextLength = AppConfig.AI.maxContextLength
        var currentLength = 0
        var compressedResults: [(chunk: PageChunk, score: Float)] = []

        for res in searchResults.sorted(by: { $0.score > $1.score }) {
            let chunkLen = res.chunk.content.count
            if currentLength + chunkLen > maxContextLength {
                // 如果已经太长了，只保留摘要或高度相关的短句
                if res.chunk.chunkType == "summary" || res.score > 0.8 {
                    compressedResults.append(res)
                    currentLength += chunkLen
                }
                if currentLength > maxContextLength + 500 { break } // 彻底封顶
            } else {
                compressedResults.append(res)
                currentLength += chunkLen
            }
        }

        // 3. 聚合分块上下文
        var context = "\(Localized.tr("llm.prompt.relevantPages"))\n"
        let groupedResults = Dictionary(grouping: compressedResults) { $0.chunk.pageID }

        for (pageID, results) in groupedResults {
            let store = ServiceContainer.shared.resolve(KnowledgePageStore.self)
            if let page = try? store.fetchByID(pageID) {
                context += "\n---\n## \(page.title) [\(Localized.tr("llm.prompt.typeLabel")): \(page.type.displayName)]\n"

                for (chunk, score) in results.sorted(by: { $0.score > $1.score }) {
                    context += "\n> [相关度: \(String(format: "%.4f", score)) | 类型: \(chunk.chunkType)]\n"
                    context += chunk.content
                    context += "\n"
                }
            }
        }

        return context
    }

    // MARK: - Ingest Prompt Builder
    func buildIngestPrompt(title: String, rawContent: String, pages: [KnowledgePage]) -> String {
        let existingTitles = pages.map(\.title).joined(separator: ", ")

        return """
        \(Localized.tr("llm.ingest.compileInstruction"))

        \(Localized.tr("llm.ingest.compileRules"))
        \(Localized.tr("llm.ingest.rule1"))
        \(Localized.tr("llm.ingest.rule2"))
        \(Localized.tr("llm.ingest.rule3"))
        \(Localized.tr("llm.ingest.rule4"))
        \(Localized.tr("llm.ingest.rule5"))
        \(Localized.tr("llm.ingest.rule6"))

        \(Localized.tr("llm.ingest.existingPages"))：\(existingTitles)

        \(Localized.tr("llm.ingest.rawTitle"))：\(title)

        \(Localized.tr("llm.ingest.rawContent"))
        \(rawContent)

        ---
        ## 结构化规范 (Schema Rules)
        对于识别出的不同类型，请务必遵守以下内容结构和提取要求：

        1. **实体 (entity)**: 提取明确定义，列出核心属性。必须发现并建立与其他实体的双向链接。
        2. **概念 (concept)**: 重点解释底层原理和应用场景。内容要求高度概括且专业。

        请严格按照以下 JSON 格式输出结果：
        {
          "compiledContent": "\(Localized.tr("llm.ingest.jsonCompiledContent"))",
          "suggestedTags": ["\(Localized.tr("llm.ingest.jsonSuggestedTags"))1", "\(Localized.tr("llm.ingest.jsonSuggestedTags"))2"],
          "suggestedType": "entity|concept|source|comparison|map",
          "relatedTitles": [],
          "summary": "\(Localized.tr("llm.ingest.jsonSummary"))"
        }
        """
    }

    // MARK: - Query Rewrite Builder
    func buildRewritePrompt(query: String) -> String {
        """
        \(Localized.tr("prompt.queryRewrite.instruction"))

        \(Localized.tr("prompt.queryRewrite.rules"))
        1. \(Localized.tr("prompt.queryRewrite.rule1"))
        2. \(Localized.tr("prompt.queryRewrite.rule2"))
        3. \(Localized.tr("prompt.queryRewrite.rule3"))
        4. \(Localized.tr("prompt.queryRewrite.rule4"))

        \(Localized.tr("prompt.queryRewrite.userQuery")): \(query)

        \(Localized.tr("prompt.queryRewrite.footer"))
        """
    }
}

// MARK: - Chat History Store
/// Manages chat message persistence with UserDefaults.
final class ChatHistoryStore: ObservableObject {
    var messages: [ChatMessage] = []

    private let historyKey = "zhiyu_chat_history"

    init() {
        load()
    }

    func append(_ message: ChatMessage) {
        messages.append(message)
        persistToDisk()
    }

    func appendBatch(_ newMessages: [ChatMessage]) {
        messages.append(contentsOf: newMessages)
        persistToDisk()
    }

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
    func recent(_ count: Int) -> ArraySlice<ChatMessage> {
        messages.suffix(count)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let history = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            messages = history
        }
    }
}
