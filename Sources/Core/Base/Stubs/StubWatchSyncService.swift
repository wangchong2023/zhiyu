// StubWatchSyncService.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：WatchSyncProtocol 的空实现，用于不支持该框架的平台 (如 macOS)。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Combine

final class StubWatchSyncService: NSObject, WatchSyncProtocol {
    @Published var lastReceivedText: String = ""
    func sendContent(_ text: String) {}
}
