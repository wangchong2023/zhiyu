// 功能说明: [Shared]
//
// L10n+Accessibility.swift
// 智宇 (ZhiYu) 多语言 Accessibility 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public struct Accessibility: Sendable {
        public static let t = "Common"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static var tags: String { Localized.tr("accessibility.tags", table: t) }
        public static var words: String { Localized.tr("accessibility.words", table: t) }
        public static var links: String { Localized.tr("accessibility.links", table: t) }
        public static var tapToOpen: String { Localized.tr("accessibility.tapToOpen", table: t) }
    }
}
