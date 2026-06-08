//
//  SchemaService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：实现 Schema 模块的核心业务逻辑服务。
//
import Foundation

/// 页面结构服务：管理各类型页面的标准 Schema 与 提示词指令
@MainActor
final class SchemaService {
    /// 全局单例
    static let shared = SchemaService()

    /// 预置的页面 Schema 映射表
    private(set) var schemas: [PageType: PageSchema] = [
        .entity: PageSchema(
            type: .entity,
            requiredFields: [
                L10n.Schema.entity.field.definition,
                L10n.Schema.entity.field.attributes,
                L10n.Schema.entity.field.relations
            ],
            template: L10n.Schema.entity.template,
            promptInstruction: L10n.Schema.entity.prompt
        ),
        .concept: PageSchema(
            type: .concept,
            requiredFields: [
                L10n.Schema.concept.field.theory,
                L10n.Schema.concept.field.applications
            ],
            template: L10n.Schema.concept.template,
            promptInstruction: L10n.Schema.concept.prompt
        )
    ]

    /// 获取指定类型的页面 Schema
    /// - Parameter type: 页面类型
    /// - Returns: 匹配的 PageSchema 实例或 nil
    func schema(for type: PageType) -> PageSchema? {
        schemas[type]
    }
}