//
//  L10n+Components.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 本地化层
//  核心职责：为 Components 模块提供本地化强类型字符串的访问扩展。
//
import Foundation

extension L10n {
    public struct Components {
        public static let t = "Common"

        /// 本地化翻译
        /// /// - Parameter key: key
        /// /// - Returns: 返回值
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static var noOutgoing: String { tr("components.noOutgoing") }
        public static var noBackLinks: String { tr("components.noBackLinks") }
        public static var search: String { tr("components.search") }
    }
}
