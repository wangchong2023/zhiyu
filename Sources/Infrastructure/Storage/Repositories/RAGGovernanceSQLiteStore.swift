//
//  RAGGovernanceSQLiteStore.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：RAG 全链路质量治理 SQLite 存储实现。
//
import Foundation
import GRDB

/// [Infra] RAG 全链路质量治理 SQLite 存储
final class RAGGovernanceSQLiteStore: RAGGovernanceRepository, @unchecked Sendable {
    private var dbWriter: any DatabaseWriter {
        get async {
            await MainActor.run {
                // 动态获取当前活跃的数据库写入器以记录 AI 治理数据。若处于测试冷启动中，则降级创建内存数据库队列。
                if let writer = DatabaseManager.shared.dbWriter {
                    return writer
                }
                do { return try DatabaseQueue() } catch { fatalError("无法创建内存数据库(GovernanceRepo): \(error)") }
            }
        }
    }

    init(dbWriter: any DatabaseWriter) {
        // 保留原构造函数，但内部实际上不持有静态 dbWriter，使用动态计算属性以支持多笔记本金库无缝热切换并消除 closed 连接挂起隐慢
    }

    // MARK: - Token 计费 (Usage)

    /// 记录日志TokenUsage
    /// - Parameter model: model
    /// - Parameter promptTokens: promptTokens
    /// - Parameter completionTokens: completionTokens
    func logTokenUsage(model: String, promptTokens: Int, completionTokens: Int) async throws {
        let writer = await dbWriter
        try await writer.write { db in
            var usage = TokenUsage(model: model, promptTokens: promptTokens, completionTokens: completionTokens)
            try usage.insert(db)
        }
    }

    /// 拉取TokenStats
    /// - Parameter days: days
    /// - Returns: 返回值
    func fetchTokenStats(days: Int) async throws -> (prompt: Int, completion: Int, total: Int) {
        let writer = await dbWriter
        return try await writer.read { db in
            let dateThreshold = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            
            let request = TokenUsage
                .filter(TokenUsage.Columns.createdAt >= dateThreshold)
                .select(
                    sum(TokenUsage.Columns.promptTokens),
                    sum(TokenUsage.Columns.completionTokens),
                    sum(TokenUsage.Columns.totalTokens)
                )
            
            if let row = try Row.fetchOne(db, request) {
                return (
                    prompt: row[0] ?? 0,
                    completion: row[1] ?? 0,
                    total: row[2] ?? 0
                )
            }
            return (0, 0, 0)
        }
    }

    /// 拉取DailyAIStats
    /// - Parameter days: days
    /// - Returns: 列表
    func fetchDailyAIStats(days: Int) async throws -> [(date: String, tokens: Int, requests: Int)] {
        let writer = await dbWriter
        return try await writer.read { db in
            let dateThreshold = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            
            let dayExpr = SQL("strftime('%Y-%m-%d', \(TokenUsage.Columns.createdAt))")
            let request = TokenUsage
                .filter(TokenUsage.Columns.createdAt >= dateThreshold)
                .select(
                    dayExpr.forKey("day"),
                    sum(TokenUsage.Columns.totalTokens).forKey("tokens"),
                    count(TokenUsage.Columns.id).forKey("requests")
                )
                .group(dayExpr)
                .order(dayExpr)
            
            let rows = try Row.fetchAll(db, request)
            
            return rows.map { row in (
                date: row["day"] ?? "",
                tokens: row["tokens"] ?? 0,
                requests: row["requests"] ?? 0
            ) }
        }
    }

    /// 拉取MonthlyTokenStats
    /// - Returns: 列表
    func fetchMonthlyTokenStats() async throws -> [(month: String, total: Int)] {
        let writer = await dbWriter
        return try await writer.read { db in
            let monthExpr = SQL("strftime('%Y-%m', \(TokenUsage.Columns.createdAt))")
            let request = TokenUsage
                .select(
                    monthExpr.forKey("month"),
                    sum(TokenUsage.Columns.totalTokens).forKey("total")
                )
                .group(monthExpr)
                .order(monthExpr)
            
            let rows = try Row.fetchAll(db, request)
            
            return rows.map { row in (
                month: row["month"] ?? "",
                total: row["total"] ?? 0
            ) }
        }
    }

    // MARK: - 调用日志 (Logs)

    /// 记录日志Call
    /// - Parameter model: model
    /// - Parameter promptTokens: promptTokens
    /// - Parameter completionTokens: completionTokens
    /// - Parameter latencyMS: latencyMS
    /// - Parameter status: status
    func logCall(model: String, promptTokens: Int, completionTokens: Int, latencyMS: Int, status: String) async throws {
        let writer = await dbWriter
        try await writer.write { db in
            var log = LLMCallLog(
                model: model,
                promptTokens: promptTokens,
                completionTokens: completionTokens,
                latencyMS: latencyMS,
                status: status
            )
            try log.insert(db)
        }
    }

    /// 拉取RecentLogs
    /// - Parameter limit: limit
    /// - Returns: 列表
    func fetchRecentLogs(limit: Int) async throws -> [LLMCallLog] {
        let writer = await dbWriter
        return try await writer.read { db in
            try LLMCallLog
                .order(LLMCallLog.Columns.createdAt.desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    // MARK: - RAG 评估 (Evaluations)

    /// 保存RAGEvaluation
    /// - Parameter evaluation: evaluation
    func saveRAGEvaluation(_ evaluation: RAGEvaluation) async throws {
        let writer = await dbWriter
        try await writer.write { db in
            var mutableEvaluation = evaluation
            try mutableEvaluation.insert(db)
        }
    }

    /// 拉取RAGEvaluations
    /// - Parameter limit: limit
    /// - Returns: 列表
    func fetchRAGEvaluations(limit: Int) async throws -> [RAGEvaluation] {
        let writer = await dbWriter
        return try await writer.read { db in
            try RAGEvaluation
                .order(RAGEvaluation.Columns.createdAt.desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    /// 计算AverageRAGScores（含幻觉率与引用准确度）
    /// - Parameter days: days
    /// - Returns: 五维均值元组
    func calculateAverageRAGScores(days: Int) async throws -> (
        faithfulness: Double,
        relevance: Double,
        precision: Double,
        hallucinationRate: Double,
        citationAccuracy: Double
    ) {
        let writer = await dbWriter
        return try await writer.read { db in
            let dateThreshold = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

            let request = RAGEvaluation
                .filter(RAGEvaluation.Columns.createdAt >= dateThreshold)
                .select(
                    average(RAGEvaluation.Columns.faithfulness),
                    average(RAGEvaluation.Columns.relevance),
                    average(RAGEvaluation.Columns.precision),
                    average(RAGEvaluation.Columns.hallucinationRate),
                    average(RAGEvaluation.Columns.citationAccuracy)
                )

            if let row = try Row.fetchOne(db, request) {
                return (
                    faithfulness: row[0] ?? 0.0,
                    relevance: row[1] ?? 0.0,
                    precision: row[2] ?? 0.0,
                    hallucinationRate: row[3] ?? 0.0,
                    citationAccuracy: row[4] ?? 0.0
                )
            }
            return (0.0, 0.0, 0.0, 0.0, 0.0)
        }
    }
}
