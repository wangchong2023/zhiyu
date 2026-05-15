// ReminderServiceProtocol.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：提醒事项服务抽象协议，用于解耦 EventKit 平台依赖。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 提醒事项服务协议
public protocol ReminderServiceProtocol: Sendable {
    /// 请求提醒事项访问权限
    func requestAccess() async -> Bool
    
    /// 创建单条提醒事项
    /// - Parameters:
    ///   - title: 标题
    ///   - notes: 备注
    func createReminder(title: String, notes: String) async throws
}
