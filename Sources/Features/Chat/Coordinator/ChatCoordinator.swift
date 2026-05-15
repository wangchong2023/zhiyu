// ChatCoordinator.swift
//
// 作者: Wang Chong
// 功能说明: 聊天功能协调器，负责 ChatView 的业务编排、消息流管理及 UI 交互状态。
// 版本: 1.1
// 修改记录:
//   - 2026-05-15: 从 ChatViewModel 演进为 Coordinator，整合 UI 交互状态（导出、选择模式、错误处理）。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI
import Observation
import Combine

@MainActor
@Observable
final class ChatCoordinator {
    // ── 业务数据状态 ──
    var inputText = ""
    var insightfulQuestions: [String] = []
    var chatHistory: [ChatMessage] = []
    var isProcessing = false
    var streamingContent = ""
    
    // ── UI 交互状态 ──
    var isExporting = false
    var errorMessage: String?
    var showError = false
    var isGeneratingAIQuestions = false
    var showPrompts = false
    var exportURL: IdentifiableURL?
    var isSelectionMode = false
    var selectedMessageIDs: Set<UUID> = []

    @ObservationIgnored @Inject private var aiSynthesis: (any AISynthesisServiceProtocol)
    @ObservationIgnored @Inject private var chatService: (any ChatServiceProtocol)
    @ObservationIgnored @Inject private var llmService: LLMService
    @ObservationIgnored @Inject private var logger: any LoggerProtocol
    @ObservationIgnored @Inject private var perf: PerformanceService

    init() {
        self.chatHistory = ServiceContainer.shared.resolve((any ChatServiceProtocol).self).loadHistory()
    }

    // ── 业务动作 ──

    func loadInsightfulQuestions(pages: [KnowledgePage]) async {
        guard !pages.isEmpty && llmService.isEnabled && insightfulQuestions.isEmpty else { return }
        
        isGeneratingAIQuestions = true
        do {
            insightfulQuestions = try await aiSynthesis.generateInsightfulQuestions(pages: pages)
        } catch {
            insightfulQuestions = []
        }
        isGeneratingAIQuestions = false
    }

    func sendMessage(query: String? = nil, pages: [KnowledgePage]) async {
        let text = (query ?? inputText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        if isProcessing {
            cancelCurrentRequest()
            return
        }
        
        if query == nil { inputText = "" }
        errorMessage = nil
        
        // 1. 保存并展示用户消息
        chatService.saveUserMessage(text)
        self.chatHistory.append(ChatMessage(role: .user, content: text))
        
        self.isProcessing = true
        self.streamingContent = ""
        
        do {
            _ = try await perf.measureAsync("chatStreamDelay") {
                let stream = chatService.streamChat(query: text, pages: pages)
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
            if case LLMError.notConfigured = error {
                // UI banner handles this, no need for alert
            } else {
                errorMessage = error.localizedDescription
                showError = true
                logger.error("❌ [ChatCoordinator] 对话发生错误", error: error)
            }
        }
    }

    func cancelCurrentRequest() {
        isProcessing = false
    }

    func clearChatHistory() {
        chatService.clearHistory()
        chatHistory.removeAll()
    }

    func exportChat() async {
        let history = isSelectionMode && !selectedMessageIDs.isEmpty ?
            chatHistory.filter { selectedMessageIDs.contains($0.id) } :
            chatHistory
            
        guard !history.isEmpty else { return }
        
        isExporting = true
        do {
            let md: String = history.map { msg in
                let role = msg.role == .user ? "You" : "AI"
                return "## \(role)\n\n\(msg.content)"
            }.joined(separator: "\n\n---\n\n")

            let url = try await WebViewExportService.shared.exportToPDF(markdown: md, fileName: "Chat_Export")
            self.exportURL = IdentifiableURL(url: url)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isExporting = false
    }

    func toggleSelectionMode() {
        withAnimation {
            isSelectionMode.toggle()
            if !isSelectionMode {
                selectedMessageIDs.removeAll()
            }
        }
    }

    func toggleMessageSelection(_ id: UUID) {
        if selectedMessageIDs.contains(id) {
            selectedMessageIDs.remove(id)
        } else {
            selectedMessageIDs.insert(id)
        }
        HapticFeedback.shared.trigger(.selection)
    }
}
