// 功能说明: [Shared]
//
// L10n+Action.swift
// 智宇 (ZhiYu) 多语言 Action 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public struct Action {
        public static let t = "Common"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static var createPage: String { tr("action.createPage") }
        public static var createPageSubtitle: String { tr("action.createPageSubtitle") }
        public static var ingestKnowledge: String { tr("action.ingestKnowledge") }
        public static var ingestKnowledgeSubtitle: String { tr("action.ingestKnowledgeSubtitle") }

        public struct cmd {
            public static var deepExplore: String { Localized.tr("action.cmd.deepExplore", table: t) }
            public static var newKnowledgePage: String { Localized.tr("action.cmd.newKnowledgePage", table: t) }
            public static var quickActions: String { Localized.tr("action.cmd.quickActions", table: t) }
            public static var recentAccess: String { Localized.tr("action.cmd.recentAccess", table: t) }
        }
    }
}
