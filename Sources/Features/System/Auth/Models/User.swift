// User.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：本文件定义了系统中的用户信息模型。
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
