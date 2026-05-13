// iOSWatchSyncService.swift
//
// 作者: Wang Chong
// 功能说明: WatchSyncProtocol 的 iOS 实现。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
    
    func sendContent(_ text: String) {
        let session = WCSession.default
        guard session.activationState == .activated, session.isPaired, session.isWatchAppInstalled else {
            return 
        }
        let userInfo = ["type": "new_page", "content": text, "date": Date()] as [String : Any]
        session.transferUserInfo(userInfo)
    }
    
    // MARK: - WCSessionDelegate
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            Logger.shared.error("⌚ [WatchSync] iOS 激活异常: \(error.localizedDescription)")
        }
    }
    
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
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

extension iOSWatchSyncService: @unchecked Sendable {}
#endif
