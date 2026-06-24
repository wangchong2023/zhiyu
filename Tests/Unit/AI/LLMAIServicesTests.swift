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
    
    // MARK: - LLMConfigStore 调试降级测试
    
    /// 测试在调试环境下，如果 Keychain 异常，LLMConfigStore 是否能够通过 UserDefaults 降级方案成功保存并读取 API 密钥
    @MainActor
    func testLLMConfigStoreFallback() throws {
        // 1. 构造一个临时的测试提供商与测试密钥
        let testProvider = LLMProvider.deepSeek
        let testKey = "sk-test-fallback-key-123456"
        
        // 清理可能残留的测试数据
        let fallbackKey = "zhiyu_llm_api_key_fallback_\(testProvider.rawValue)"
        UserDefaults.standard.removeObject(forKey: fallbackKey)
        
        // 2. 实例化配置存储库
        let store = LLMConfigStore()
        store.provider = testProvider
        
        // 3. 设定测试 API 密钥，由于在单元测试中（DEBUG 下运行），这会自动写入 UserDefaults 备份
        store.apiKey = testKey
        
        // 验证内存状态是否更新
        XCTAssertEqual(store.apiKey, testKey, "内存中的 API 密钥应立即更新")
        
        // 验证本地 UserDefaults 中是否已有该降级备份且是安全加密密文
        let backupValue = UserDefaults.standard.string(forKey: fallbackKey)
        XCTAssertNotNil(backupValue, "UserDefaults 中应有该降级备份")
        XCTAssertNotEqual(backupValue, testKey, "备份应被安全加密以防泄露，不应是明文")
        if let encrypted = backupValue {
            let decrypted = try SecurityManager.shared.decrypt(encrypted)
            XCTAssertEqual(decrypted, testKey, "降级备份解密还原后应与原始 Key 完全一致")
        }
        
        // 4. 重新实例化一个全新的 LLMConfigStore，模拟 App 重启
        let secondStore = LLMConfigStore()
        secondStore.provider = testProvider
        
        // 验证其读取出来的 apiKey 是否正是我们备份的测试密钥
        XCTAssertEqual(secondStore.apiKey, testKey, "重新实例化后的 LLMConfigStore 应能通过降级机制成功恢复 API 密钥")
        
        // 5. 测试清空密钥的行为
        store.apiKey = ""
        XCTAssertNil(UserDefaults.standard.string(forKey: fallbackKey), "清空密钥后，降级备份也应该被清除")
    }
}
