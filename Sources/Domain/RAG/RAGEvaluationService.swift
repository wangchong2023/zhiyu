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
import CryptoKit

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

    /// 执行单次回答评估（含可选的检索源标注）
    /// - Parameters:
    ///   - query: 原始问题
    ///   - answer: AI 生成的回答
    ///   - context: 检索到的上下文片段（合并后）
    ///   - sources: 检索源列表（传入时触发检索快照记录 + 相关性标注）
    func evaluate(query: String, answer: String, context: String, sources: [KnowledgeSource]? = nil) async -> EvaluationReport {
        let hasSources = (sources?.isEmpty == false)
        let prompt: String
        if hasSources {
            prompt = Self.buildJudgePromptWithSources(context: context, query: query, answer: answer, sources: sources!)
        } else {
            prompt = L10n.AI.Eval.judgePrompt(context, query, answer)
        }
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

                // 持久化评估结果到数据库，然后查询回 ID
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
                // 查询最新评估获取自增 ID
                let savedEvals = (try? await governanceStore.fetchRAGEvaluations(limit: 1)) ?? []
                let savedEvalID = savedEvals.first.flatMap { $0.id }

                // 检索快照 + 相关性标注（仅当有 sources 时）
                if hasSources, let evalID = savedEvalID {
                    await recordRetrievalQuality(
                        evalID: evalID,
                        query: query,
                        sources: sources!,
                        relevanceScoresJSON: json["relevance_scores"] as? [Int]
                    )
                }

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
            Logger.shared.error("Evaluation failed", error: error)
        }

        return EvaluationReport(
            query: query, answer: answer,
            faithfulness: 0, relevance: 0, precision: 0,
            hallucinationRate: 0, citationAccuracy: 0,
            status: L10n.AI.Eval.Status.error
        )
    }

    // MARK: - 检索质量记录

    /// 记录检索快照与 LLM 标注的相关性数据
    private func recordRetrievalQuality(
        evalID: Int64,
        query: String,
        sources: [KnowledgeSource],
        relevanceScoresJSON: [Int]?
    ) async {
        let queryHash = Self.sha256(query)

        // 1. 保存检索快照（Top-N 排序结果）
        let snapshots: [RetrievalSnapshot] = sources.enumerated().map { idx, src in
            RetrievalSnapshot(
                evaluationID: evalID,
                rank: idx + 1,
                sourceID: src.id.uuidString,
                pageTitle: src.title,
                snippet: String(src.snippet.prefix(200)),
                score: src.score
            )
        }
        try? await governanceStore.saveRetrievalSnapshots(snapshots)

        // 2. 保存相关性标注（优先使用 LLM 返回的分数，回退到基于 score 的弱标注）
        let judgments: [RelevanceJudgment] = sources.enumerated().map { idx, src in
            let level: Int
            if let scores = relevanceScoresJSON, idx < scores.count {
                level = max(0, min(2, scores[idx]))
            } else {
                // 回退：基于相似度分数的启发式标注
                if src.score >= 0.8 { level = 2 }
                else if src.score >= 0.5 { level = 1 }
                else { level = 0 }
            }
            return RelevanceJudgment(
                queryHash: queryHash,
                query: query,
                sourceID: src.id.uuidString,
                relevanceLevel: level,
                judgeSource: relevanceScoresJSON != nil ? "llm-auto" : "heuristic",
                evaluationID: evalID
            )
        }
        try? await governanceStore.saveRelevanceJudgments(judgments)
    }

    // MARK: - 辅助

    private static func sha256(_ text: String) -> String {
        let hash = CryptoKit.SHA256.hash(data: Data(text.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// 构建含逐源相关性评判的 Prompt
    private static func buildJudgePromptWithSources(
        context: String,
        query: String,
        answer: String,
        sources: [KnowledgeSource]
    ) -> String {
        var sourceList = ""
        for (idx, src) in sources.prefix(20).enumerated() {
            sourceList += "[\(idx)] \(src.title): \(String(src.snippet.prefix(150)))\n"
        }

        return """
        你是一个 RAG 系统评估专家。请对以下 AI 回答进行多维评分 (0.0 - 1.0) 并评估各检索源的相关性。

        ## 检索到的文档源（共 \(sources.count) 条，仅展示前 \(min(20, sources.count)) 条）
        \(sourceList)

        ## 合并后的上下文
        \(String(context.prefix(3000)))

        ## 用户问题
        \(query)

        ## AI 回答
        \(answer)

        ## 评分要求
        1. faithfulness: 回答是否完全基于上下文？（1.0 = 完美忠实）
        2. relevance: 回答是否直接解决用户问题？（1.0 = 完美匹配）
        3. precision: 上下文是否包含回答问题所需的知识？（1.0 = 完美覆盖）
        4. hallucination_rate: 回答中无上下文支撑的内容占比？（0.0 = 无幻觉）
        5. citation_accuracy: 引用准确度？（1.0 = 完全准确）
        6. relevance_scores: 对上述每个检索源 [0]...[N] 标注相关性：0=无关, 1=部分相关, 2=高度相关

        ## 输出 JSON 格式
        {
          "faithfulness": 0.9,
          "relevance": 0.8,
          "precision": 0.85,
          "hallucination_rate": 0.1,
          "citation_accuracy": 0.8,
          "relevance_scores": [2, 1, 0, 2, ...],
          "reasoning": "简要说明"
        }
        """
    }
}
