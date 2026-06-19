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

    /// 验证当传入空页面列表时，AI 合成服务应返回空数组而不抛出异常。
    /// 使用原生 async/await 测试，避免在 @MainActor 上阻塞主线程（防止死锁与 SIGABRT）。
    @MainActor
    func testGenerateInsightfulQuestions_emptyPages() async throws {
        let service = AISynthesisService.shared
        // 直接 await，Swift 6 结构化并发下安全可靠
        let result = try await service.generateInsightfulQuestions(pages: [])
        XCTAssertTrue(result.isEmpty, "空页面列表应返回空数组")
    }

    // MARK: - predictFollowUpQuestions 后续提问预测测试

    /// 验证当历史记录为空时，应直接返回空数组而不用请求大模型。
    @MainActor
    func testPredictFollowUpQuestions_emptyHistory() async throws {
        let service = AISynthesisService.shared
        let result = try await service.predictFollowUpQuestions(history: [], pages: [])
        XCTAssertTrue(result.isEmpty, "空历史记录应直接返回空数组")
    }

    /// 验证当 LLM 正常返回标准的 JSON 数组时，能正确解析出推荐问题。
    @MainActor
    func testPredictFollowUpQuestions_success() async throws {
        let service = AISynthesisService.shared
        
        // 配置 Mock 返回 3 个预测问题的 JSON
        if let mockLLM = ServiceContainer.shared.resolve((any LLMServiceProtocol).self) as? MockFullLLMService {
            mockLLM.generateResult = "[\"后续问题一\", \"后续问题二\", \"后续问题三\"]"
        }
        
        let history = [
            ChatMessage(role: .user, content: "你好"),
            ChatMessage(role: .assistant, content: "你好！有什么我可以帮你的吗？")
        ]
        
        let result = try await service.predictFollowUpQuestions(history: history, pages: [])
        XCTAssertEqual(result.count, 3, "应该返回 3 个预测的问题")
        XCTAssertEqual(result[0], "后续问题一")
        XCTAssertEqual(result[1], "后续问题二")
        XCTAssertEqual(result[2], "后续问题三")
    }

    /// 验证当 LLM 返回非规范的 JSON 或其他错误文本时，能优雅防护并返回空数组。
    @MainActor
    func testPredictFollowUpQuestions_fallback() async throws {
        let service = AISynthesisService.shared
        
        // 配置 Mock 返回非法 JSON
        if let mockLLM = ServiceContainer.shared.resolve((any LLMServiceProtocol).self) as? MockFullLLMService {
            mockLLM.generateResult = "This is not a JSON array"
        }
        
        let history = [
            ChatMessage(role: .user, content: "你好")
        ]
        
        let result = try await service.predictFollowUpQuestions(history: history, pages: [])
        XCTAssertTrue(result.isEmpty, "解析失败时应该优雅返回空数组")
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
    
    // 支持动态注入的模拟结果
    var generateResult: String = ""

    func chat(query: String, history: [ChatMessageDTO], pages: [any KnowledgePageRepresentable]) async throws -> ChatMessageDTO {
        ChatMessageDTO(role: .assistant, content: "")
    }
    func chatStream(query: String, history: [ChatMessageDTO], pages: [any KnowledgePageRepresentable]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { $0.finish() }
    }
    func generate(prompt: String, systemPrompt: String, maxTokens: Int) async throws -> String { generateResult }
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
