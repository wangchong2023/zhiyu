// PageSchema.swift
//
// 作者: Wang Chong
// 功能说明: [L1.5] 领域中心层：页面 Schema：定义特定类型页面必须包含的内容结构
// 版本: 1.1
// 修改记录:
//   - 2026-05-02: 初始版本创建。
//   - 2026-05-07: 架构重构，将 SchemaService 移至 Domain 层，本文件仅保留模型定义。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 页面 Schema：定义特定类型页面必须包含的内容结构
public struct PageSchema: Codable, Sendable {
    public let type: PageType
    public let requiredFields: [String]
    public let template: String
    public let promptInstruction: String

    public init(type: PageType, requiredFields: [String], template: String, promptInstruction: String) {
        self.type = type
        self.requiredFields = requiredFields
        self.template = template
        self.promptInstruction = promptInstruction
    }
}
