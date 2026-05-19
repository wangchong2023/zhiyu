// 功能说明: [Shared]
//
// L10n+Accessibility.swift
// 智宇 (ZhiYu) 多语言 Accessibility 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public struct Accessibility: Sendable {
        public static let t = "Common"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        /// 标签的无障碍声明
        public static var tags: String { Localized.tr("accessibility.tags", table: t) }
        /// 字数的无障碍声明
        public static var words: String { Localized.tr("accessibility.words", table: t) }
        /// 链接的无障碍声明
        public static var links: String { Localized.tr("accessibility.links", table: t) }
        /// 打开操作的无障碍基础声明
        public static var tapToOpen: String { Localized.tr("accessibility.tapToOpen", table: t) }
        
        /// 笔记本金库卡片的无障碍类别标签
        public static var notebookCardLabel: String { Localized.tr("accessibility.notebookCardLabel", table: t) }
        /// 笔记本金库卡片无障碍手势提示文案
        public static var notebookCardHint: String { Localized.tr("accessibility.notebookCardHint", table: t) }
        /// 列表单行笔记本无障碍手势提示文案
        public static var notebookListRowHint: String { Localized.tr("accessibility.notebookListRowHint", table: t) }
    }
}
