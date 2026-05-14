// ChatService.swift
//
// 作者: Wang Chong
// 功能说明: 聊天核心服务，负责对话历史持久化、日志记录及与 LLM 服务的通信。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
        let history = Array(historyStore.recent(AppConstants.AI.maxChatHistorySize))
        return llmService.chatStream(query: query, history: history, pages: pages)
    }
}
