// User.swift
//
// 作者: Wang Chong
// 功能说明: 智宇 (ZhiYu) 系统用户信息模型。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 用户模型
/// 存储用户的基本信息、身份标识及个性化元数据。
public struct User: Codable, Identifiable, Sendable {
    /// 唯一用户标识符
    public let id: UUID
    /// 用户显示名称
    public var name: String
    /// 注册邮箱
    public var email: String
    /// 头像 URL (可选)
    public var avatarURL: URL?
    
    /// 初始化用户
    public init(id: UUID = UUID(), name: String, email: String, avatarURL: URL? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarURL = avatarURL
    }
}
