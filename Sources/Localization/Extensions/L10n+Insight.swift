//
//  L10n+Insight.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 本地化层
//  核心职责：为 Insight 模块提供本地化强类型字符串的访问扩展。
//
import Foundation

extension L10n {
    public enum Insight {
        public static let t = "Insight"

        /// 本地化翻译
        /// /// - Parameter key: key
        /// /// - Returns: 返回值
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }

        /// 本地化格式化翻译
        /// /// - Parameter key: key
        /// /// - Parameter args: args
        /// /// - Returns: 返回值
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

            /// node计数
            /// /// - Parameter count: 计数
            /// /// - Returns: 字符串
            public static func nodeCount(_ count: Int) -> String {
                Insight.trf("report.nodeCount", count)
            }
        }
    }
}
