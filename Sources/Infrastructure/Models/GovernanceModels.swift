// GovernanceModels.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：[Infra] AI 治理领域模型：包含 Token 使用统计、调用日志与 RAG 质量评估记录。
// 版本: 1.1
// 修改记录:
//   - 2026-05-16: 移除 didInsert 的显式定义，依靠 GRDB 自动回填自增 ID。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import GRDB

// MARK: - Token 使用量模型
/// 用于统计 AI 模型消耗的 Token 数据
public struct TokenUsage: Identifiable, Codable, FetchableRecord, MutablePersistableRecord, Sendable {
    public static let databaseTableName: String = AppConstants.Storage.Tables.tokenUsage
    
    public var id: Int64?
    public var model: String
    public var promptTokens: Int
    public var completionTokens: Int
    public var totalTokens: Int
    public var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case model
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
        case createdAt = "created_at"
    }
    
    public enum Columns {
        static let id = Column(CodingKeys.id)
        static let model = Column(CodingKeys.model)
        static let promptTokens = Column(CodingKeys.promptTokens)
        static let completionTokens = Column(CodingKeys.completionTokens)
        static let totalTokens = Column(CodingKeys.totalTokens)
        static let createdAt = Column(CodingKeys.createdAt)
    }
    
    public init(id: Int64? = nil, model: String, promptTokens: Int, completionTokens: Int, createdAt: Date = Date()) {
        self.id = id
        self.model = model
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = promptTokens + completionTokens
        self.createdAt = createdAt
    }
}

// MARK: - RAG 质量评估模型
/// 用于存储 LLM-as-a-Judge 对回答质量的自动评估结果
public struct RAGEvaluation: Identifiable, Codable, FetchableRecord, MutablePersistableRecord, Sendable {
    public static let databaseTableName: String = AppConstants.Storage.Tables.ragEvaluations
    
    public var id: Int64?
    public var query: String
    public var answer: String
    public var faithfulness: Double
    public var relevance: Double
    public var precision: Double
    public var evaluatorModel: String
    public var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case query
        case answer
        case faithfulness = "faithfulness_score"
        case relevance = "relevance_score"
        case precision = "context_precision"
        case evaluatorModel = "evaluator_model"
        case createdAt = "created_at"
    }
    
    public enum Columns {
        static let id = Column(CodingKeys.id)
        static let query = Column(CodingKeys.query)
        static let answer = Column(CodingKeys.answer)
        static let faithfulness = Column(CodingKeys.faithfulness)
        static let relevance = Column(CodingKeys.relevance)
        static let precision = Column(CodingKeys.precision)
        static let evaluatorModel = Column(CodingKeys.evaluatorModel)
        static let createdAt = Column(CodingKeys.createdAt)
    }
    
    public init(
        id: Int64? = nil,
        query: String,
        answer: String,
        faithfulness: Double,
        relevance: Double,
        precision: Double,
        evaluatorModel: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.query = query
        self.answer = answer
        self.faithfulness = faithfulness
        self.relevance = relevance
        self.precision = precision
        self.evaluatorModel = evaluatorModel
        self.createdAt = createdAt
    }
}

// MARK: - LLM 调用日志模型（完整 ORM 支持版）
/// LLM 调用详细日志模型，迁移自协议定义文件
public struct LLMCallLog: Identifiable, Codable, FetchableRecord, MutablePersistableRecord, Sendable {
    public static let databaseTableName: String = AppConstants.Storage.Tables.llmCallLogs
    
    public var id: Int64?
    public let model: String
    public let promptTokens: Int
    public let completionTokens: Int
    public let latencyMS: Int
    public let status: String
    public let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case model
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case latencyMS = "latency_ms"
        case status
        case createdAt = "created_at"
    }
    
    public enum Columns {
        static let id = Column(CodingKeys.id)
        static let model = Column(CodingKeys.model)
        static let promptTokens = Column(CodingKeys.promptTokens)
        static let completionTokens = Column(CodingKeys.completionTokens)
        static let latencyMS = Column(CodingKeys.latencyMS)
        static let status = Column(CodingKeys.status)
        static let createdAt = Column(CodingKeys.createdAt)
    }
    
    public init(
        id: Int64? = nil,
        model: String,
        promptTokens: Int,
        completionTokens: Int,
        latencyMS: Int,
        status: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.model = model
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.latencyMS = latencyMS
        self.status = status
        self.createdAt = createdAt
    }
}
