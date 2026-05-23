//
//  StubWatchSyncService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：实现 StubWatchSync 模块的核心业务逻辑服务。
//
import Foundation
import Combine

final class StubWatchSyncService: NSObject, WatchSyncProtocol {
    @Published var lastReceivedText: String = ""
    func sendContent(_ text: String) {}
}
