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

        /// 本地化翻译
        /// /// - Parameter key: key
        /// /// - Returns: 返回值
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }

        /// 本地化格式化翻译
        /// /// - Parameter key: key
        /// /// - Parameter args: args
        /// /// - Returns: 返回值
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

            /// 重命名Message
            /// /// - Parameter name: name
            /// /// - Returns: 字符串
            public static func renameMessage(_ name: String) -> String { Tag.trf("tag.renameMessage", name) }

            /// 删除Message
            /// /// - Parameter name: name
            /// /// - Returns: 字符串
            public static func deleteMessage(_ name: String) -> String { Tag.trf("tag.deleteMessage", name) }

            /// tagPages
            /// /// - Parameter count: 计数
            /// /// - Returns: 字符串
            public static func tagPages(_ count: Int) -> String { Tag.trf("tag.tagPages", count) }
        }

        public enum Management {
            public static var addNew: String { Tag.tr("tags.addNew") }
            public static var inputName: String { Tag.tr("tags.inputName") }
            public static var manageTitle: String { Tag.tr("tags.manageTitle") }
            public static var createHint: String { Tag.tr("tags.createHint") }
            public static var selectToManage: String { Tag.tr("tags.selectToManage") }

            /// bulk删除Warning
            /// /// - Parameter count: 计数
            /// /// - Returns: 字符串
            public static func bulkDeleteWarning(_ count: Int) -> String { Tag.trf("tags.bulkDeleteWarning", count) }

            /// selected计数
            /// /// - Parameter count: 计数
            /// /// - Returns: 字符串
            public static func selectedCount(_ count: Int) -> String { Tag.trf("tags.selectedCount", count) }
        }

        public enum Cloud {
            public static var selectTag: String { Tag.tr("tagcloud.selectTag") }
        }
    }
}
