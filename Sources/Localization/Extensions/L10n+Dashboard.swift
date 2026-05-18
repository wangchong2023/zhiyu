// 功能说明: [Shared]
//
// L10n+Dashboard.swift
// 智宇 (ZhiYu) 多语言 Dashboard 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public struct Dashboard {
        public static let t = "Dashboard"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static func trf(_ key: String, _ args: CVarArg...) -> String {
            let localized = Localized.trf(key, table: t, arguments: args)
            if localized == key {
                return Localized.trf(key, table: "Dashboard", arguments: args)
            }
            return localized
        }

        public static var pageListPages: String { Localized.tr("dashboard.pageList.pages", table: "Dashboard") }
        public static var pageListLinks: String { Localized.tr("dashboard.pageList.links", table: "Dashboard") }
        public static var density: String { Localized.tr("dashboard.density", table: "Dashboard") }
        public static var dailyInsights: String { Localized.tr("dashboard.dailyInsights", table: "Dashboard") }
        public static var hotTopics: String { Localized.tr("dashboard.hotTopics", table: "Dashboard") }

        public static var insightsLoading: String { Localized.tr("dashboard.insights.loading", table: "Dashboard") }
        public static var insightsPageDeleted: String { Localized.tr("insights.pageDeleted", table: "Dashboard") }
        public static var insightsEmpty: String { Localized.tr("dashboard.insights.empty", table: "Dashboard") }
        public static var graphShortcut: String { Localized.tr("graphShortcut", table: "Dashboard") }

        public struct insight {
            public static var weeklyTitle: String { Localized.tr("dashboard.insight.weeklyTitle", table: "Dashboard") }
            public static var generateReport: String { Localized.tr("dashboard.insight.generateReport", table: "Dashboard") }

            public struct daily {
                public static var systemPrompt: String { Localized.tr("dashboard.insight.daily.systemPrompt", table: "Dashboard") }

                /// 获取每日洞察针对最近内容的 Prompt
                /// - Parameters:
                ///   - focus: 关注点/热点话题
                ///   - title: 页面标题
                ///   - snippet: 页面片段
                /// - Returns: 本地化 Prompt
                public static func promptRecent(_ focus: String, _ title: String, _ snippet: String) -> String { Dashboard.trf("insight.daily.prompt.recent", focus, title, snippet) }
            }

            public struct recap {
                public static var tip: String { Localized.tr("dashboard.insight.recap.tip", table: "Dashboard") }
            }

            public struct weekly {
                public static var systemPrompt: String { Localized.tr("dashboard.insight.weekly.systemPrompt", table: "Dashboard") }

                /// 获取每周洞察针对精选页面的 Prompt
                /// - Parameter titles: 精选条目标题连接串
                /// - Returns: 本地化 Prompt
                public static func prompt(_ titles: String) -> String { Dashboard.trf("insight.weekly.prompt", titles) }
            }

            public struct growth {
                public static var explosive: String { Localized.tr("dashboard.insight.growth.explosive", table: "Dashboard") }
                public static var steady: String { Localized.tr("dashboard.insight.growth.steady", table: "Dashboard") }
            }

            public struct tips {
                public static var title: String { Localized.tr("dashboard.insight.tips.title", table: "Dashboard") }
                public static var content: String { Localized.tr("dashboard.insight.tips.content", table: "Dashboard") }
            }
        }

        public struct pageList {
            public static var tags: String { Localized.tr("dashboard.pageList.tags", table: "Dashboard") }
            public static var sources: String { Localized.tr("dashboard.pageList.sources", table: "Dashboard") }
            public static var overview: String { Localized.tr("dashboard.pageList.overview", table: "Dashboard") }
            public static var concepts: String { Localized.tr("dashboard.pageList.concepts", table: "Dashboard") }
            public static var entities: String { Localized.tr("dashboard.pageList.entities", table: "Dashboard") }
            public static var wordCount: String { Localized.tr("dashboard.pageList.wordCount", table: "Dashboard") }
            public static var entityCount: String { Localized.tr("dashboard.pageList.entityCount", table: "Dashboard") }
            public static var conceptCount: String { Localized.tr("dashboard.pageList.conceptCount", table: "Dashboard") }
            public static var sourceCount: String { Localized.tr("dashboard.pageList.sourceCount", table: "Dashboard") }
            public static var comparisonCount: String { Localized.tr("dashboard.pageList.comparisonCount", table: "Dashboard") }

            /// 获取格式化字数文案
            /// - Parameter count: 字数
            /// - Returns: 本地化格式化文案
            public static func wordCount(_ count: Int) -> String { Localized.trf("pageList.wordCount", table: "Dashboard", count) }

            /// 获取格式化实体个数文案
            /// - Parameter count: 实体个数
            /// - Returns: 本地化格式化文案
            public static func entityCount(_ count: Int) -> String { Localized.trf("pageList.entityCount", table: "Dashboard", count) }

            /// 获取格式化概念个数文案
            /// - Parameter count: 概念个数
            /// - Returns: 本地化格式化文案
            public static func conceptCount(_ count: Int) -> String { Localized.trf("pageList.conceptCount", table: "Dashboard", count) }

            /// 获取格式化信源个数文案
            /// - Parameter count: 信源个数
            /// - Returns: 本地化格式化文案
            public static func sourceCount(_ count: Int) -> String { Localized.trf("pageList.sourceCount", table: "Dashboard", count) }

            /// 获取格式化对比个数文案
            /// - Parameter count: 对比个数
            /// - Returns: 本地化格式化文案
            public static func comparisonCount(_ count: Int) -> String { Localized.trf("pageList.comparisonCount", table: "Dashboard", count) }
        }

        public static var title: String { tr("title") }
        public static var unitMs: String { Localized.tr("dashboard.stats.unitMs") }
        public static var densityDesc: String { Localized.tr("dashboard.density.desc", table: "Dashboard") }
        public static var densityDetails: String { Localized.tr("dashboard.density.details", table: "Dashboard") }
        public static var densityOutbound: String { Localized.tr("dashboard.density.outbound", table: "Dashboard") }
        public static var densityInbound: String { Localized.tr("dashboard.density.inbound", table: "Dashboard") }
        public static var benchmarkDescription: String { Localized.tr("dashboard.stats.benchmark.description", table: "Dashboard") }
        public static var cleanupAction: String { Dashboard.tr("cleanupAction") }
        public static var updateSuccess: String { Localized.tr("dashboard.updateSuccess", table: "Dashboard") }
        public static var totalPages: String { Dashboard.tr("totalPages") }
        public static var totalLinks: String { Dashboard.tr("totalLinks") }
        public static var apiRequests: String { Dashboard.tr("apiRequests") }
        public static var totalStorage: String { Dashboard.tr("totalStorage") }
        public static var tokens: String { Dashboard.tr("tokens") }
        public static var chartDate: String { Localized.tr("dashboard.stats.chartDate", table: "Dashboard") }
        public static var chartSelected: String { Localized.tr("dashboard.stats.chartSelected", table: "Dashboard") }
        public static var chartValue: String { Localized.tr("dashboard.stats.chartValue", table: "Dashboard") }
        /// 数据维护与清理段标题
        public static var maintenance: String { Localized.tr("dashboard.stats.maintenance", table: "Dashboard") }
        /// 已清理条数的前缀文案
        public static var cleanedPrefix: String { Localized.tr("dashboard.stats.cleanedPrefix", table: "Dashboard") }
        /// 已清理条数的后缀文案
        public static var cleanedSuffix: String { Localized.tr("dashboard.stats.cleanedSuffix", table: "Dashboard") }

        public struct stats {
            public static var faithfulness: String { Dashboard.tr("stats.faithfulness") }
            public static var relevance: String { Dashboard.tr("stats.relevance") }
            public static var precision: String { Dashboard.tr("stats.precision") }
            public static var benchmark: String { Localized.tr("dashboard.stats.benchmark", table: "Dashboard") }
            public static var categoryDistribution: String { Localized.tr("dashboard.stats.categoryDistribution", table: "Dashboard") }
            public static var knowledgeGrowth: String { Localized.tr("dashboard.stats.knowledgeGrowth", table: "Dashboard") }
            public static var navigationTitleMonitor: String { Localized.tr("dashboard.stats.navigationTitleMonitor", table: "Dashboard") }
            public static var storageImport: String { Localized.tr("dashboard.stats.storageImport", table: "Dashboard") }
            public static var storageExport: String { Localized.tr("dashboard.stats.storageExport", table: "Dashboard") }
            public static var tabPerf: String { Localized.tr("dashboard.stats.tabPerf", table: "Dashboard") }
            public static var tabStorage: String { Localized.tr("dashboard.stats.tabStorage", table: "Dashboard") }
            public static var rangeThirtyDays: String { Localized.tr("dashboard.stats.rangeThirtyDays", table: "Dashboard") }
            public static var requestsUsage: String { Localized.tr("dashboard.stats.requestsUsage", table: "Dashboard") }
            public static var storageDistribution: String { Localized.tr("dashboard.stats.storageDistribution", table: "Dashboard") }
            public static var chartDate: String { Localized.tr("dashboard.stats.chartDate", table: "Dashboard") }
            public static var chartSelected: String { Localized.tr("dashboard.stats.chartSelected", table: "Dashboard") }
            /// Token 使用消耗量卡片标题
            public static var tokensUsage: String { Localized.tr("dashboard.stats.tokensUsage", table: "Dashboard") }
            /// 响应时延统计卡片标题
            public static var latencyTitle: String { Localized.tr("dashboard.stats.latencyTitle", table: "Dashboard") }
            /// 平均响应时延简写标签
            public static var avgLatencyShort: String { Localized.tr("dashboard.stats.avgLatencyShort", table: "Dashboard") }
            /// 最大时延标签
            public static var maxLatency: String { Localized.tr("dashboard.stats.maxLatency", table: "Dashboard") }
            /// 最小时延标签
            public static var minLatency: String { Localized.tr("dashboard.stats.minLatency", table: "Dashboard") }
            /// 时延测量次数/样本数标签
            public static var measureCount: String { Localized.tr("dashboard.stats.measureCount", table: "Dashboard") }
            /// 存储空间分布详情卡片标题
            public static var storageDetails: String { Localized.tr("dashboard.stats.storageDetails", table: "Dashboard") }
            public static var chartValue: String { Localized.tr("dashboard.stats.chartValue", table: "Dashboard") }

            public struct short {
                public static var entity: String { Dashboard.tr("stats.short.entity") }
                public static var concept: String { Dashboard.tr("stats.short.concept") }
                public static var source: String { Dashboard.tr("stats.short.source") }
                public static var comparison: String { Dashboard.tr("stats.short.comparison") }
                public static var pages: String { Dashboard.tr("stats.short.pages") }
                public static var new: String { Dashboard.tr("stats.short.new") }
                public static var ref: String { Dashboard.tr("stats.short.ref") }
            }
        }


        public struct index {
            public static var title: String { Localized.tr("dashboard.index.title", table: "Dashboard") }
            public static var overview: String { Localized.tr("dashboard.index.overview", table: "Dashboard") }
        }

        public struct System {
            public static var status: String { Localized.tr("dashboard.system.status", table: "Dashboard") }
            public static var database: String { Dashboard.tr("stats.database") }
            public static var logs: String { Dashboard.tr("stats.logs") }
        }
    }
}
