// 功能说明: [Shared]
//
// L10n+Creation.swift
// 智宇 (ZhiYu) 多语言 Creation 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public struct Creation {
        public static let t = "Creation"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static var entityTemplate: String { tr("template.entity") }
        public static var conceptTemplate: String { tr("template.concept") }
        public static var comparisonTemplate: String { tr("template.comparison") }
        public static var customIcon: String { tr("customIcon") }
        public static var newPage: String { tr("newPage") }
        public static var basicInfo: String { tr("basicInfo") }
        public static var pageTitle: String { tr("pageTitle") }
        public static var pageType: String { tr("pageType") }

        public static var title: String { Localized.tr("create.title") }
        public static var tagsPlaceholder: String { Localized.tr("create.tagsPlaceholder") }
        public static var create: String { Localized.tr("create.create") }
        public static var content: String { Localized.tr("create.content") }
        public static var quickTemplates: String { Localized.tr("create.quickTemplates") }

        public struct template {
            public struct entity {
                public static var overview: String { Localized.tr("create.template.entity.overview") }
                public static var overviewPlaceholder: String { Localized.tr("create.template.entity.overviewPlaceholder") }
                public static var contributions: String { Localized.tr("create.template.entity.contributions") }
                public static var contributionsPlaceholder: String { Localized.tr("create.template.entity.contributionsPlaceholder") }
                public static var related: String { Localized.tr("create.template.entity.related") }
                public static var relatedPlaceholder: String { Localized.tr("create.template.entity.relatedPlaceholder") }
            }
            public struct concept {
                public static var definition: String { Localized.tr("create.template.concept.definition") }
                public static var definitionPlaceholder: String { Localized.tr("create.template.concept.definitionPlaceholder") }
                public static var analysis: String { Localized.tr("create.template.concept.analysis") }
                public static var analysisPlaceholder: String { Localized.tr("create.template.concept.analysisPlaceholder") }
                public static var links: String { Localized.tr("create.template.concept.links") }
                public static var linksPlaceholder: String { Localized.tr("create.template.concept.linksPlaceholder") }
            }
            public struct comparison {
                public static var suffix: String { Localized.tr("create.template.comparison.suffix") }
                public static var dimensions: String { Localized.tr("create.template.comparison.dimensions") }
                public static var dimensionsPlaceholder: String { Localized.tr("create.template.comparison.dimensionsPlaceholder") }
                public static var conclusion: String { Localized.tr("create.template.comparison.conclusion") }
                public static var conclusionPlaceholder: String { Localized.tr("create.template.comparison.conclusionPlaceholder") }
            }
        }
    }
}
