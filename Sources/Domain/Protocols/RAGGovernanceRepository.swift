//
//  GovernanceRepository.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：领域层协议定义（Repository、Service、Strategy 等抽象）。
//
import Foundation

/// [Domain] RAG 全链路质量治理仓储协议（评估、Token 审计、调用日志）
public protocol RAGGovernanceRepository: Sendable {
    // MARK: - Token 计费 (Usage)
    
    /// 记录 Token 消耗情况
    func logTokenUsage(model: String, promptTokens: Int, completionTokens: Int) async throws
    
    /// 获取指定天数内的 Token 统计数据 (汇总)
    func fetchTokenStats(days: Int) async throws -> (prompt: Int, completion: Int, total: Int)
    
    /// 获取每日统计详情 (用于图表)
    func fetchDailyAIStats(days: Int) async throws -> [(date: String, tokens: Int, requests: Int)]
    
    /// 获取月度统计详情
    func fetchMonthlyTokenStats() async throws -> [(month: String, total: Int)]

    // MARK: - 调用日志 (Logs)
    
    /// 记录单次 LLM 调用详情
    func logCall(model: String, promptTokens: Int, completionTokens: Int, latencyMS: Int, status: String) async throws
    
    /// 获取最近的调用日志
    func fetchRecentLogs(limit: Int) async throws -> [LLMCallLog]

    // MARK: - RAG 评估 (Evaluations)
    
    /// 保存 RAG 评估结果
    func saveRAGEvaluation(_ evaluation: RAGEvaluation) async throws
    
    /// 获取最近的评估结果
    func fetchRAGEvaluations(limit: Int) async throws -> [RAGEvaluation]
    
    /// 计算平均评估得分（包含生成质量与引用保真指标）
    func calculateAverageRAGScores(days: Int) async throws -> (
        faithfulness: Double,
        relevance: Double,
        precision: Double,
        hallucinationRate: Double,
        citationAccuracy: Double
    )

    // MARK: - 检索快照 (Retrieval Snapshots)

    /// 保存检索快照（评估时记录完整 Top-N 排序结果）
    func saveRetrievalSnapshots(_ snapshots: [RetrievalSnapshot]) async throws

    /// 获取某次评估的检索快照
    func fetchRetrievalSnapshots(evaluationID: Int64) async throws -> [RetrievalSnapshot]

    // MARK: - 相关性标注 (Relevance Judgments)

    /// 保存相关性标注
    func saveRelevanceJudgments(_ judgments: [RelevanceJudgment]) async throws

    // MARK: - 检索质量指标 (Retrieval Metrics)

    /// Hit Rate@K：Top-K 结果中至少命中一个相关文档的查询占比
    func calculateHitRate(days: Int, k: Int) async throws -> Double

    /// MRR (Mean Reciprocal Rank)：首个相关文档排名的倒数均值
    func calculateMRR(days: Int) async throws -> Double

    /// NDCG@K (Normalized Discounted Cumulative Gain)：归一化折损累计增益
    func calculateNDCG(days: Int, k: Int) async throws -> Double
}
