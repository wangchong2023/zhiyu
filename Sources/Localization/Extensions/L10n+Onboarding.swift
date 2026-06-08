//
//  L10n+Onboarding.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 本地化层
//  核心职责：为 Onboarding 模块提供本地化强类型字符串的访问扩展。
//
import Foundation

extension L10n {
    public enum Onboarding {
        public static let t = "System"

        /// 本地化翻译
        /// - Parameter key: key
        /// - Returns: 返回值
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }

        /// 本地化格式化翻译
        /// - Parameter key: key
        /// - Parameter args: args
        /// - Returns: 返回值
        public static func trf(_ key: String, _ args: CVarArg...) -> String { Localized.trf(key, table: t, arguments: args) }

        public static var title: String { tr("welcome.title") }
        public static var subtitle: String { tr("welcome.subtitle") }
        public static var quickStart: String { tr("welcome.quickStart") }
        public static var growthTrend: String { tr("welcome.growthTrend") }

        public enum Guide {
            public static var title: String { Onboarding.tr("welcome.demo.title") }
            public static var desc: String { Onboarding.tr("welcome.demo.desc") }
            public static var createPage: String { Onboarding.tr("welcome.guide.createPage") }
            public static var knowledgeLink: String { Onboarding.tr("welcome.guide.knowledgeLink") }
        }

        public enum Demo {
            public static var title: String { Guide.title }
            public static var desc: String { Guide.desc }
        }

        public enum Stats {
            public static var totalPages: String { Onboarding.tr("welcome.stat.totalPages") }
            public static var entities: String { Onboarding.tr("welcome.stat.entities") }
            public static var concepts: String { Onboarding.tr("welcome.stat.concepts") }
            public static var sources: String { Onboarding.tr("welcome.stat.sources") }
        }

        public enum Step {
            public enum graph {
                public static var title: String { Onboarding.tr("onboarding.step.graph.title") }
                public static var desc: String { Onboarding.tr("onboarding.step.graph.desc") }
            }
            public enum aiLab {
                public static var title: String { Onboarding.tr("onboarding.step.aiLab.title") }
                public static var desc: String { Onboarding.tr("onboarding.step.aiLab.desc") }
            }
            public enum vault {
                public static var title: String { Onboarding.tr("onboarding.step.vault.title") }
                public static var desc: String { Onboarding.tr("onboarding.step.vault.desc") }
            }
        }

        public enum Action {
            public static var start: String { Onboarding.tr("onboarding.action.start") }
            public static var next: String { Onboarding.tr("onboarding.action.next") }
            public static var skip: String { Onboarding.tr("onboarding.action.skip") }
        }
    }
}