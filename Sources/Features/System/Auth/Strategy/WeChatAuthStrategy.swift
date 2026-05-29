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
    
    public func acquireCredentials() async throws -> AuthCredential {
        let mockCode = "mock_wechat_code_\(UUID().uuidString)"
        return AuthCredential(
            identityType: identityType,
            identifier: "mock_wechat_openid",
            credential: mockCode,
            extraInfo: ["state": UUID().uuidString, "nickname": "WeChat Mock User"]
        )
    }
}

#else

@MainActor
public final class WeChatAuthStrategy: AuthStrategy {
    public var identityType: String { "wechat" }
    public init() {}

    public func acquireCredentials() async throws -> AuthCredential {
        throw NSError(domain: "WeChatAuthStrategy", code: -99, userInfo: [NSLocalizedDescriptionKey: "WeChat SDK not configured"])
    }
}

#endif
