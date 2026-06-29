//
//  L10n+Widget.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 本地化层
//  核心职责：为 Widget 模块提供本地化强类型字符串的访问扩展。
//
import Foundation

extension L10n {
    public struct Widget: L10nTableEntry {
        public static let tableName = "Platform"
        public static var t: String { tableName }
        /// 本地化翻译
        /// - Parameter key: key
        /// - Returns: 返回值
        public static var title: String { Localized.tr("widget.title", table: t) }
        public static var pages: String { L10n.Common.tr("perf.pages") }
        public static var words: String { L10n.Common.tr("accessibility.words") }
        public static var active: String { L10n.Common.tr("status.active") }
        public static var characters: String { Localized.tr("widget.characters", table: t) }
        public static var recentUpdates: String { L10n.Common.tr("recentUpdates") }
        public static var stub: String { L10n.Common.tr("status.stub") }
        public static var knowledgeCompile: String { Localized.tr("widget.knowledgeCompile", table: t) }
        public static var aiChat: String { L10n.Common.tr("tab.chat") }
        public static var search: String { L10n.Common.tr("components.search") }
        public static var links: String { L10n.Common.tr("accessibility.links") }
        public static var tags: String { L10n.Common.tr("accessibility.tags") }
        public static var vaultName: String { Localized.tr("widget.vaultName", table: t) }
        public static var ai: String { Localized.tr("widget.ai", table: t) }

        /// pages
        /// - Parameter n: n
        /// - Returns: 字符串
        public static func pages(_ n: Int) -> String { Localized.trf("pagesCount", table: t, n) }
    }
}
