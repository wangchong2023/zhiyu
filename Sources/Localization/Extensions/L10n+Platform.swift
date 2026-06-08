//
//  L10n+Platform.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/30.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 本地化层
//  核心职责：为平台特定功能提供本地化强类型字符串的访问扩展。
//
import Foundation

extension L10n {
    public enum Platform {
        public static let t = "Platform"

        /// 本地化翻译
        /// /// - Parameter key: key
        /// /// - Returns: 返回值
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }

        public enum Unsupported {
            public static var pdf: String { Platform.tr("platform.unsupported.pdf") }
            public static var mermaid: String { Platform.tr("platform.unsupported.mermaid") }
        }
    }
}