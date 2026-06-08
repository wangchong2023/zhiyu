//
//  LLMAIServicesTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 LLMAIServices 开展自动化单元测试验证。
//
import XCTest
@testable import ZhiYu

// MARK: - Mock LLM Client
final class MockLLMClient: LLMClientProtocol, @unchecked Sendable {
    var mockResponse: [String: Any] = [:]
    var mockError: Error?
    var lastBody: [String: Any]?

    func sendRequest(body: [String: Any]) async throws -> [String: Any] {
        lastBody = body
        if let error = mockError { throw error }
        return mockResponse
    }

    func sendStreamingRequest(body: [String: Any]) async throws -> URLSession.AsyncBytes {
        fatalError("Not implemented")
    }
}

final class LLMAIServicesTests: XCTestCase {
    
    var mockClient: MockLLMClient!
    var contextBuilder: LLMContextBuilder!
    
    override func setUp() {
        super.setUp()
        mockClient = MockLLMClient()
        contextBuilder = LLMContextBuilder()
    }
    
    // MARK: - Ingest Service Tests
    
    func testSmartIngest() async throws {
        let service = LLMIngestService(client: mockClient, model: "gpt-4o", contextBuilder: contextBuilder)
        
        // 模拟 AI 返回的结构化 JSON
        let jsonResponse = """
        {
            "compiled_content": "Compiled content",
            "suggested_tags": ["tag1", "tag2"],
            "suggested_type": "concept",
            "related_titles": ["Rel1"],
            "summary": "Summary text"
        }
        """
        mockClient.mockResponse = [
            "choices": [[
                "message": ["content": jsonResponse]
            ]]
        ]
        
        let result = try await service.smartIngest(title: "Test", rawContent: "Raw", pages: [])
        
        XCTAssertEqual(result.compiledContent, "Compiled content")
        XCTAssertEqual(result.suggestedTags, ["tag1", "tag2"])
        XCTAssertEqual(result.summary, "Summary text")
    }
    
    // MARK: - Retrieval Service Tests
    
    func testRewriteQuery() async {
        let service = LLMRetrievalService(client: mockClient, model: "gpt-4o", contextBuilder: contextBuilder)
        
        mockClient.mockResponse = [
            "choices": [[
                "message": ["content": "Optimized Query"]
            ]]
        ]
        
        let rewritten = await service.rewriteQuery("Natural query")
        XCTAssertEqual(rewritten, "Optimized Query")
    }
    
    func testRerank() async throws {
        let service = LLMRetrievalService(client: mockClient, model: "gpt-4o", contextBuilder: contextBuilder)
        
        let page1 = KnowledgePage(title: "Page 1", pageType: .concept, content: "C1")
        let page2 = KnowledgePage(title: "Page 2", pageType: .concept, content: "C2")
        let candidates = [page1, page2]
        
        // 模拟返回排序后的 ID 数组
        mockClient.mockResponse = [
            "choices": [[
                "message": ["content": "[\"\(page2.id.uuidString)\", \"\(page1.id.uuidString)\"]"]
            ]]
        ]
        
        let ranked = try await service.rerank(query: "Test", candidates: candidates)
        
        XCTAssertEqual(ranked.first?.id, page2.id)
        XCTAssertEqual(ranked.last?.id, page1.id)
    }
    
    // MARK: - Refactor Service Tests
    
    func testDiscoverPotentialLinks() async throws {
        let service = LLMRefactorService(client: mockClient, model: "gpt-4o")
        
        mockClient.mockResponse = [
            "choices": [[
                "message": ["content": "[\"Link1\", \"Link2\"]"]
            ]]
        ]
        
        let links = try await service.discoverPotentialLinks(content: "Content", existingTitles: ["Link1", "Link2"])
        XCTAssertEqual(links, ["Link1", "Link2"])
    }
}
