// GovernanceRepository.swift
//
// 作者: Wang Chong
// 功能说明: [L1.5] 领域中心层：AI 治理与监控数据仓库协议。
// 版本: 1.3
// 修改记录:
//   - 2026-05-16: 契约下沉：从 L1 迁移至 L1.5 领域层，实现依赖倒置。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// [Domain] AI 治理与观测性仓储协议
public protocol GovernanceRepository: Sendable {
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
    
    /// 计算平均评估得分
    func calculateAverageRAGScores(days: Int) async throws -> (faithfulness: Double, relevance: Double, precision: Double)
}
