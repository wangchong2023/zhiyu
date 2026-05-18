// 功能说明: [Shared]
//
// L10n+Components.swift
// 智宇 (ZhiYu) 多语言 Components 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public struct Components {
        public static let t = "Common"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static var noOutgoing: String { tr("components.noOutgoing") }
        public static var noBackLinks: String { tr("components.noBackLinks") }
        public static var search: String { tr("components.search") }
    }
}
