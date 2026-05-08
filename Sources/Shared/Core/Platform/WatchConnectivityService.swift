// WatchConnectivityService.swift
//
// 作者: Wang Chong
// 功能说明: 跨端通信服务 (Shared across iOS & watchOS)
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
#if canImport(WatchConnectivity)
import WatchConnectivity
import Combine

/// 跨端通信服务 (Shared across iOS & watchOS)
@MainActor
final class WatchConnectivityService: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityService()
    
    @Published var lastReceivedText: String = ""
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    /// 将采集到的内容发送到配对设备
    func sendContent(_ text: String) {
        let session = WCSession.default
        
        // 1. 基础状态检查
        guard session.activationState == .activated else {
            Logger.shared.debug("⌚ [WatchSync] 传输中断：WCSession 尚未激活 (当前状态: \(session.activationState.rawValue))")
            return 
        }
        
        #if os(iOS)
        // 2. 配对状态检查 (仅 iOS)
        guard session.isPaired else {
            Logger.shared.debug("⌚ [WatchSync] 传输跳过：当前 iPhone 未配对 Apple Watch")
            return
        }
        
        guard session.isWatchAppInstalled else {
            Logger.shared.debug("⌚ [WatchSync] 传输跳过：配对的手表上未安装智宇 App")
            return
        }
        #endif
        
        // 使用 transferUserInfo 保证离线环境下的最终一致性
        let userInfo = ["type": "new_page", "content": text, "date": Date()] as [String : Any]
        session.transferUserInfo(userInfo)
        
        Logger.shared.debug("⌚ [WatchSync] 数据已入队等待传输：\(text.prefix(10))...")
    }
    
    // MARK: - WCSessionDelegate
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        #if os(iOS)
        let isPaired = session.isPaired
        #endif
        
        if let error = error {
            Task { @MainActor in
                Logger.shared.error("⌚ [WatchSync] WCSession 激活异常: \(error.localizedDescription)")
            }
        } else {
            Task { @MainActor in
                #if os(iOS)
                let status = isPaired ? "已配对" : "未配对"
                Logger.shared.debug("🚀 [WatchSync] WCSession 激活成功 (状态: \(activationState.rawValue), 硬件: \(status))")
                #else
                Logger.shared.debug("🚀 [WatchSync] WCSession 激活成功 (状态: \(activationState.rawValue))")
                #endif
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        if let content = userInfo["content"] as? String {
            Task { @MainActor in
                WatchConnectivityService.shared.lastReceivedText = content
                // 触发主 App 存储逻辑（由 AppStore 监听）
                NotificationCenter.default.post(name: .didReceiveWatchContent, object: content)
                Logger.shared.debug("⌚ [WatchSync] 收到来自手表的数据，已触发本地存储")
            }
        }
    }
    
    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate() // 重新激活
    }
    #endif
}

extension WatchConnectivityService: @unchecked Sendable {}
#endif

extension Notification.Name {
    static let didReceiveWatchContent = Notification.Name("didReceiveWatchContent")
}

