//
//  L10n+Network.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/28.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 本地化层
//  核心职责：为 Network 模块提供本地化强类型字符串的访问扩展。
//

import Foundation

public extension L10n {
    enum Network {
        public static let t = "System"

        /// 本地化翻译
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }

        /// 本地化格式化翻译
        public static func trf(_ key: String, _ args: CVarArg...) -> String { Localized.trf(key, table: t, arguments: args) }

        public static var invalidHTTPResponse: String { tr("invalidHTTPResponse") }
        public static var missingDataPayload: String { tr("missingDataPayload") }
        public static var missingRefreshToken: String { tr("missingRefreshToken") }
        public static var sessionInvalidated: String { tr("sessionInvalidated") }
        
        public static var errorInvalidURL: String { tr("errorInvalidURL") }
        public static var errorTokenExpired: String { tr("errorTokenExpired") }
        
        /// errorUnauthorized
        /// - Parameter msg: msg
        /// - Returns: 字符串
        public static func errorUnauthorized(_ msg: String) -> String { trf("errorUnauthorized", msg) }

        /// errorServer
        /// - Parameter code: code
        /// - Parameter msg: msg
        /// - Returns: 字符串
        public static func errorServer(_ code: Int, _ msg: String) -> String { trf("errorServer", code, msg) }

        /// error解码Failed
        /// - Parameter msg: msg
        /// - Returns: 字符串
        public static func errorDecodeFailed(_ msg: String) -> String { trf("errorDecodeFailed", msg) }

        /// errorHTTP
        /// - Parameter code: code
        /// - Returns: 字符串
        public static func errorHTTP(_ code: Int) -> String { trf("errorHTTP", code) }

        /// errorUnexpected
        /// - Parameter msg: msg
        /// - Returns: 字符串
        public static func errorUnexpected(_ msg: String) -> String { trf("errorUnexpected", msg) }
    }
}
