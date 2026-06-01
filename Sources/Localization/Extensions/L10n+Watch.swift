//
//  L10n+Watch.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 本地化层
//  核心职责：为 Watch 模块提供本地化强类型字符串的访问扩展。
//
import Foundation

extension L10n {
    public struct Watch {
        public static let t = "Platform"

        /// 本地化翻译
        /// - Parameter key: key
        /// - Returns: 返回值
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static var capture: String { tr("watch.capture") }
        public static var recents: String { Localized.tr("watch.recents", table: t) }
        public static var dictateHint: String { Localized.tr("watch.dictate.hint", table: t) }
        public static var widgetDisplayName: String { Localized.tr("watch.widget.displayName", table: t) }
        public static var widgetDisplayDesc: String { Localized.tr("watch.widget.displayDesc", table: t) }
    }
}
