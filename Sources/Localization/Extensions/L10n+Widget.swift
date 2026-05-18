// 功能说明: [Shared]
//
// L10n+Widget.swift
// 智宇 (ZhiYu) 多语言 Widget 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public struct Widget {
        public static let t = "Platform"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static var title: String { Localized.tr("widget.title", table: t) }
        public static var pages: String { Localized.tr("widget.pages", table: t) }
        public static var words: String { Localized.tr("widget.words", table: t) }
        public static var active: String { Localized.tr("widget.active", table: t) }
        public static var characters: String { Localized.tr("widget.characters", table: t) }
        public static var recentUpdates: String { Localized.tr("widget.recentUpdates", table: t) }
        public static var stub: String { Localized.tr("widget.stub", table: t) }
        public static var knowledgeCompile: String { Localized.tr("widget.knowledgeCompile", table: t) }
        public static func pages(_ n: Int) -> String { Localized.trf("pagesCount", table: t, n) }
    }
}
