// 功能说明: [Shared]
//
// L10n+Vault.swift
// 智宇 (ZhiYu) 多语言 Vault 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public struct Vault {
        public static let t = "Vault"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static func trf(_ key: String, _ args: CVarArg...) -> String { Localized.trf(key, table: t, arguments: args) }

        public static var homeTitle: String { tr("vault.homeTitle") }
        public static var label: String { tr("vault.label") }
        public static var backToHub: String { tr("vault.backToHub") }
        public static var defaultName: String { tr("vault.defaultName") }
        public static var subtitle: String { Localized.tr("vault.subtitle", table: "Vault") }
        public static var noSelection: String { tr("vault.noSelection") }
        public static var new: String { Localized.tr("vault.new", table: "Vault") }

        public static var create: String { Localized.tr("vault.create", table: "Vault") }
        public static var edit: String { Localized.tr("vault.edit", table: "Vault") }
        public static var iconLabel: String { Localized.tr("vault.iconLabel", table: "Vault") }
        public static var rename: String { Localized.tr("vault.rename", table: "Vault") }
        public static var namePlaceholder: String { Localized.tr("vault.namePlaceholder", table: "Vault") }
        public static var renameMessage: String { Localized.tr("vault.renameMessage", table: "Vault") }
        public static var defaultDescription: String { Localized.tr("vault.defaultDescription", table: "Vault") }
        public static var lastEdited: String { Localized.tr("vault.lastEdited", table: "Vault") }
        public static var descriptionLabel: String { Localized.tr("vault.descriptionLabel", table: "Vault") }
        public static var descriptionPlaceholder: String { Localized.tr("vault.descriptionPlaceholder", table: "Vault") }
        public static var nameLabel: String { Localized.tr("vault.nameLabel", table: "Vault") }
        public static var pageCountSuffix: String {
            Localized.tr("vault.pageCountSuffix", table: "Vault")
        }

        public struct sort {
            public static var date: String { Localized.tr("vault.sort.date", table: "Vault") }
            public static var name: String { Localized.tr("vault.sort.name", table: "Vault") }
        }

        public struct Page {
            public static var knowledge: String { Localized.tr("page.knowledge", table: "Knowledge") }
            public static var deletePage: String { Localized.tr("page.deletePage", table: "Knowledge") }
            public static func deletePageTitle(_ name: String) -> String { Localized.trf("page.deletePageTitle", table: "Knowledge", name) }
        }

        public struct Backlinks {
            public static func count(_ n: Int) -> String { Localized.trf("page.backlinksCount", table: "Knowledge", n) }
            public static func outgoing(_ n: Int) -> String { Localized.trf("page.outLinksCount", table: "Knowledge", n) }
        }
    }
}
