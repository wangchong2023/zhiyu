// 功能说明: [Shared]
//
// L10n+Editor.swift
// 智宇 (ZhiYu) 多语言 Editor 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public struct Editor {
        public static let t = "Editor"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static var insertPageLink: String { Localized.tr("editor.insertPageLink", table: "Editor") }
        public static var searchPages: String { Localized.tr("editor.searchPages", table: "Editor") }
        public static var bidirectionalLinks: String { Localized.tr("editor.bidirectionalLinks", table: "Editor") }
        public static var enterTag: String { Localized.tr("editor.enterTag", table: "Editor") }
        public static var addTag: String { Localized.tr("editor.addTag", table: "Editor") }
        public static var tableColumn1: String { Localized.tr("editor.tableColumn1", table: "Editor") }
        public static var tableColumn2: String { Localized.tr("editor.tableColumn2", table: "Editor") }
        public static var tableColumn3: String { Localized.tr("editor.tableColumn3", table: "Editor") }
        public static var tableContent: String { Localized.tr("editor.tableContent", table: "Editor") }
        public static var bold: String { Localized.tr("editor.bold", table: "Editor") }
        public static var code: String { Localized.tr("editor.code", table: "Editor") }
        public static var divider: String { Localized.tr("editor.divider", table: "Editor") }
        public static var italic: String { Localized.tr("editor.italic", table: "Editor") }
        public static var knowledgeLink: String { Localized.tr("editor.knowledgeLink", table: "Editor") }
        public static var link: String { Localized.tr("editor.link", table: "Editor") }
        public static var list: String { Localized.tr("editor.list", table: "Editor") }
        public static var ocrScan: String { Localized.tr("editor.ocrScan", table: "Editor") }
        public static var quote: String { Localized.tr("editor.quote", table: "Editor") }
        public static var table: String { Localized.tr("editor.table", table: "Editor") }
        public static var selectedText: String { Localized.tr("editor.selectedText", table: "Editor") }
        public static var placeholder: String { Localized.tr("editor.placeholder", table: "Editor") }

        public struct iconPicker {
            public static var reset: String { Localized.tr("editor.iconPicker.reset", table: "Editor") }
            public static var customSelected: String { Localized.tr("editor.iconPicker.customSelected", table: "Editor") }
            public static var useDefault: String { Localized.tr("editor.iconPicker.useDefault", table: "Editor") }
            public static var selectIcon: String { Localized.tr("editor.iconPicker.selectIcon", table: "Editor") }
        }
    }
}
