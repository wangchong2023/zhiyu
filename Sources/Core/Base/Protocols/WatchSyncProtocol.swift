// WatchSyncProtocol.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：跨端通信（手机与手表）抽象协议。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Combine

/// 跨端通信协议
@MainActor
public protocol WatchSyncProtocol: ObservableObject, Sendable {
    /// 最近接收到的文本
    var lastReceivedText: String { get }
    
    /// 向配对设备发送内容
    func sendContent(_ text: String)
}

extension Notification.Name {
    /// 收到来自手表的同步内容通知
    public static let didReceiveWatchContent = Notification.Name("didReceiveWatchContent")
}
