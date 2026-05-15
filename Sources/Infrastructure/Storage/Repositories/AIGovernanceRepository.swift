// AIGovernanceRepository.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：[Infra] AI 治理存储实现：负责 Token 计费、调用日志及 RAG 质量评估记录。
// 遵循 GovernanceRepository 协议，采用 GRDB ORM 模式实现。
// 版本: 1.7
// 修改记录:
//   - 2026-05-16: 物理归位重构：更名为 AIGovernanceRepository。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import GRDB

/// [Infra] AI 治理存储实现
final class AIGovernanceRepository: GovernanceRepository, @unchecked Sendable {
    private let dbWriter: any DatabaseWriter

    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }

    // MARK: - Token 计费 (Usage)

    func logTokenUsage(model: String, promptTokens: Int, completionTokens: Int) async throws {
        try await dbWriter.write { db in
            var usage = TokenUsage(model: model, promptTokens: promptTokens, completionTokens: completionTokens)
            try usage.insert(db)
        }
    }

    func fetchTokenStats(days: Int) async throws -> (prompt: Int, completion: Int, total: Int) {
        try await dbWriter.read { db in
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

    func fetchDailyAIStats(days: Int) async throws -> [(date: String, tokens: Int, requests: Int)] {
        try await dbWriter.read { db in
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

    func fetchMonthlyTokenStats() async throws -> [(month: String, total: Int)] {
        try await dbWriter.read { db in
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

    func logCall(model: String, promptTokens: Int, completionTokens: Int, latencyMS: Int, status: String) async throws {
        try await dbWriter.write { db in
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

    func fetchRecentLogs(limit: Int) async throws -> [LLMCallLog] {
        try await dbWriter.read { db in
            try LLMCallLog
                .order(LLMCallLog.Columns.createdAt.desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    // MARK: - RAG 评估 (Evaluations)

    func saveEvaluation(query: String, answer: String, faithfulness: Double, relevance: Double, precision: Double, model: String) async throws {
        try await dbWriter.write { db in
            var evaluation = RAGEvaluation(
                query: query,
                answer: answer,
                faithfulness: faithfulness,
                relevance: relevance,
                precision: precision,
                evaluatorModel: model
            )
            try evaluation.insert(db)
        }
    }

    func fetchAverageMetrics() async throws -> (faithfulness: Double, relevance: Double, precision: Double) {
        try await dbWriter.read { db in
            let request = RAGEvaluation
                .select(
                    average(RAGEvaluation.Columns.faithfulness),
                    average(RAGEvaluation.Columns.relevance),
                    average(RAGEvaluation.Columns.precision)
                )
            
            if let row = try Row.fetchOne(db, request) {
                return (
                    faithfulness: row[0] ?? 0.0,
                    relevance: row[1] ?? 0.0,
                    precision: row[2] ?? 0.0
                )
            }
            return (0.0, 0.0, 0.0)
        }
    }
}
