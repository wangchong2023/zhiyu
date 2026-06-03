//
//  L10n+Vault.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 本地化层
//  核心职责：为 Vault 模块提供本地化强类型字符串的访问扩展。
//
import Foundation

extension L10n {
    public struct Vault {
        public static let t = "Knowledge"

        /// 本地化翻译
        /// - Parameter key: key
        /// - Returns: 返回值
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }

        /// 本地化格式化翻译
        /// - Parameter key: key
        /// - Parameter args: args
        /// - Returns: 返回值
        public static func trf(_ key: String, _ args: CVarArg...) -> String { Localized.trf(key, table: t, arguments: args) }

        public static var homeTitle: String { tr("vault.homeTitle") }
        public static var label: String { tr("vault.label") }
        public static var backToHub: String { tr("vault.backToHub") }
        /// 默认笔记本名称
        public static var defaultName: String { tr("vault.defaultName") }
        /// 项目调研默认笔记本名称
        public static var researchName: String { tr("vault.researchName") }
        public static var subtitle: String { Localized.tr("vault.subtitle", table: t) }
        public static var noSelection: String { tr("vault.noSelection") }
        public static var new: String { Localized.tr("vault.new", table: t) }

        public static var create: String { Localized.tr("vault.create", table: t) }
        public static var edit: String { Localized.tr("vault.edit", table: t) }
        public static var iconLabel: String { Localized.tr("vault.iconLabel", table: t) }
        public static var rename: String { Localized.tr("vault.rename", table: t) }
        public static var namePlaceholder: String { Localized.tr("vault.namePlaceholder", table: t) }
        public static var renameMessage: String { Localized.tr("vault.renameMessage", table: t) }
        /// 默认笔记本描述信息
        public static var defaultDescription: String { Localized.tr("vault.defaultDescription", table: t) }
        /// 项目调研默认笔记本描述信息
        public static var researchDescription: String { Localized.tr("vault.researchDescription", table: t) }
        public static var lastEdited: String { Localized.tr("vault.lastEdited", table: t) }
        public static var descriptionLabel: String { Localized.tr("vault.descriptionLabel", table: t) }
        public static var descriptionPlaceholder: String { Localized.tr("vault.descriptionPlaceholder", table: t) }
        public static var nameLabel: String { Localized.tr("vault.nameLabel", table: t) }
        public static var pageCountSuffix: String {
            Localized.tr("vault.pageCountSuffix", table: t)
        }

        public struct sort {
            public static var date: String { Localized.tr("vault.sort.date", table: t) }
            public static var name: String { Localized.tr("vault.sort.name", table: t) }
        }

        public struct Page {
            public static var knowledge: String { Localized.tr("page.knowledge", table: "Knowledge") }
            public static var deletePage: String { Localized.tr("page.deletePage", table: "Knowledge") }

            /// 删除PageTitle
            /// - Parameter name: name
            /// - Returns: 字符串
            public static func deletePageTitle(_ name: String) -> String { Localized.trf("page.deletePageTitle", table: "Knowledge", name) }
        }

        public struct Backlinks {

            /// 计数
            /// - Parameter n: n
            /// - Returns: 字符串
            public static func count(_ n: Int) -> String { Localized.trf("page.backlinksCount", table: "Knowledge", n) }

            /// outgoing
            /// - Parameter n: n
            /// - Returns: 字符串
            public static func outgoing(_ n: Int) -> String { Localized.trf("page.outLinksCount", table: "Knowledge", n) }
        }
    }
}
