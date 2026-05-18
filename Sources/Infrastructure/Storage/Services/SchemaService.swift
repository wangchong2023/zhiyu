// SchemaService.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：页面结构服务，管理各类型页面的标准 Schema 与 提示词指令。
// 版本: 1.0
// 修改记录:
//   - 2026-05-07: 从 Models 目录迁移至 Domain 层，实现业务逻辑与数据模型的分离。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
