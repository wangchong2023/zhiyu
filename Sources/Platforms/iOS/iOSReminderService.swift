// iOSReminderService.swift
//
// 作者: Wang Chong
// 功能说明: [Shared] 平台特有桥接实现，基于 EventKit 的提醒事项服务封装。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

#if !os(watchOS)
import Foundation
import EventKit

/// iOS/macOS 提醒事项服务实现
final class iOSReminderService: ReminderServiceProtocol, @unchecked Sendable {
    private let eventStore = EKEventStore()
    
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
