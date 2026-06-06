//
//  L10n+Plugin.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 本地化层
//  核心职责：为 Plugin 模块提供本地化强类型字符串的访问扩展。
//
import Foundation

extension L10n {
    public enum Plugin {
        public static let t = "Plugin"

        /// 本地化翻译
        /// - Parameter key: key
        /// - Returns: 返回值
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }

        /// 本地化格式化翻译
        /// - Parameter key: key
        /// - Parameter args: args
        /// - Returns: 返回值
        public static func trf(_ key: String, _ args: CVarArg...) -> String { Localized.trf(key, table: t, arguments: args) }

        /// permTitle
        /// - Returns: 字符串
        public static func permTitle(for perm: String) -> String {
            switch perm {
            case "writeContent", "content":
                return Localized.tr("plugin.perm.content", table: t)
            case "network":
                return Localized.tr("plugin.perm.network", table: t)
            case "sandbox":
                return Localized.tr("plugin.perm.sandbox", table: t)
            default:
                let key = "plugin.perm." + perm
                let localized = Localized.tr(key, table: t)
                return localized == key ? perm.capitalized : localized
            }
        }

        /// permDesc
        /// - Returns: 字符串
        public static func permDesc(for perm: String) -> String {
            switch perm {
            case "writeContent", "content":
                let key = "plugin.perm.content.desc"
                let localized = Localized.tr(key, table: t)
                return localized == key ? Plugin.tr("permission.modifyKnowledgeDesc") : localized
            case "network":
                let key = "plugin.perm.network.desc"
                let localized = Localized.tr(key, table: t)
                return localized == key ? Plugin.tr("permission.networkAccessDesc") : localized
            case "sandbox":
                let key = "plugin.perm.sandbox.desc"
                let localized = Localized.tr(key, table: t)
                return localized == key ? Plugin.tr("permission.sandboxDesc") : localized
            default:
                let key = "plugin.perm." + perm + ".desc"
                let localized = Localized.tr(key, table: t)
                return localized == key ? Plugin.trf("permission.requestPermission", perm) : localized
            }
        }

        public static var centerTitle: String { tr("plugin.center") }
        public static var marketTitle: String { tr("plugin.market") }
        public static var myPlugins: String { tr("plugin.myPlugins") }
        public static var safeModeTitle: String { tr("plugin.safeMode") }
        public static var safeModeWarningTitle: String { tr("plugin.safeMode.warning.title") }
        public static var safeModeWarningMessage: String { tr("plugin.safeMode.warning.message") }
        public static var safeModeTurnOff: String { tr("plugin.safeMode.turnOff") }
        public static var searchPlaceholder: String { tr("plugin.searchPlaceholder") }
        public static var noPlugins: String { tr("plugin.noPlugins") }
        public static var noPluginsHint: String { tr("plugin.noPluginsHint") }
        public static var noResults: String { tr("plugin.noResults") }
        public static var noResultsHint: String { tr("plugin.noResultsHint") }

        /// permissionMessage
        /// - Parameter name: name
        /// - Returns: 字符串
        public static func permissionMessage(_ name: String) -> String { trf("plugin.permission.message", name) }

        public enum Sidebar {
            public static var currentSources: String { Plugin.tr("sidebar.currentSources") }
        }
        
        public typealias Section = section
        public enum section {
            public static var rag: String { Plugin.tr("section.rag") }
            public static var pluginSettings: String { Plugin.tr("section.pluginSettings") }
            public static var permissions: String { Plugin.tr("plugin.section.permissions") }
            public static var about: String { Plugin.tr("plugin.section.about") }
            public static var ribbon: String { Plugin.tr("plugin.section.ribbon") }
        }

        public enum Status {
            public static var enabled: String { Plugin.tr("plugin.status.enabled") }
            public static var disabled: String { Plugin.tr("plugin.status.disabled") }
        }

        public enum market {
            public static var empty: String { Plugin.tr("plugin.market.empty") }
            public static var emptyHint: String { Plugin.tr("plugin.market.emptyHint") }
            public static var connectionError: String { Plugin.tr("plugin.market.connectionError") }
        }

        public enum commands {
            public static var title: String { Plugin.tr("plugin.commands.title") }
        }

        public enum local {
            public static var mount: String { Plugin.tr("plugin.local.mount") }
            public static var desc: String { Plugin.tr("plugin.local.desc") }
        }

        public enum Stats {
            public static var downloads: String { Plugin.tr("plugin.stats.downloads") }
            public static var rating: String { Plugin.tr("plugin.stat.rating") }
            public static var resourceUsage: String { Plugin.tr("plugin.stats.resourceUsage") }
            public static var noUsage: String { Plugin.tr("plugin.stats.noUsage") }

            /// call计数格式化
            /// - Parameter calls: calls
            /// - Parameter avgMs: avgMs
            /// - Returns: 字符串
            public static func callCountFormat(calls: Int, avgMs: Double) -> String {
                Plugin.trf("plugin.stats.callCountFormat", calls, avgMs)
            }
        }

        public enum settings {
            public static var noSettings: String { Plugin.tr("plugin.settings.noSettings") }
        }

        public enum Action {
            public static var install: String { Plugin.tr("plugin.action.install") }
            public static var uninstall: String { Plugin.tr("plugin.action.uninstall") }
            public static var confirmInstall: String { Plugin.tr("plugin.action.confirmInstall") }
        }

        public enum perm {
            public static var none: String { Plugin.tr("plugin.perm.none") }
        }

        public enum permission {
            public static var title: String { Plugin.tr("plugin.permission.title") }

            /// message
            /// - Parameter name: name
            /// - Returns: 字符串
            public static func message(_ name: String) -> String { Plugin.trf("plugin.permission.message", name) }
        }

        // MARK: - 沙盒与 DLP 安全拦截报错词条
        // MARK: - 插件详情页（参照业界标准）

        public enum Detail {
            /// "by {author}"
            public static func byAuthor(_ author: String) -> String { Plugin.trf("plugin.detail.byAuthor", author) }
            public static var downloadsUnit: String { Plugin.tr("plugin.detail.downloadsUnit") }
            public static var installed: String { Plugin.tr("plugin.detail.installed") }
            public static var metadataTitle: String { Plugin.tr("plugin.detail.metadata") }
            public static var version: String { Plugin.tr("plugin.detail.version") }
            public static var author: String { Plugin.tr("plugin.detail.author") }
            public static var minAppVersion: String { Plugin.tr("plugin.detail.minAppVersion") }
            public static var category: String { Plugin.tr("plugin.detail.category") }
            public static var license: String { Plugin.tr("plugin.detail.license") }
            public static var reportTitle: String { Plugin.tr("plugin.detail.report") }
            public static var reportIssue: String { Plugin.tr("plugin.detail.reportIssue") }
            public static var viewSource: String { Plugin.tr("plugin.detail.viewSource") }
            public static var categoryLocal: String { Plugin.tr("plugin.detail.category.local") }
            public static var categoryRemote: String { Plugin.tr("plugin.detail.category.remote") }
            public static var categoryCommunity: String { Plugin.tr("plugin.detail.category.community") }
            public static var licenseFree: String { Plugin.tr("plugin.detail.license.free") }
            public static var licenseDonation: String { Plugin.tr("plugin.detail.license.donation") }
            public static var licenseSubscription: String { Plugin.tr("plugin.detail.license.subscription") }

            /// 评价数格式化，如 "（287）"
            public static func reviewCount(_ count: Int) -> String { Plugin.trf("plugin.detail.reviewCount", count) }
        }

        public enum Error {
            public static var sandboxBlocked: String { Plugin.tr("plugin.error.sandboxBlocked") }
            public static var dlpScriptBlocked: String { Plugin.tr("plugin.error.dlpScriptBlocked") }

            /// dlp拉取Blocked
            /// - Parameter host: host
            /// - Returns: 字符串
            public static func dlpFetchBlocked(_ host: String) -> String { Plugin.trf("plugin.error.dlpFetchBlocked", host) }

            /// pre处理Exception
            /// - Parameter reason: reason
            /// - Returns: 字符串
            public static func preProcessException(_ reason: String) -> String { Plugin.trf("plugin.error.preProcessException", reason) }
            public static var payloadTooLarge: String { Plugin.tr("plugin.error.payloadTooLarge") }

            /// post处理Exception
            /// - Parameter reason: reason
            /// - Returns: 字符串
            public static func postProcessException(_ reason: String) -> String { Plugin.trf("plugin.error.postProcessException", reason) }

            /// invalidURL
            /// - Parameter url: url
            /// - Returns: 字符串
            public static func invalidURL(_ url: String) -> String { Plugin.trf("plugin.error.invalidURL", url) }

            /// keyLengthExceeded
            /// - Parameter limit: limit
            /// - Returns: 字符串
            public static func keyLengthExceeded(_ limit: Int) -> String { Plugin.trf("plugin.error.keyLengthExceeded", limit) }
        }
    }
}

