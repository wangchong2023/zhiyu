// iOSReminderService.swift
//
// 作者: Wang Chong
// 功能说明: ReminderServiceProtocol 的 iOS/macOS 实现，基于 EventKit。
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
                throw NSError(domain: "ZhiYu.ReminderService", code: 404, userInfo: [NSLocalizedDescriptionKey: "找不到可用的提醒事项列表，请检查系统提醒事项 App 是否已启用。"])
            }
            reminder.calendar = firstCalendar
        }
        
        try eventStore.save(reminder, commit: true)
    }
}
#endif
