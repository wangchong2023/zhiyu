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
    public struct Widget {
        public static let t = "Platform"

        /// 本地化翻译
        /// - Parameter key: key
        /// - Returns: 返回值
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static var title: String { Localized.tr("widget.title", table: t) }
        public static var pages: String { Localized.tr("widget.pages", table: t) }
        public static var words: String { Localized.tr("widget.words", table: t) }
        public static var active: String { Localized.tr("widget.active", table: t) }
        public static var characters: String { Localized.tr("widget.characters", table: t) }
        public static var recentUpdates: String { Localized.tr("widget.recentUpdates", table: t) }
        public static var stub: String { Localized.tr("widget.stub", table: t) }
        public static var knowledgeCompile: String { Localized.tr("widget.knowledgeCompile", table: t) }
        public static var aiChat: String { Localized.tr("widget.aiChat", table: t) }
        public static var search: String { Localized.tr("widget.search", table: t) }
        public static var links: String { Localized.tr("widget.links", table: t) }
        public static var tags: String { Localized.tr("widget.tags", table: t) }
        public static var vaultName: String { Localized.tr("widget.vaultName", table: t) }
        public static var ai: String { Localized.tr("widget.ai", table: t) }

        /// pages
        /// - Parameter n: n
        /// - Returns: 字符串
        public static func pages(_ n: Int) -> String { Localized.trf("pagesCount", table: t, n) }
    }
}