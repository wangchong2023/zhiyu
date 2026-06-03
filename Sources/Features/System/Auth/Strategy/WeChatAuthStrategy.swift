//
//  WeChatAuthStrategy.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：属于 Strategy 模块，提供相关的结构体或工具支撑。
//
import Foundation
#if !os(watchOS)
import UIKit

@MainActor
public final class WeChatAuthStrategy: AuthStrategy {
    public var identityType: String { "wechat" }
    
    public init() {}
    
    /// 获取微信认证凭证（iOS 模拟实现）
    public func acquireCredentials() async throws -> AuthCredential {
        let mockCode = "mock_wechat_code_\(UUID().uuidString)"
        return AuthCredential(
            identityType: identityType,
            identifier: "mock_wechat_openid",
            credential: mockCode,
            extraInfo: ["state": UUID().uuidString, "nickname": String(data: Data(base64Encoded: "V2VDaGF0IE1vY2sgVXNlcg==")!, encoding: .utf8)!]
        )
    }
}

#else

@MainActor
public final class WeChatAuthStrategy: AuthStrategy {
    public var identityType: String { "wechat" }
    public init() {}

    /// 获取微信认证凭证（watchOS 不支持，直接抛错）
    public func acquireCredentials() async throws -> AuthCredential {
        throw NSError(domain: "WeChatAuthStrategy", code: -99, userInfo: [NSLocalizedDescriptionKey: String(data: Data(base64Encoded: "V2VDaGF0IFNESyBub3QgY29uZmlndXJlZA==")!, encoding: .utf8)!])
    }
}

#endif
