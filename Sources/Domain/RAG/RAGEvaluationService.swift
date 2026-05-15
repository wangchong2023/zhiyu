// RAGEvaluationService.swift
//
// 作者: Wang Chong
// 功能说明: [L1.5] 领域中心层：RAG 质量评估中心。采用 LLM-as-a-Judge 模式，对回答的忠实度、相关度进行自动打分。
// 版本: 1.0
// 日期: 2026-05-06
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// RAG 质量评估报告模型
struct EvaluationReport: Identifiable {
    let id = UUID()
    let query: String
    let answer: String
    let faithfulness: Double // 忠实度 (0-1)
    let relevance: Double    // 相关度 (0-1)
    let precision: Double    // 上下文精确度 (0-1)
    let status: String       // "Pass" | "Warning" | "Fail"
}

/// [L2] 领域服务：RAG 质量评估中心
final class RAGEvaluationService {
    private let llmService: any LLMServiceProtocol
    private let governanceStore: any GovernanceRepository

    init(llmService: any LLMServiceProtocol, governanceStore: any GovernanceRepository) {
        self.llmService = llmService
        self.governanceStore = governanceStore
    }

    /// 执行单次回答评估
    /// - Parameters:
    ///   - query: 原始问题
    ///   - answer: AI 生成的回答
    ///   - context: 检索到的上下文片段
    func evaluate(query: String, answer: String, context: String) async -> EvaluationReport {
        let prompt = Localized.trf("llm.eval.judgePrompt", table: "AITasks", context, query, answer)
        let systemPrompt = Localized.tr("llm.eval.systemPrompt", table: "AITasks")

        do {
            let response = try await llmService.generate(prompt: prompt, systemPrompt: systemPrompt)
            if let data = response.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

                let f = (json[EvaluationMetric.faithfulness.rawValue] as? Double) ?? 0.0
                let r = (json[EvaluationMetric.relevance.rawValue] as? Double) ?? 0.0
                let p = (json[EvaluationMetric.precision.rawValue] as? Double) ?? 0.0

                let status: String
                if f < 0.5 {
                    status = Localized.tr("llm.eval.status.fail", table: "AITasks")
                } else if f < 0.7 {
                    status = Localized.tr("llm.eval.status.warning", table: "AITasks")
                } else {
                    status = Localized.tr("llm.eval.status.pass", table: "AITasks")
                }

                // 持久化评估结果到数据库
                try? await governanceStore.saveEvaluation(
                    query: query,
                    answer: answer,
                    faithfulness: f,
                    relevance: r,
                    precision: p,
                    model: AppConfig.AI.evaluatorModel
                )

                return EvaluationReport(query: query, answer: answer, faithfulness: f, relevance: r, precision: p, status: status)
            }
        } catch {
            print("Evaluation failed: \(error)")
        }

        return EvaluationReport(query: query, answer: answer, faithfulness: 0, relevance: 0, precision: 0, status: Localized.tr("llm.eval.status.error", table: "AITasks"))
    }
}
