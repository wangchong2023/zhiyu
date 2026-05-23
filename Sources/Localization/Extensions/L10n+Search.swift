//
//  L10n+Search.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 本地化层
//  核心职责：为 Search 模块提供本地化强类型字符串的访问扩展。
//
import Foundation

extension L10n {
    public enum Search {
        public static let t = "Common"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static func trf(_ key: String, _ args: CVarArg...) -> String { Localized.trf(key, table: t, arguments: args) }

        public static var base: String { Search.tr("search") }
        public static var title: String { Search.tr("search.title") }
        public static var all: String { Search.tr("search.all") }
        public static var noResults: String { Search.tr("search.noResults") }
        public static var noResultsHint: String { Search.tr("search.noResultsHint") }

        public static func resultsCount(_ count: Int) -> String { Search.trf("search.resultsCount", count) }
        public static func pagesCount(_ count: Int) -> String { Search.trf("search.pagesCount", count) }

        public static var Diagnostics: String { diagnostics }
        public static var diagnostics: String { Search.tr("search.diagnostics") }

        public enum Diag {
            public static var title: String { Search.tr("search.diag.title") }
            public static var rewrite: String { Search.tr("search.diag.rewrite") }
            public static var originalQuery: String { Search.tr("search.diag.originalQuery") }
            public static var rewrittenQuery: String { Search.tr("search.diag.rewrittenQuery") }
            public static var rrfDetail: String { Search.tr("search.diag.rrfDetail") }
            public static var ftsRank: String { Search.tr("search.diag.ftsRank") }
            public static var vectorRank: String { Search.tr("search.diag.vectorRank") }
            public static var miss: String { Search.tr("search.diag.miss") }
            public static var scoreFormat: String { Search.tr("search.diag.scoreFormat") }
        }
    }
}
