// GovernanceRepository.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：[Infra] 治理仓库协议：负责 Token 计费、调用日志及 RAG 质量评估数据的持久化。
// 实现 AI 观测性（Observability）与核心存储的解耦。
// 版本: 1.0
// 日期: 2026-05-15
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// [Infra] 治理仓库协议
/// 专门负责 token_usage, llm_call_logs 和 rag_evaluations 表的操作。
protocol GovernanceRepository: Sendable {
    
    // MARK: - Token 计费 (Usage)
    
    /// 记录 Token 使用量
    func logTokenUsage(model: String, promptTokens: Int, completionTokens: Int) async throws
    
    /// 获取近期的 Token 使用统计
    func fetchTokenStats(days: Int) async throws -> (prompt: Int, completion: Int, total: Int)
    
    /// 获取每日 AI 资源统计 (日期, Token, 请求数)
    func fetchDailyAIStats(days: Int) async throws -> [(date: String, tokens: Int, requests: Int)]
    
    /// 获取每月 Token 统计 (月份, 总量)
    func fetchMonthlyTokenStats() async throws -> [(month: String, total: Int)]
    
    // MARK: - 调用日志 (Logs)
    
    /// 记录 LLM 调用详细日志
    func logCall(model: String, promptTokens: Int, completionTokens: Int, latencyMS: Int, status: String) async throws
    
    /// 获取最近的调用记录
    func fetchRecentLogs(limit: Int) async throws -> [LLMCallLog]
    
    // MARK: - RAG 评估 (Evaluations)
    
    /// 保存 RAG 评估结果
    func saveEvaluation(query: String, answer: String, faithfulness: Double, relevance: Double, precision: Double, model: String) async throws
    
    /// 获取平均评估指标
    func fetchAverageMetrics() async throws -> (faithfulness: Double, relevance: Double, precision: Double)
}
