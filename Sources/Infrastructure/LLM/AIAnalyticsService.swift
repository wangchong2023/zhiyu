//
//  AIAnalyticsService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：实现 AIAnalytics 模块的核心业务逻辑服务。
//
import Foundation

/// AI 指标分析服务 (L1-Infra)
public final class AIAnalyticsService: Sendable {
    
    public init() {}

    /// 记录单次 LLM 调用指标
    public func recordUsage(model: String, response: [String: Any], latency: Int) {
        // 单测环境下禁用后台异步指标写入，以防重置 DI 容器导致的崩溃
        guard NSClassFromString("XCTestCase") == nil else { return }
        
        guard let usage = response["usage"] as? [String: Any],
              let prompt = usage["prompt_tokens"] as? Int,
              let completion = usage["completion_tokens"] as? Int else { return }

        Task.detached(priority: .background) {
            let governance = ServiceContainer.shared.resolve((any GovernanceRepository).self)
            _ = try? await governance.logCall(model: model, promptTokens: prompt, completionTokens: completion, latencyMS: latency, status: AppConstants.Storage.defaultCallStatus)
            _ = try? await governance.logTokenUsage(model: model, promptTokens: prompt, completionTokens: completion)
        }
    }

    /// 执行 RAG 性能指标异步计算与评估
    public func recordRAGMetrics(query: String, response: String, context: String, systemPrompt: String, modelName: String, latency: Int) {
        // 单测环境下禁用后台异步指标写入，以防重置 DI 容器导致的崩溃
        guard NSClassFromString("XCTestCase") == nil else { return }
        
        Task.detached(priority: .background) {
            let governance = ServiceContainer.shared.resolve((any GovernanceRepository).self)
            let promptTokens = (systemPrompt.count + query.count) / BusinessConstants.AI.charactersPerToken
            let completionTokens = response.count / BusinessConstants.AI.charactersPerToken
            
            _ = try? await governance.logCall(model: modelName, promptTokens: promptTokens, completionTokens: completionTokens, latencyMS: latency, status: AppConstants.Storage.defaultCallStatus)
            _ = try? await governance.logTokenUsage(model: modelName, promptTokens: promptTokens, completionTokens: completionTokens)

            let evalService = ServiceContainer.shared.resolve(RAGEvaluationService.self)
            _ = await evalService.evaluate(query: query, answer: response, context: context)
        }
    }
}
