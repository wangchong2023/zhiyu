//
//  User.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：用户认证模型：包含基本信息与订阅套餐配额字段。
//
import Foundation

/// 用户信息模型
/// 包含基本身份信息以及当前订阅套餐的配额限制字段。
public struct User: Codable, Identifiable, Sendable {
    // MARK: - 基本身份信息

    /// 唯一标识符
    public let id: UUID
    /// 用户昵称/显示名
    public let name: String
    /// 电子邮箱
    public let email: String
    /// 头像远端 URL（可选）
    public var avatarURL: URL?

    // MARK: - 订阅套餐信息

    /// 当前套餐标识：free（Lite 基础版）或 pro（Pro 专业版）
    public var planKey: String?
    /// 套餐允许的最大金库（笔记本）数量
    public var maxVaults: Int
    /// 套餐允许的最大知识页面数量
    public var maxPages: Int
    /// 套餐允许的最大插件安装数量
    public var maxPlugins: Int

    // MARK: - 初始化

    /// 完整初始化方法
    public init(
        id: UUID = UUID(),
        name: String,
        email: String,
        avatarURL: URL? = nil,
        planKey: String? = "free",
        maxVaults: Int = 2,
        maxPages: Int = 1000,
        maxPlugins: Int = 3
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarURL = avatarURL
        self.planKey = planKey
        self.maxVaults = maxVaults
        self.maxPages = maxPages
        self.maxPlugins = maxPlugins
    }

    // MARK: - 便捷属性

    /// 是否为 Pro 专业版用户
    public var isPro: Bool {
        planKey == "pro"
    }
}
