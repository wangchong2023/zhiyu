//
//  Date+Extensions.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：属于 Extensions 模块，提供相关的结构体或工具支撑。
//
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
            if day == 1 { return L10n.Common.yesterday }
            return formatter.localizedString(from: components)
        }
        
        if let hour = components.hour, hour > 0 {
            return formatter.localizedString(from: components)
        }
        
        if let minute = components.minute, minute > 0 {
            return formatter.localizedString(from: components)
        }
        
        return L10n.Common.justNow
    }
}
