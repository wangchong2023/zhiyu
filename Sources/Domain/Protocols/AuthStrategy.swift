//
//  AuthStrategy.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/24.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：定义统一身份认证策略的客户端接口契约与凭证模型，保持平台无关性。
//

import Foundation

/// 统一封装的客户端登录与注册凭证
/// 包含认证类型、唯一标识、核心凭证明文/Token 以及辅助的社交个人资料
public struct AuthCredential: Sendable {
    /// 身份认证渠道类型，例如 "apple", "wechat", "phone", "google", "passkey", "username"
    public let identityType: String
    
    /// 账号唯一标识，在第三方登录中对应 sub/openid，普通密码登录对应用户名，手机验证码登录对应手机号
    public let identifier: String
    
    /// 核心身份验证凭证，在第三方登录中对应 identityToken/authCode，普通密码对应密码哈希，短信登录对应验证码
    public let credential: String
    
    /// 客户端获取的额外用户资料，用于首次注册时自动初始化昵称或头像
    public let extraInfo: [String: String]?
    
    /// 统一构造方法
    /// - Parameters:
    ///   - identityType: 认证渠道类型
    ///   - identifier: 账号唯一标识
    ///   - credential: 核心身份验证凭证
    ///   - extraInfo: 额外用户资料
    public init(identityType: String, identifier: String, credential: String, extraInfo: [String: String]? = nil) {
        self.identityType = identityType
        self.identifier = identifier
        self.credential = credential
        self.extraInfo = extraInfo
    }
}

/// 客户端身份认证策略标准协议
/// 各个登录渠道（微信、Google、Apple ID、Passkey等）在客户端需要遵从此协议以实现多态注入
@MainActor
public protocol AuthStrategy {
    /// 认证渠道类型标识，用以后端路由匹配
    var identityType: String { get }
    
    /// 驱动客户端物理 SDK 启动用户授权交互，获取对应的第三方/物理安全凭证
    /// - Returns: 标准化的统一登录凭证实例
    /// - Throws: 授权中断、网络失败或凭证解析异常
    func acquireCredentials() async throws -> AuthCredential
}