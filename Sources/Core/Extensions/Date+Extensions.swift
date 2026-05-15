// Date+Extensions.swift
//
// 作者: Wang Chong
// 功能说明: Date 类型的实用扩展，支持语义化时间显示。
// 核心原则：
// 1. 本地化：优先使用系统 Locale。
// 2. 语义化：根据时间跨度自动切换显示格式。

import Foundation

extension Date {
    /// 返回语义化的相对时间字符串 (例如: "刚刚", "5 分钟前", "2 小时前")
    public func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale.current
        
        let now = Date()
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self, to: now)
        
        if let year = components.year, year > 0 {
            return formatter.localizedString(from: components)
        }
        
        if let month = components.month, month > 0 {
            return formatter.localizedString(from: components)
        }
        
        if let day = components.day, day > 0 {
            if day == 1 { return Localized.tr("date.yesterday", table: "Common") }
            return formatter.localizedString(from: components)
        }
        
        if let hour = components.hour, hour > 0 {
            return formatter.localizedString(from: components)
        }
        
        if let minute = components.minute, minute > 0 {
            return formatter.localizedString(from: components)
        }
        
        return Localized.tr("date.justNow", table: "Common")
    }
}
