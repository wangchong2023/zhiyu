//
//  AISynthesisServiceTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/11.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 AISynthesisService 的纯逻辑及边界条件开展单元测试。
//

import XCTest
@testable import ZhiYu

final class AISynthesisServicePureLogicTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        await MainActor.run {
            ServiceContainer.shared.reset()
            // AISynthesisService.shared.init 会 resolve(LLMServiceProtocol.self)，
            // 需要注册 mock 避免 fatalError
            let mockLLM = MockFullLLMService()
            ServiceContainer.shared.register(mockLLM as any LLMServiceProtocol, for: (any LLMServiceProtocol).self)
        }
    }

    override func tearDown() async throws {
        await MainActor.run {
            ServiceContainer.shared.reset()
        }
        try await super.tearDown()
    }

    // MARK: - generateInsightfulQuestions 空输入防护

    @MainActor
    func testGenerateInsightfulQuestions_emptyPages() throws {
        let expectation = XCTestExpectation()
        let service = AISynthesisService.shared
        let test = Task {
            let result = try await service.generateInsightfulQuestions(pages: [])
            XCTAssertTrue(result.isEmpty, "空页面列表应返回空数组")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
        test.cancel()
    }
}

/// 最小化 LLMServiceProtocol 实现，仅用于避免 AISynthesisService.shared 初始化崩溃
@MainActor
private final class MockFullLLMService: LLMServiceProtocol {
    var isEnabled: Bool = false
    var provider: LLMProvider = .custom
    var apiKey: String = ""
    var baseURL: String = ""
    var model: String = ""
    var autoScan: Bool = false
    var autoRefactor: Bool = false

    func chat(query: String, history: [ChatMessageDTO], pages: [any KnowledgePageRepresentable]) async throws -> ChatMessageDTO {
        ChatMessageDTO(role: .assistant, content: "")
    }
    func chatStream(query: String, history: [ChatMessageDTO], pages: [any KnowledgePageRepresentable]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { $0.finish() }
    }
    func generate(prompt: String, systemPrompt: String, maxTokens: Int) async throws -> String { "" }
    func smartIngest(title: String, rawContent: String, pages: [any KnowledgePageRepresentable]) async throws -> SmartIngestResultDTO {
        SmartIngestResultDTO(title: "", compiledContent: "", suggestedTags: [], suggestedType: "", relatedTitles: [], summary: "")
    }
    func discoverPotentialLinks(content: String, existingTitles: [String]) async throws -> [String] { [] }
    func foldContent(existingContent: String, newContent: String, title: String) async throws -> String { "" }
    func analyzeForRefactoring(pages: [any KnowledgePageRepresentable]) async throws -> [RefactorSuggestionDTO] { [] }
    func rewriteQuery(_ query: String) async -> String { query }
    func expandQuery(_ query: String) async -> [String] { [query] }
    func rerank(query: String, candidates: [any KnowledgePageRepresentable]) async throws -> [any KnowledgePageRepresentable] { candidates }
    func rerankChunks(query: String, chunks: [PageChunk]) async -> [PageChunk] { chunks }
    func generateHypotheticalDocument(query: String) async -> String { query }
}
