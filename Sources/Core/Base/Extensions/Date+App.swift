// Date+App.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：Date 扩展，提供统一的日期格式化 DSL，消除工程中的魔鬼字符串。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

extension Date {
    /// 预定义的 App 日期格式规范
    struct AppFormat {
        /// 标准日期：2026-05-15
        static let iso8601 = "yyyy-MM-dd"
        /// 详细时间：2026-05-15 14:30
        static let detailed = "yyyy-MM-dd HH:mm"
        /// 斜杠详细时间：2026/5/15 14:30
        static let slashDetailed = "yyyy/M/d HH:mm"
        /// 紧凑月份：5-15
        static let monthDay = "M-d"
        /// 纯年份：2026
        static let year = "yyyy"
    }
    
    /**
     * @description: 将日期格式化为指定的字符串
     * @param {String} format 日期格式字符串 (推荐使用 AppFormat 中的定义)
     * @return {String} 格式化后的字符串
     */
    func formatted(as format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
