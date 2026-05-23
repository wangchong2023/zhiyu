//
//  WatchWatchSyncService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：实现 WatchWatchSync 模块的核心业务逻辑服务。
//
#if os(watchOS)
import Foundation
import WatchConnectivity
import Combine

/// watchOS 端同步实现
final class WatchWatchSyncService: NSObject, WatchSyncProtocol, WCSessionDelegate {
    @Published var lastReceivedText: String = ""
    
    #if DEBUG
    /// 仅限单元测试模拟使用的激活状态插桩，绕过模拟器测试时 session 激活受限的问题
    var mockActivationState: WCSessionActivationState? = nil
    #endif
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    /// 将文字笔记数据发送给配对的 iPhone 宿主
    /// - Parameter text: 待同步的文本内容
    func sendContent(_ text: String) {
        let session = WCSession.default
        #if DEBUG
        let activationState = mockActivationState ?? session.activationState
        #else
        let activationState = session.activationState
        #endif
        guard activationState == .activated else { return }
        let userInfo = ["type": "new_page", "content": text, "date": Date()] as [String : Any]
        session.transferUserInfo(userInfo)
    }
    
    // MARK: - WCSessionDelegate
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            Logger.shared.error("⌚ [WatchSync] watchOS activation anomaly: \(error.localizedDescription)")
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        if let content = userInfo["content"] as? String {
            Task { @MainActor in
                self.lastReceivedText = content
                NotificationCenter.default.post(name: .didReceiveWatchContent, object: content)
            }
        }
    }
}

extension WatchWatchSyncService: @unchecked Sendable {}
#endif
