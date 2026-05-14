// Chat视图模型.swift
//
// 作者: Wang Chong
// 功能说明: Chat视图模型.swift
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-04
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI
import Observation

@MainActor
@Observable
final class ChatViewModel {
    var inputText = ""
    var insightfulQuestions: [String] = []

    var chatHistory: [ChatMessage] = []
    var isProcessing = false
    var streamingContent = ""
    var currentTask: Task<Void, Never>? = nil

    @ObservationIgnored @Inject private var aiSynthesis: (any AISynthesisServiceProtocol)
    @ObservationIgnored @Inject private var chatService: (any ChatServiceProtocol)

    init() {
        self.chatHistory = ServiceContainer.shared.resolve((any ChatServiceProtocol).self).loadHistory()
    }

    func loadInsightfulQuestions(pages: [KnowledgePage]) async {
        do {
            insightfulQuestions = try await aiSynthesis.generateInsightfulQuestions(pages: pages)
        } catch {
            insightfulQuestions = []
        }
    }

    func sendChatMessage(query: String, pages: [KnowledgePage]) async throws {
        guard !query.isEmpty else { return }
        
        chatService.saveUserMessage(query)
        self.chatHistory.append(ChatMessage(role: .user, content: query))
        
        self.isProcessing = true
        self.streamingContent = ""
        self.inputText = ""
        
        let logger = ServiceContainer.shared.resolve((any LoggerProtocol).self)
        let perf = ServiceContainer.shared.resolve(PerformanceService.self)
        
        do {
            _ = try await perf.measureAsync("chatStreamDelay") {
                let stream = chatService.streamChat(query: query, pages: pages)
                for try await chunk in stream {
                    if !self.isProcessing { break }
                    self.streamingContent += chunk
                }
            }
            
            if self.isProcessing {
                chatService.saveAssistantMessage(self.streamingContent)
                self.chatHistory.append(ChatMessage(role: .assistant, content: self.streamingContent))
            }
            self.isProcessing = false
        } catch {
            self.isProcessing = false
            logger.error("❌ [ChatViewModel] 对话发生错误", error: error)
            throw error
        }
    }

    func cancelCurrentRequest() {
        isProcessing = false
    }

    func clearChatHistory() {
        chatService.clearHistory()
        chatHistory.removeAll()
    }

    func exportChat(history: [ChatMessage]) async throws -> URL {
        let md: String = history.map { msg in
            let role = msg.role == .user ? "You" : "AI"
            return "## \(role)\n\n\(msg.content)"
        }.joined(separator: "\n\n---\n\n")

        return try await WebViewExportService.shared.exportToPDF(markdown: md, fileName: "Chat_Export")
    }
}
