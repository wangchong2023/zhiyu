// Vault.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：笔记本/库领域模型定义
// 版本: 1.0
// 修改记录:
//   - 2026-05-15: 从 VaultService 剥离模型，确保架构解耦。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 笔记本/库基础协议
public protocol VaultProtocol: Sendable {
    var id: UUID { get }
    var name: String { get }
    var icon: String? { get }
    var pageCount: Int { get }
    var updatedAt: Date { get }
}

/// 笔记本/库数据模型
public struct Vault: Identifiable, Codable, Hashable, VaultProtocol {
    public let id: UUID
    public var name: String
    public var createdAt: Date
    public var updatedAt: Date
    public var pageCount: Int
    public var themePayload: String?
    public var icon: String?
    public var description: String?
    
    public init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        pageCount: Int = 0,
        themePayload: String? = nil,
        icon: String? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.pageCount = pageCount
        self.themePayload = themePayload
        self.icon = icon
        self.description = description
    }
}
