// LLMRefactorService.swift
//
// 作者: Wang Chong
// 功能说明: LLM 知识重构服务，处理潜在链接发现、内容自动折叠及知识库结构优化建议。
// MARK: [SR-02] 知识库自动化重构与语义链接优化
// 版本: 1.2
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// LLM 知识重构服务
/// 负责扫描知识库内容，通过语义分析建立双向链接并建议页面合并或拆分。
final class LLMRefactorService: Sendable {
    private let client: any LLMClientProtocol
    private let model: String

    init(client: any LLMClientProtocol, model: String) {
        self.client = client
        self.model = model
    }

    // MARK: - 链接发现 (Link Discovery)

    /// 扫描文本以发现潜在的内部链接建议
    func discoverPotentialLinks(content: String, existingTitles: [String]) async throws -> [String] {
        let prompt = """
        \(PromptService.shared.potentialLinksPrompt)

        现有页面标题列表：
        \(existingTitles.joined(separator: ", "))

        待分析文本：
        \"\"\"
        \(content)
        \"\"\"
        """

        let body: [String: Any] = [
            "model": model,
            "messages": [["role": "user", "content": prompt]],
            "temperature": 0.1,
            "max_tokens": 500
        ]

        let response = try await client.sendRequest(body: body)
        let responseContent = LLMUtils.extractContent(from: response) ?? ""
        return LLMUtils.parseJSONArray(responseContent)
    }

    // MARK: - 智能折叠 (Smart Folding)

    /// 增量折叠：将新资料合并至现有页面，避免重复
    func foldContent(existingContent: String, newContent: String, title: String) async throws -> String {
        let prompt = """
        \(PromptService.shared.foldingPrompt)

        现有页面内容：
        \(existingContent)

        新资料内容：
        \(newContent)
        """

        let body: [String: Any] = [
            "model": model,
            "messages": [["role": "user", "content": prompt]],
            "temperature": 0.2,
            "max_tokens": 2000
        ]

        let response = try await client.sendRequest(body: body)
        return LLMUtils.extractContent(from: response) ?? (existingContent + "\n\n" + newContent)
    }

    // MARK: - 架构重构建议

    /// 分析一组页面以获取重构建议（合并、拆分、重命名）
    func analyzeForRefactoring(pages: [KnowledgePage]) async throws -> [RefactorSuggestion] {
        let pageData = pages.map { "\($0.title): \($0.content.prefix(150))..." }.joined(separator: "\n---\n")

        let prompt = """
        \(PromptService.shared.refactorPrompt)

        页面简述列表：
        \(pageData)
        """

        let body: [String: Any] = [
            "model": model,
            "messages": [["role": "user", "content": prompt]],
            "temperature": AppConfig.AI.defaultTemperature,
            "max_tokens": 1000
        ]

        let response = try await client.sendRequest(body: body)
        let responseContent = LLMUtils.extractContent(from: response) ?? ""
        return LLMUtils.parseRefactorSuggestions(responseContent)
    }
}

// MARK: - 辅助模型

/// 重构建议模型
struct RefactorSuggestion: Codable, Identifiable {
    var id: String { target + type }
    let type: String // merge, split, rename
    let target: String
    let reason: String
    let suggestion: String
}
