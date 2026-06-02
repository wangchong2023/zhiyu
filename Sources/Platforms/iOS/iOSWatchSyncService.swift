//
//  iOSWatchSyncService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：实现 iOSWatchSync 模块的核心业务逻辑服务。
//
#if os(iOS) && !os(watchOS)
import Foundation
import WatchConnectivity
import Combine

/// iOS 端手表同步实现
final class iOSWatchSyncService: NSObject, WatchSyncProtocol, WCSessionDelegate {
    @Published var lastReceivedText: String = ""
    @Published var latestBriefing: String? = nil
    @Published var isBriefingLoading: Bool = false
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    /// 发送Content
    /// - Parameter text: text
    func sendContent(_ text: String) {
        let session = WCSession.default
        guard session.activationState == .activated else {
            Logger.shared.warning("WatchSync_Error1")
            return
        }
        guard session.isPaired else {
            Logger.shared.warning("WatchSync_Error2")
            return
        }
        guard session.isWatchAppInstalled else {
            Logger.shared.warning("WatchSync_Error3")
            return
        }
        
        let userInfo = ["type": "new_page", "content": text, "date": Date()] as [String : Any]
        session.transferUserInfo(userInfo)
        Logger.shared.info("WatchSync_Success")
    }
    
    /// 请求DailyBriefing
    func requestDailyBriefing() {
        // iOS 宿主端通常不主动请求，此接口预留
    }
    
    /// 处理BriefingResponse
    /// /// - Parameter text: text
    func handleBriefingResponse(_ text: String) {
        // iOS 宿主端不处理响应
    }
    
    /// 响应手表的简报请求，生成并推送
    private func generateAndSendBriefing() {
        Task {
            do {
                guard let appStore = ServiceContainer.shared.resolveOptional(AppStore.self),
                      let llmService = ServiceContainer.shared.resolveOptional((any LLMServiceProtocol).self) else {
                    return
                }
                
                // 1. 获取最近 24 小时的活跃页面
                let pages = await appStore.pages
                let recentPages = pages.filter { $0.updatedAt > Date().addingTimeInterval(-24 * 60 * 60) }.prefix(5)
                
                guard !recentPages.isEmpty else {
                    sendBriefingToWatch(content: "今天没有新的知识录入，去放松一下吧。")
                    return
                }
                
                // 2. 聚合并使用 LLM 生成简报
                let combinedContent = recentPages.map { "- \($0.title): \($0.content.prefix(100))" }.joined(separator: "\n")
                let prompt = """
                根据以下最近录入的笔记，生成一段简短、口语化、适合用语音播报的每日知识简报。
                要求：去除所有 Markdown 标记，使用自然语言的转折词，像一位知识管家在对我说话。
                内容：
                \(combinedContent)
                """
                let briefing = try await llmService.generate(prompt: prompt, systemPrompt: "你是一个专业的知识管理语音播报员。")
                
                // 3. 推送回手表
                sendBriefingToWatch(content: briefing)
                
            } catch {
                Logger.shared.error("Briefing Generation Failed: \(error)")
                sendBriefingToWatch(content: "生成简报失败，请检查网络或模型设置。")
            }
        }
    }
    
    private func sendBriefingToWatch(content: String) {
        let session = WCSession.default
        guard session.activationState == .activated && session.isPaired && session.isWatchAppInstalled else {
            return
        }
        let userInfo = ["type": "briefing_response", "content": content] as [String : Any]
        session.transferUserInfo(userInfo)
    }
    
    // MARK: - WCSessionDelegate
    
    /// session回调
    /// - Parameter session: session
    /// - Parameter error: error
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            Logger.shared.error("WatchSync_Anomaly")
        }
    }
    
    /// sessionDidBecomeInactive回调
    /// - Parameter session: session
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    /// sessionDid停用回调
    /// - Parameter session: session
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    
    /// session回调
    /// - Parameter session: session
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        if let type = userInfo["type"] as? String {
            if type == "request_briefing" {
                Task { @MainActor in
                    self.generateAndSendBriefing()
                }
            } else if type == "new_page", let content = userInfo["content"] as? String {
                Task { @MainActor in
                    self.lastReceivedText = content
                    NotificationCenter.default.post(name: .didReceiveWatchContent, object: content)
                }
            }
        } else if let content = userInfo["content"] as? String {
            Task { @MainActor in
                self.lastReceivedText = content
                NotificationCenter.default.post(name: .didReceiveWatchContent, object: content)
            }
        }
    }
}

extension iOSWatchSyncService: @unchecked Sendable {}
#endif
