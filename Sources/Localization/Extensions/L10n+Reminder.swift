// 功能说明: [Shared]
//
// L10n+Reminder.swift
// 智宇 (ZhiYu) 多语言 Reminder 垂直切片强类型扩展定义
//
// 作者: Wang Chong
// 功能说明: 提供系统级提醒服务的强类型多语言接口，映射至 "System" 表。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

extension L10n {
    /// 提醒事项服务多语言强类型扩展
    public enum Reminder {
        public static let t = "System"
        
        /// 获取带表名映射的翻译
        /// - Parameter key: 多语言键值
        /// - Returns: 翻译文案
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }

        /// 找不到可用的提醒事项列表错误提示
        public static var noListAvailableMessage: String { tr("reminder.noListAvailableMessage") }
    }
}
