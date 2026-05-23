//
//  AIGovernanceRepository.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：属于 Repositories 模块，提供相关的结构体或工具支撑。
//
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

    func saveRAGEvaluation(_ evaluation: RAGEvaluation) async throws {
        try await dbWriter.write { db in
            var mutableEvaluation = evaluation
            try mutableEvaluation.insert(db)
        }
    }

    func fetchRAGEvaluations(limit: Int) async throws -> [RAGEvaluation] {
        try await dbWriter.read { db in
            try RAGEvaluation
                .order(RAGEvaluation.Columns.createdAt.desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    func calculateAverageRAGScores(days: Int) async throws -> (faithfulness: Double, relevance: Double, precision: Double) {
        try await dbWriter.read { db in
            let dateThreshold = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            
            let request = RAGEvaluation
                .filter(RAGEvaluation.Columns.createdAt >= dateThreshold)
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
