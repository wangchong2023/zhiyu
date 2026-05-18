// AIAnalyticsService.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：AI 分析与指标记录服务，负责 Token 消耗、时延统计及 RAG 质量评估触发。
// 版本: 1.0
// 修改记录:
//   - 2026-05-18: 从 LLMService 剥离指标逻辑，实现性能监控解耦。
// 版权: © 2026 Wang Chong。保留所有权利。

import Foundation

/// AI 指标分析服务 (L1-Infra)
public final class AIAnalyticsService: Sendable {
    
    public init() {}

    /// 记录单次 LLM 调用指标
    public func recordUsage(model: String, response: [String: Any], latency: Int) {
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
