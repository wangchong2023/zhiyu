// IngestQueueTests.swift
//
// 作者: Wang Chong
// 功能说明: 边界与异常测试 (Expert QA Item #4)
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
// 日期: 2026-05-04
// 版权: Copyright © 2026 Wang Chong. All rights reserved.

import XCTest
import Combine
@testable import ZhiYu

/// 边界与异常测试 (Expert QA Item #4)
/// 模拟极端环境下的 IngestQueue 表现。
@MainActor
final class IngestQueueTests: XCTestCase {
    var store: AppStore!
    var llmService: MockLLMService!
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() async throws {
        try await super.setUp()
        store = AppStore()
        llmService = MockLLMService()
        cancellables = []
    }
    
    /// 模拟异步处理流程中的状态流转
    func testQueueProcessingStatusFlow() async throws {
        let queue = IngestQueue.shared
        let dummyContent = "Test Content"
        
        let expectation = expectation(description: "Queue should finish processing")
        
        // 观察 isProcessing 变化
        queue.$isProcessing
            .dropFirst()
            .sink { isProcessing in
                if !isProcessing { expectation.fulfill() }
            }
            .store(in: &cancellables)
        
        // 2. 压入任务
        queue.enqueue(
            title: "BoundaryTest",
            content: dummyContent,
            llmService: llmService,
            pages: [],
            onResult: { _ in }
        )
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        // 3. 验证队列状态已重置
        XCTAssertFalse(queue.isProcessing, "即便完成任务，队列也必须重置状态")
        XCTAssertEqual(queue.pendingCount, 0, "计数器必须归零")
    }
}

// MARK: - Mock Helpers
final class MockLLMService: LLMServiceProtocol, @unchecked Sendable {
    var objectWillChange = ObservableObjectPublisher()
    var isProcessing: Bool = false
    var isEnabled: Bool = true
    
    func chat(query: String, pages: [KnowledgePage]) async throws -> ChatMessage {
        return ChatMessage(role: .assistant, content: "Mock")
    }
    func chatStream(query: String, pages: [KnowledgePage]) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { _ in }
    }
    func generate(prompt: String, systemPrompt: String) async throws -> String {
        return "Mock"
    }
    func smartIngest(title: String, rawContent: String, pages: [KnowledgePage]) async throws -> SmartIngestResult {
        return SmartIngestResult(
            compiledContent: "Mock",
            suggestedTags: ["Mock"],
            suggestedType: "Mock",
            relatedTitles: [],
            summary: "Mock"
        )
    }
    func discoverPotentialLinks(content: String, existingTitles: [String]) async throws -> [String] {
        return []
    }
    func foldContent(existingContent: String, newContent: String, title: String) async throws -> String {
        return "Mock"
    }
    func analyzeForRefactoring(pages: [KnowledgePage]) async throws -> [RefactorSuggestion] {
        return []
    }
    func rewriteQuery(_ query: String) async -> String {
        return query
    }
    func rerank(query: String, candidates: [KnowledgePage]) async throws -> [KnowledgePage] {
        return candidates
    }
}
