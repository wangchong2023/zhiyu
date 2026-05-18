// 功能说明: [Shared]
//
// L10n+Knowledge.swift
// 智宇 (ZhiYu) 多语言 Knowledge 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public enum Knowledge {
        public static let t = "Knowledge"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static func trf(_ key: String, _ args: CVarArg...) -> String { Localized.trf(key, table: t, arguments: args) }

        public enum Page {
            public static var title: String { Knowledge.tr("page.title") }
            public static var edit: String { Knowledge.tr("page.edit") }
            public static var doneEditing: String { Knowledge.tr("page.doneEditing") }
            public static var deletePage: String { Knowledge.tr("page.deletePage") }
            public static var delete: String { Knowledge.tr("page.deletePage") }
            public static var confirmDelete: String { Knowledge.tr("page.confirmDelete") }
            public static var deleteMessage: String { Knowledge.tr("page.deleteMessage") }
            public static var icon: String { Knowledge.tr("page.icon") }
            public static var knowledge: String { Knowledge.tr("page.knowledge") }
            public static var empty: String { Knowledge.tr("page.empty") }
            public static var emptyHint: String { Knowledge.tr("page.emptyHint") }
            public static var status: String { Knowledge.tr("page.status") }
            public static var metaInfo: String { Knowledge.tr("page.metaInfo") }
            public static var expandStub: String { Knowledge.tr("page.expandStub") }
            public static var findLinks: String { Knowledge.tr("page.findLinks") }
            public static var pin: String { Knowledge.tr("page.pin") }
            public static var unpin: String { Knowledge.tr("page.unpin") }
            public static var wordCountUnit: String { Knowledge.tr("page.wordCountUnit") }
            public static var outLinkUnit: String { Knowledge.tr("page.outLinkUnit") }
            public static var noBackLinks: String { Knowledge.tr("page.noBackLinks") }
            public static var doubleTapToNavigate: String { Knowledge.tr("page.doubleTapToNavigate") }
            public static var backlinks: String { Knowledge.tr("page.backlinks") }

            public static func deletePageTitle(_ name: String) -> String { Knowledge.trf("page.deletePageTitle", name) }
            public static func backlinkAccessibility(_ title: String, _ type: String) -> String { Knowledge.trf("page.backlinkAccessibility", title, type) }
            public static func titleAccessibility(_ title: String) -> String { Knowledge.trf("page.titleAccessibility", title) }
            public static func createdAtFormat(_ date: String) -> String { Knowledge.trf("page.createdAtFormat", date) }
            public static func updatedAtFormat(_ date: String) -> String { Knowledge.trf("page.updatedAtFormat", date) }
            public static func wordCount(_ count: Int) -> String { Knowledge.trf("page.wordCount", count) }
            public static func outLinksCount(_ count: Int) -> String { Knowledge.trf("page.outLinksCount", count) }
            public static func metaAccessibility(_ date: String, _ words: Int, _ links: Int) -> String { Knowledge.trf("page.metaAccessibility", date, words, links) }
            public static func pageTypeAccessibility(_ type: String) -> String { Knowledge.trf("page.pageTypeAccessibility", type) }
            public static func statusAccessibility(_ status: String) -> String { Knowledge.trf("page.statusAccessibility", status) }
            public static func confidenceAccessibility(_ confidence: String) -> String { Knowledge.trf("page.confidenceAccessibility", confidence) }

            public struct AIInsightsVal {
                public let title: String
                init(title: String) { self.title = title }
            }
            public static var aiInsights: AIInsightsVal { AIInsightsVal(title: Knowledge.tr("page.aiInsights")) }

            public enum Source {
                public static var title: String { Knowledge.tr("page.source.title") }
                public static var open: String { Knowledge.tr("page.source.open") }
            }

            public enum AI {
                public static var insights: String { Knowledge.tr("page.aiInsights") }
                public static var insightsDesc: String { Knowledge.tr("page.aiInsights.desc") }
                public static var summary: String { Knowledge.tr("page.ai.summary") }
                public static var extractActions: String { Knowledge.tr("page.ai.extractActions") }
                public static var mindmap: String { Knowledge.tr("page.ai.mindmap") }
                public static var quiz: String { Knowledge.tr("page.ai.quiz") }
                public static var slides: String { Knowledge.tr("page.ai.slides") }
                public static var report: String { Knowledge.tr("page.ai.report") }
                public static var infographic: String { Knowledge.tr("page.ai.infographic") }
                public static var lab: String { Knowledge.tr("page.ai.lab") }
                public static var expansion: String { Knowledge.tr("page.ai.expansion") }
                public static var labOutput: String { Knowledge.tr("page.ai.labOutput") }
            }

            public enum History {
                public static var title: String { Knowledge.tr("page.history") }
                public static var none: String { Knowledge.tr("page.history.none") }
                public static var manual: String { Knowledge.tr("page.history.manual") }
                public static var physical: String { Knowledge.tr("page.history.physical") }
                public static var version: String { Knowledge.tr("page.history.version") }
                public static var rollback: String { Knowledge.tr("page.history.rollback") }
            }

            public enum Snapshot {
                public static var preview: String { Knowledge.tr("page.snapshot.preview") }
            }
        }
    }
}
