// AIWorkflowCapabilities.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：定义 AI 工作流底层能力接口协议，用于领域层与业务层解耦，遵循依赖倒置原则（DIP）。
// 版本: 1.0
// 日期: 2026-05-18
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// AI 工作流能力协议接口
///
/// 本协议定义了领域层可以直接调用的 AI 工作流关键操作，
/// 通过协议抽象避免领域层（Domain）直接引用具体的业务层 Store（Features），保持架构纯净与单向依赖。
@MainActor
public protocol AIWorkflowCapabilities: AnyObject, Sendable {
    
    /// 移除特定的 AI 重构建议
    ///
    /// 当用户应用或拒绝了某项 AI 优化建议后，调用此方法将其从 activity 缓存中清除。
    /// - Parameter id: 优化建议的唯一标识符 (String)
    func removeRefactorSuggestion(id: String)
}
