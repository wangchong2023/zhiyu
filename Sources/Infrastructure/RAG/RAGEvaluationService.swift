// RAGEvaluationService.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 领域服务：RAG 质量评估中心。采用 LLM-as-a-Judge 模式，对回答的忠实度、相关度进行自动打分。
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
    private let store: KnowledgePageStore

    init(llmService: any LLMServiceProtocol, store: KnowledgePageStore) {
        self.llmService = llmService
        self.store = store
    }

    /// 执行单次回答评估
    /// - Parameters:
    ///   - query: 原始问题
    ///   - answer: AI 生成的回答
    ///   - context: 检索到的上下文片段
    func evaluate(query: String, answer: String, context: String) async -> EvaluationReport {
        let prompt = """
        你是一个 RAG 系统评估专家。请根据以下三个维度对 AI 的回答进行评分 (0.0 - 1.0)：
        1. Faithfulness (忠实度): 回答是否完全基于提供的上下文？是否有幻觉？
        2. Relevance (相关度): 回答是否直接且完整地解决了用户的问题？
        3. Context Precision (上下文精确度): 提供的上下文是否真的包含回答问题所需的知识？

        Context: \(context)
        Query: \(query)
        Answer: \(answer)

        请严格按以下 JSON 格式返回评分：
        {
          "faithfulness": 0.9,
          "relevance": 0.8,
          "precision": 0.9,
          "reasoning": "简要说明理由"
        }
        """

        do {
            let response = try await llmService.generate(prompt: prompt, systemPrompt: "你是一个客观公正的评估机器人。")
            if let data = response.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

                let f = (json[EvaluationMetric.faithfulness.rawValue] as? Double) ?? 0.0
                let r = (json[EvaluationMetric.relevance.rawValue] as? Double) ?? 0.0
                let p = (json[EvaluationMetric.precision.rawValue] as? Double) ?? 0.0

                let status = f < 0.7 ? "Warning" : (f < 0.5 ? "Fail" : "Pass")

                // 持久化评估结果到数据库
                try? store.saveEvaluation(
                    query: query,
                    answer: answer,
                    scores: [
                        EvaluationMetric.faithfulness.rawValue: f,
                        EvaluationMetric.relevance.rawValue: r,
                        EvaluationMetric.precision.rawValue: p
                    ],
                    model: AppModel.evaluator.rawValue
                )

                return EvaluationReport(query: query, answer: answer, faithfulness: f, relevance: r, precision: p, status: status)
            }
        } catch {
            print("Evaluation failed: \(error)")
        }

        return EvaluationReport(query: query, answer: answer, faithfulness: 0, relevance: 0, precision: 0, status: "Error")
    }
}
