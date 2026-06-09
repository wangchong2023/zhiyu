//
//  RAGEvaluationService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：实现 RAGEvaluation 模块的核心业务逻辑服务。
//
import Foundation

/// RAG 质量评估报告模型
struct EvaluationReport: Identifiable {
    let id = UUID()
    let query: String
    let answer: String
    let faithfulness: Double       // 忠实度 (0-1)
    let relevance: Double          // 相关度 (0-1)
    let precision: Double          // 上下文精确度 (0-1)
    let hallucinationRate: Double  // 幻觉率 (0-1)，越低越好
    let citationAccuracy: Double   // 引用准确度 (0-1)，越高越好
    let status: String             // "Pass" | "Warning" | "Fail"
}

/// [L2] 领域服务：RAG 质量评估中心
final class RAGEvaluationService {
    private let llmService: any LLMServiceProtocol
    private let governanceStore: any RAGGovernanceRepository

    init(llmService: any LLMServiceProtocol, governanceStore: any RAGGovernanceRepository) {
        self.llmService = llmService
        self.governanceStore = governanceStore
    }

    /// 执行单次回答评估
    /// - Parameters:
    ///   - query: 原始问题
    ///   - answer: AI 生成的回答
    ///   - context: 检索到的上下文片段
    func evaluate(query: String, answer: String, context: String) async -> EvaluationReport {
        let prompt = L10n.AI.Eval.judgePrompt(context, query, answer)
        let systemPrompt = L10n.AI.Eval.systemPrompt

        do {
            let response = try await llmService.generate(prompt: prompt, systemPrompt: systemPrompt)
            if let data = response.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

                let f = (json[EvaluationMetric.faithfulness.rawValue] as? Double) ?? 0.0
                let r = (json[EvaluationMetric.relevance.rawValue] as? Double) ?? 0.0
                let p = (json[EvaluationMetric.precision.rawValue] as? Double) ?? 0.0
                let h = (json[EvaluationMetric.hallucinationRate.rawValue] as? Double) ?? 0.0
                let c = (json[EvaluationMetric.citationAccuracy.rawValue] as? Double) ?? 0.0

                let status: String
                if f < 0.5 {
                    status = L10n.AI.Eval.Status.fail
                } else if f < 0.7 {
                    status = L10n.AI.Eval.Status.warning
                } else {
                    status = L10n.AI.Eval.Status.pass
                }

                // 持久化评估结果到数据库
                let eval = RAGEvaluation(
                    query: query,
                    answer: answer,
                    faithfulness: f,
                    relevance: r,
                    precision: p,
                    hallucinationRate: h,
                    citationAccuracy: c,
                    evaluatorModel: AppConfig.AI.evaluatorModel
                )
                try? await governanceStore.saveRAGEvaluation(eval)

                return EvaluationReport(
                    query: query,
                    answer: answer,
                    faithfulness: f,
                    relevance: r,
                    precision: p,
                    hallucinationRate: h,
                    citationAccuracy: c,
                    status: status
                )
            }
        } catch {
            print("Evaluation failed:" + " \(error)")
        }

        return EvaluationReport(
            query: query, answer: answer,
            faithfulness: 0, relevance: 0, precision: 0,
            hallucinationRate: 0, citationAccuracy: 0,
            status: L10n.AI.Eval.Status.error
        )
    }
}
