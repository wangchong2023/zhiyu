// 功能说明: [Shared]
//
// L10n+Watch.swift
// 智宇 (ZhiYu) 多语言 Watch 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public struct Watch {
        public static let t = "Watch"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static var capture: String { tr("watch.capture") }
        public static var recents: String { Localized.tr("watch.recents", table: "Watch") }
        public static var dictateHint: String { Localized.tr("watch.dictate.hint", table: "Watch") }
        public static var widgetDisplayName: String { Localized.tr("watch.widget.displayName", table: "Watch") }
        public static var widgetDisplayDesc: String { Localized.tr("watch.widget.displayDesc", table: "Watch") }
    }
}
