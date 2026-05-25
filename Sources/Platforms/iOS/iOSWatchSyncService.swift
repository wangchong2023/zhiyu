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
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    /// 发送Content
    /// /// - Parameter text: text
    func sendContent(_ text: String) {
        let session = WCSession.default
        guard session.activationState == .activated else {
            Logger.shared.warning("⌚ [WatchSync] Send failed: WCSession not active (current state: \(session.activationState.rawValue))")
            return
        }
        guard session.isPaired else {
            Logger.shared.warning("⌚ [WatchSync] Send failed: Apple Watch not paired")
            return
        }
        guard session.isWatchAppInstalled else {
            Logger.shared.warning("⌚ [WatchSync] Send failed: Watch App not installed")
            return
        }
        
        let userInfo = ["type": "new_page", "content": text, "date": Date()] as [String : Any]
        session.transferUserInfo(userInfo)
        Logger.shared.info("⌚ [WatchSync] Content sent to Watch via UserInfo (length: \(text.count))")
    }
    
    // MARK: - WCSessionDelegate
    
    /// session回调
    /// /// - Parameter session: session
    /// /// - Parameter error: error
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            Logger.shared.error("⌚ [WatchSync] iOS activation anomaly: \(error.localizedDescription)")
        }
    }
    
    /// sessionDidBecomeInactive回调
    /// /// - Parameter session: session
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    /// sessionDid停用回调
    /// /// - Parameter session: session
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    
    /// session回调
    /// /// - Parameter session: session
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        if let content = userInfo["content"] as? String {
            Task { @MainActor in
                self.lastReceivedText = content
                NotificationCenter.default.post(name: .didReceiveWatchContent, object: content)
            }
        }
    }
}

extension iOSWatchSyncService: @unchecked Sendable {}
#endif
