//
//  ChatService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：实现 Chat 模块的核心业务逻辑服务。
//
import Foundation

@MainActor
final class ChatService: ChatServiceProtocol, @unchecked Sendable {
    static let shared = ChatService()
    
    private let historyStore = ChatHistoryStore()
    
    init() {}
    
    func loadHistory() -> [ChatMessage] {
        return historyStore.messages
    }
    
    func clearHistory() {
        historyStore.clear()
    }
    
    func saveUserMessage(_ content: String) {
        historyStore.append(ChatMessage(role: .user, content: content))
    }
    
    func saveAssistantMessage(_ content: String) {
        historyStore.append(ChatMessage(role: .assistant, content: content))
        historyStore.persistToDisk()
    }
    
    func streamChat(query: String, pages: [KnowledgePage]) -> AsyncThrowingStream<String, Error> {
        let llmService = ServiceContainer.shared.resolve((any LLMServiceProtocol).self)
        let logger = ServiceContainer.shared.resolve((any LoggerProtocol).self)
        
        logger.debug("🗣️ [ChatService] 开始构建对话上下文与流式请求: \(query)")
        let history = Array(historyStore.recent(BusinessConstants.AI.maxChatHistorySize))
        return llmService.chatStream(query: query, history: history, pages: pages)
    }
}
