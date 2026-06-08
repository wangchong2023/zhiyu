//
//  User.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：用户认证：多平台登录（Apple/Google/GitHub/微信/运营商）。
//
import Foundation

/// 用户信息模型
public struct User: Codable, Identifiable, Sendable {
    /// 唯一标识符
    public let id: UUID
    /// 用户姓名
    public let name: String
    /// 电子邮箱
    public let email: String
    /// 头像 URL (可选)
    public var avatarURL: URL?
    
    /// 初始化方法
    public init(id: UUID = UUID(), name: String, email: String, avatarURL: URL? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarURL = avatarURL
    }
}
