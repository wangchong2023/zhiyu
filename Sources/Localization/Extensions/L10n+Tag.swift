//
//  L10n+Tag.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 本地化层
//  核心职责：为 Tag 模块提供本地化强类型字符串的访问扩展。
//
import Foundation

extension L10n {
    public enum Tag {
        public static let t = "Knowledge"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static func trf(_ key: String, _ args: CVarArg...) -> String { Localized.trf(key, table: t, arguments: args) }

        public static var title: String { tr("tag.title") }
        public static var allTags: String { tr("tag.allTags") }
        public static var relatedPagesTitle: String { tr("tag.relatedPagesTitle") }

        public enum Action {
            public static var rename: String { Tag.tr("tag.rename") }
            public static var delete: String { Tag.tr("tag.delete") }
            public static var renameTag: String { Tag.tr("tag.renameTag") }
            public static var newName: String { Tag.tr("tag.newName") }
            public static var deleteTag: String { Tag.tr("tag.deleteTag") }
            public static var noTags: String { Tag.tr("tag.noTags") }
            public static var noTagsHint: String { Tag.tr("tag.noTagsHint") }

            public static func renameMessage(_ name: String) -> String { Tag.trf("tag.renameMessage", name) }
            public static func deleteMessage(_ name: String) -> String { Tag.trf("tag.deleteMessage", name) }
            public static func tagPages(_ count: Int) -> String { Tag.trf("tag.tagPages", count) }
        }

        public enum Management {
            public static var addNew: String { Tag.tr("tags.addNew") }
            public static var inputName: String { Tag.tr("tags.inputName") }
            public static var manageTitle: String { Tag.tr("tags.manageTitle") }
            public static var createHint: String { Tag.tr("tags.createHint") }
            public static var selectToManage: String { Tag.tr("tags.selectToManage") }

            public static func bulkDeleteWarning(_ count: Int) -> String { Tag.trf("tags.bulkDeleteWarning", count) }
            public static func selectedCount(_ count: Int) -> String { Tag.trf("tags.selectedCount", count) }
        }

        public enum Cloud {
            public static var selectTag: String { Tag.tr("tagcloud.selectTag") }
        }
    }
}
