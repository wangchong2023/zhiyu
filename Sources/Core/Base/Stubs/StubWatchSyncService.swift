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
    @Published var latestBriefing: String? = nil
    @Published var isBriefingLoading: Bool = false

    /// 发送Content
    /// - Parameter text: text
    func sendContent(_ text: String) {}
    
    /// 请求DailyBriefing
    func requestDailyBriefing() {}

    /// 处理BriefingResponse
    /// /// - Parameter text: text
    func handleBriefingResponse(_ text: String) {}
}
