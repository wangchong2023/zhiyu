// 功能说明: [Shared]
//
// L10n+Log.swift
// 智宇 (ZhiYu) 多语言 Log 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public struct Log {
        public static let t = "Common"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static var noLogs: String { tr("log.noLogs") }
        public static var clearConfirmTitle: String { tr("log.clearConfirmTitle") }
        public static var startTime: String { tr("log.startTime") }
        public static var endTime: String { tr("log.endTime") }
        public static var duration: String { tr("log.duration") }
        public static var failureReason: String { tr("log.failureReason") }
    }
}
