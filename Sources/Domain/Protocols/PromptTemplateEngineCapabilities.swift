//
//  PromptTemplateEngineCapabilities.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层 / 协议契约
//  核心职责：定义动态提示词模板插值引擎的契约。支持动态参数解析、远程 Markdown 热更新拉取以及版本化缓存与降级机制。
//

import Foundation

/// 动态提示词解析引擎的能力契约协议
public protocol PromptTemplateEngineCapabilities: Sendable {
    
    /// 解析并插值替换系统提示词模板中的变量
    /// - Parameters:
    ///   - template: 提示词模板内容（如："{{input}}"）
    ///   - variables: 参数字典（如：["input": "Hello"]）
    /// - Returns: 完成插值替换后的最终提示词文本
    func parse(template: String, with variables: [String: String]) -> String
    
    /// 渲染指定的 Agent 智能体技能提示词
    ///
    /// 该方法具备极致的鲁棒性：
    /// 1. 优先校验本地沙盒是否存在对应 `skillId` 与 `version` 的缓存。
    /// 2. 若无缓存且配置了 `remotePromptURLString`，将尝试从远端静默热更新拉取最新的 Markdown 提示词。
    /// 3. 若远端拉取成功，写入沙盒版本化缓存。
    /// 4. 若无远端 URL、网络异常或拉取失败，将 100% 平滑降级至本地预设的 `systemPromptTemplate`。
    /// 5. 最后，将拉取到或兜底的提示词内容执行 `{{variable}}` 动态插值解析并返回。
    ///
    /// - Parameters:
    ///   - skill: 智能体技能领域实体模型
    ///   - variables: 待插值替换的参数字典（如包含 input、context 等）
    /// - Returns: 最终装配完成的提示词文本，用于直接送入大模型推理
    func renderPrompt(for skill: AgentSkill, with variables: [String: String]) async -> String
    
    /// 清除所有本地缓存的外部 Prompt 文本
    func clearCache() async
}