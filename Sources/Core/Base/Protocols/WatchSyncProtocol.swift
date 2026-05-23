//
//  WatchSyncProtocol.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：定义 WatchSync 模块的抽象契约接口。
//
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
