//
//  UnsupportedReminderService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：实现 UnsupportedReminder 模块的核心业务逻辑服务。
//
import Foundation

/// 不支持提醒事项的平台实现
final class UnsupportedReminderService: ReminderServiceProtocol, Sendable {
    func requestAccess() async -> Bool {
        return false
    }
    
    func createReminder(title: String, notes: String) async throws {
        // Do nothing or throw error
    }
}
