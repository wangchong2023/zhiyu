//
//  L10n+Auth.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 本地化层
//  核心职责：为 Auth 模块提供本地化强类型字符串的访问扩展。
//
import Foundation

extension L10n {
    public struct Auth {
        public static let t = "System"

        /// 本地化翻译
        /// - Parameter key: key
        /// - Returns: 返回值
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
        
        /// 微信登录开发中提示文案
        public static var wechatDeveloping: String { tr("auth.wechatDeveloping") }
        
        /// Google 登录开发中提示文案
        public static var googleDeveloping: String { tr("auth.googleDeveloping") }
        
        /// Apple 登录测试用户默认昵称
        public static var appleTestUser: String { tr("auth.appleTestUser") }
        
        /// 默认普通用户昵称
        public static var defaultUser: String { tr("auth.defaultUser") }
        
        /// 无法提取 Apple ID identityToken 的错误提示
        public static var appleTokenExtractFailed: String { tr("auth.appleTokenExtractFailed") }
        
        // MARK: - 一键登录相关
        public static var oneClickLogin: String { tr("auth.oneClickLogin") }
        public static var agreementText: String { tr("auth.agreementText") }
        public static var pleaseCheckAgreement: String { tr("auth.pleaseCheckAgreement") }
        public static var moreLoginMethods: String { tr("auth.moreLoginMethods") }
        public static var smsDeveloping: String { tr("auth.smsDeveloping") }
        public static var githubDeveloping: String { tr("auth.githubDeveloping") }
        public static var agreementRequired: String { tr("auth.agreementRequired") }
    }
}