//
//  PageSchema.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：属于 Models 模块，提供相关的结构体或工具支撑。
//
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
