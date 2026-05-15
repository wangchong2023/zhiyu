// UnsupportedReminderService.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：ReminderServiceProtocol 的不支持平台占位实现。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
