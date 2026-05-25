//
//  iOSReminderService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：实现 iOSReminder 模块的核心业务逻辑服务。
//
#if !os(watchOS)
import Foundation
import EventKit

/// iOS/macOS 提醒事项服务实现
final class iOSReminderService: ReminderServiceProtocol, @unchecked Sendable {
    private let eventStore = EKEventStore()
    
    /// 请求Access
    /// /// - Returns: 是否成功
    func requestAccess() async -> Bool {
        do {
            if #available(iOS 17.0, macOS 14.0, *) {
                return try await eventStore.requestFullAccessToReminders()
            } else {
                return try await eventStore.requestAccess(to: .reminder)
            }
        } catch {
            return false
        }
    }
    
    /// 创建Reminder
    /// /// - Parameter title: title
    /// /// - Parameter notes: notes
    func createReminder(title: String, notes: String) async throws {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.notes = notes
        // 优先使用默认日历，若不存在则尝试获取第一个可用的提醒事项日历
        if let calendar = eventStore.defaultCalendarForNewReminders() {
            reminder.calendar = calendar
        } else {
            let calendars = eventStore.calendars(for: .reminder)
            guard let firstCalendar = calendars.first else {
                // 将硬编码中文字符串替换为强类型多语言引用，防止 L10n 静态扫描泄露并保障 watchOS/iOS 的多语言统一
                throw NSError(domain: "ZhiYu.ReminderService", code: 404, userInfo: [NSLocalizedDescriptionKey: L10n.Reminder.noListAvailableMessage])
            }
            reminder.calendar = firstCalendar
        }
        
        try eventStore.save(reminder, commit: true)
    }
}
#endif
