// WatchWatchSyncService.swift
//
// 作者: Wang Chong
// 功能说明: WatchSyncProtocol 的 watchOS 实现。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

#if os(watchOS)
import Foundation
import WatchConnectivity
import Combine

/// watchOS 端同步实现
final class WatchWatchSyncService: NSObject, WatchSyncProtocol, WCSessionDelegate {
    @Published var lastReceivedText: String = ""
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func sendContent(_ text: String) {
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        let userInfo = ["type": "new_page", "content": text, "date": Date()] as [String : Any]
        session.transferUserInfo(userInfo)
    }
    
    // MARK: - WCSessionDelegate
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            Logger.shared.error("⌚ [WatchSync] watchOS 激活异常: \(error.localizedDescription)")
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
