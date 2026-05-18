// 功能说明: [Shared]
//
// L10n+Insight.swift
// 智宇 (ZhiYu) 多语言 Insight 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public enum Insight {
        public static let t = "Insight"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static func trf(_ key: String, _ args: CVarArg...) -> String { Localized.trf(key, table: t, arguments: args) }

        public enum Weekly {
            public static var aiAnalysis: String { Insight.tr("weekly.aiAnalysis") }
        }

        public enum InsightSection {
            public enum Daily {
                public static var noUpdate: String { Insight.tr("insight.daily.noUpdate") }
                public static var systemPrompt: String { Insight.tr("insight.daily.systemPrompt") }
            }
            public enum Weekly {
                public static var systemPrompt: String { Insight.tr("insight.weekly.systemPrompt") }
            }
        }

        public enum Medal {
            public static var totalEarned: String { Insight.tr("medal.totalEarned") }
            public static var progress: String { Insight.tr("medal.progress") }
            public static var congrats: String { Insight.tr("medal.congrats") }

            public enum Category {
                public static var explore: String { Insight.tr("medal.category.explore") }
                public static var accumulation: String { Insight.tr("medal.category.accumulation") }
                public static var connection: String { Insight.tr("medal.category.connection") }
            }

            public enum Wall {
                public static var title: String { Insight.tr("medal.wall.title") }
            }
        }

        public enum Report {
            public static var title: String { Insight.tr("report.title") }
            public static var appName: String { Insight.tr("report.appName") }
            public static var footer: String { Insight.tr("report.footer") }

            public static func nodeCount(_ count: Int) -> String {
                Insight.trf("report.nodeCount", count)
            }
        }
    }
}
