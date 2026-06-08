//
//  AuthDTOs.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/28.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层 / [L2] 业务功能层
//  核心职责：定义与后端 API 通信所需的各种网络请求与响应模型 (Data Transfer Objects)。
//

import Foundation

// MARK: - 发送短信

public struct SendSmsRequest: Encodable {
    public let phone: String
    public let scene: String
    
    public init(phone: String, scene: String = "login") {
        self.phone = phone
        self.scene = scene
    }
}

// MARK: - 统一登录 (密码 & 短信)

public struct LoginRequest: Encodable {
    public let grantType: String
    public let username: String?
    public let password: String?
    public let phone: String?
    public let smsCode: String?
    public let privacyConsent: Bool
    public let captchaToken: String?
    public let captchaCode: String?
    
    /// 初始化密码登录请求
    public static func password(username: String, password: String, consent: Bool = true) -> LoginRequest {
        return LoginRequest(
            grantType: "password",
            username: username,
            password: password,
            phone: nil,
            smsCode: nil,
            privacyConsent: consent,
            captchaToken: nil,
            captchaCode: nil
        )
    }
    
    /// 初始化短信验证登录请求
    public static func sms(phone: String, code: String, consent: Bool = true) -> LoginRequest {
        return LoginRequest(
            grantType: "sms_code",
            username: nil,
            password: nil,
            phone: phone,
            smsCode: code,
            privacyConsent: consent,
            captchaToken: nil,
            captchaCode: nil
        )
    }
}

// MARK: - 游客跳过登录

public struct GuestLoginRequest: Encodable {
    public let deviceId: String
    public let privacyConsent: Bool
    
    public init(deviceId: String, privacyConsent: Bool = true) {
        self.deviceId = deviceId
        self.privacyConsent = privacyConsent
    }
}

// MARK: - 第三方 OAuth 登录

public struct OAuthAppleRequest: Encodable {
    public let code: String
    public let state: String?
    public let idToken: String?
    
    public init(code: String, state: String?, idToken: String?) {
        self.code = code
        self.state = state
        self.idToken = idToken
    }
}

public struct OAuthWeChatRequest: Encodable {
    public let code: String
    public let state: String?
    
    public init(code: String, state: String? = nil) {
        self.code = code
        self.state = state
    }
}

public struct OAuthGoogleRequest: Encodable {
    public let idToken: String
    
    public init(idToken: String) {
        self.idToken = idToken
    }
}

public struct OAuthGitHubRequest: Encodable {
    public let code: String
    public let state: String?
    
    public init(code: String, state: String? = nil) {
        self.code = code
        self.state = state
    }
}

// MARK: - 运营商一键登录

public struct CarrierAuthRequest: Encodable {
    public let carrierToken: String
    public let appKey: String
    public let privacyConsent: Bool
    
    public init(carrierToken: String, appKey: String, privacyConsent: Bool = true) {
        self.carrierToken = carrierToken
        self.appKey = appKey
        self.privacyConsent = privacyConsent
    }
}

// MARK: - 登录统一响应

/// Token 数据传输对象
public struct TokenDTO: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String?
    public let accessExpireAt: Int
    public let refreshExpireAt: Int?
}

/// 用户数据传输对象
public struct UserDTO: Codable, Sendable {
    public let id: String
    public let name: String
    public let phone: String?
    public let email: String?
    public let avatar: String?
}

/// 登录统一响应封装
public struct LoginResponse: Codable, Sendable {
    public let user: UserDTO
    public let tokens: TokenDTO
    public let isNewUser: Bool?
    public let totpRequired: Bool?
}

// MARK: - 刷新与登出

public struct RefreshRequest: Encodable {
    public let refreshToken: String
    
    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}

public struct RefreshResponse: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    public let tokenType: String
}