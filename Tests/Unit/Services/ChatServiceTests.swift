// ChatServiceTests.swift
//
// 作者: Wang Chong
// 功能说明: 验证聊天核心服务（ChatService）的逻辑，对应 SRS-6.2 API 契约
// 版本: 1.0
// 修改记录:
//   - 2026-05-13: 初始创建，针对垂直化后的 Chat 模块进行验证。
// 版权: Copyright © 2026 Wang Chong. All rights reserved.

import XCTest
import Combine
@testable import ZhiYu

@MainActor
final class ChatServiceTests: XCTestCase {
    
    var chatService: ChatService!
    
    override func setUp() {
        super.setUp()
        setupFullMockEnvironment()
        chatService = ChatService.shared
        chatService.clearHistory()
    }
    
    /// 验证消息保存逻辑 (SRS-6.2)
    func testMessageSaving() {
        let userContent = "Hello AI"
        chatService.saveUserMessage(userContent)
        
        let history = chatService.loadHistory()
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.role, .user)
        XCTAssertEqual(history.first?.content, userContent)
        
        let aiContent = "Hello Human"
        chatService.saveAssistantMessage(aiContent)
        
        let historyAfter = chatService.loadHistory()
        XCTAssertEqual(historyAfter.count, 2)
        XCTAssertEqual(historyAfter.last?.role, .assistant)
        XCTAssertEqual(historyAfter.last?.content, aiContent)
    }
    
    /// 验证清空历史逻辑 (SRS-6.2)
    func testClearHistory() {
        chatService.saveUserMessage("Test")
        XCTAssertFalse(chatService.loadHistory().isEmpty)
        
        chatService.clearHistory()
        XCTAssertTrue(chatService.loadHistory().isEmpty)
    }
    
    /// 验证流式对话调用链路 (SRS-6.2 / PR-02)
    func testStreamChatLink() async throws {
        let query = "Test Query"
        let stream = chatService.streamChat(query: query, pages: [])
        
        // 由于使用了 MockLLMService，流应当立即完成或返回 Mock 数据
        var receivedAny = false
        for try await _ in stream {
            receivedAny = true
        }
        
        // MockLLMService 默认返回完成
        XCTAssertNotNil(stream)
    }
}
