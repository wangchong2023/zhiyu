// 功能说明: [Shared]
//
// L10n+Lint.swift
// 智宇 (ZhiYu) 多语言 Lint 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public struct Lint {
        public static let t = "Lint"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static var title: String { tr("title") }
        public static var refactorSection: String { tr("refactorSection") }
        public static var linkDiscoverySection: String { tr("linkDiscoverySection") }
        public static var healthExcellent: String { tr("health.excellent") }
        public static var healthGood: String { tr("health.good") }
        public static var healthFair: String { tr("health.fair") }
        public static var healthPoor: String { tr("health.poor") }
        public static var islandMessage: String { tr("island.message") }
        public static var islandSuggestion: String { tr("island.suggestion") }
        public static var orphanPage: String { tr("orphan.page") }
        public static var orphanSuggestion: String { tr("orphan.suggestion") }
        public static var cycleMessage: String { tr("cycle.message") }
        public static var cycleSuggestion: String { Localized.tr("lint.cycleSuggestion", table: "Lint") }
        public static var brokenLink: String { tr("brokenLink.message") }
        public static var brokenLinkSuggestion: String { tr("brokenLink.suggestion") }
        public static var stubContent: String { tr("stub.message") }
        public static var stubSuggestion: String { Localized.tr("lint.stubSuggestion", table: "Lint") }
        public static var outdated: String { tr("outdated.message") }
        public static var outdatedSuggestion: String { Localized.tr("lint.outdatedSuggestion", table: "Lint") }
        public static var aiSuggestions: String { tr("aiSuggestions") }
        public static var detailIssues: String { tr("detailIssues") }
        public static var lastCheckTitle: String { tr("lastCheckTitle") }
        public static var lastCheckNever: String { tr("lastCheckNever") }
        public static var metricPages: String { tr("metric.pages") }
        public static var metricBroken: String { tr("metric.broken") }
        public static var metricOrphans: String { tr("metric.orphans") }
        public static var metricLinks: String { tr("metric.links") }
        public static var noIssues: String { tr("noIssues") }
        public static var noIssuesHint: String { tr("noIssuesHint") }
        public static var noAISuggestions: String { tr("noAISuggestions") }
        public static var noAISuggestionsHint: String { tr("noAISuggestionsHint") }
        public static var scanComplete: String { tr("scanComplete") }
        public static var scanning: String { tr("scanning") }
        public static var aiDisabledHint: String { tr("aiDisabledHint") }
        public static var aiScanComplete: String { tr("aiScanComplete") }
        public static var apply: String { tr("apply") }
        public static var runCheck: String { tr("runCheck") }
        public static var runAIScan: String { tr("runAIScan") }
        public static var goToPage: String { tr("goToPage") }

        public static func errors(_ n: Int) -> String { Localized.trf("errorsCount", table: t, n) }
        public static func warnings(_ n: Int) -> String { Localized.trf("warningsCount", table: t, n) }
        public static func tips(_ n: Int) -> String { Localized.trf("tipsCount", table: t, n) }

        public static func aiFixSuggestion(_ s: String) -> String { Localized.trf("aiFixSuggestion", table: t, s) }
        public static var aiFixSuggestionShort: String { tr("aiFixSuggestionShort") }
        public static func aiSuggestionError(_ s: String) -> String { Localized.trf("aiSuggestionError", table: t, s) }
    }
}
