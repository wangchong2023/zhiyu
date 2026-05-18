// 功能说明: [Shared]
//
// L10n+Auth.swift
// 智宇 (ZhiYu) 多语言 Auth 垂直切片强类型扩展定义
//

import Foundation

extension L10n {
    public struct Auth {
        public static let t = "System"
        public static func tr(_ key: String) -> String { Localized.tr(key, table: t) }
        public static var login: String { tr("login") }
        public static var register: String { tr("register") }
        public static var logout: String { tr("logout") }
        public static var identityPlaceholder: String { tr("identity.placeholder") }
        public static var phonePlaceholder: String { Localized.tr("auth.phone.placeholder", table: t) }
        public static var setPasswordPlaceholder: String { Localized.tr("auth.setPassword.placeholder", table: t) }
        public static var passwordPlaceholder: String { tr("password.placeholder") }
        public static var codePlaceholder: String { tr("code.placeholder") }
        public static var getCode: String { tr("getCode") }
        public static var thirdParty: String { tr("thirdParty") }
        public static var guestMode: String { tr("guestMode") }
        public static var authFailed: String { tr("auth.failed") }
    }
}
