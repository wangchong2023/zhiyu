//
//  DTOs.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：跨层协议定义，建立 L0-L3 各层间的抽象契约。
//
import Foundation

// MARK: - 协议定义

/// [Infra] 知识页面表征协议
/// 定义了知识页面在参与 LLM 交互时所需的核心属性，用于跨模块类型抹除。
public protocol KnowledgePageRepresentable: Sendable {
    var id: UUID { get }
    var title: String { get }
    var content: String { get }
    var tags: [String] { get }
    var pageType: PageType { get }
}

// MARK: - 基础 DTO

/// 统一的对话消息传输对象
public struct ChatMessageDTO: Codable, Identifiable, Sendable {
    public var id = UUID()
    public let role: ChatRole
    public let content: String
    public var timestamp = Date()
    public var relatedPageIDs: [UUID] = []
    
    public enum ChatRole: String, Codable, Sendable {
        case user
        case assistant
        case system
    }
    
    public init(id: UUID = UUID(), role: ChatRole, content: String, timestamp: Date = Date(), relatedPageIDs: [UUID] = []) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.relatedPageIDs = relatedPageIDs
    }
}

// MARK: - Chat Message Alias
public typealias ChatMessage = ChatMessageDTO

// MARK: - 业务 DTO

/// 智能解析/摄入任务的结果传输对象
public struct SmartIngestResultDTO: Codable, Sendable {
    public let title: String?
    public let compiledContent: String
    public let suggestedTags: [String]
    public let suggestedType: String
    public let relatedTitles: [String]
    public let summary: String

    public enum CodingKeys: String, CodingKey {
        case title
        case compiledContent = "compiled_content"
        case suggestedTags = "suggested_tags"
        case suggestedType = "suggested_type"
        case relatedTitles = "related_titles"
        case summary
    }
    
    public init(
        title: String?,
        compiledContent: String,
        suggestedTags: [String],
        suggestedType: String,
        relatedTitles: [String],
        summary: String
    ) {
        self.title = title
        self.compiledContent = compiledContent
        self.suggestedTags = suggestedTags
        self.suggestedType = suggestedType
        self.relatedTitles = relatedTitles
        self.summary = summary
    }
}

// MARK: - 重构建议 DTO

/// 知识重构建议的传输对象
public struct RefactorSuggestionDTO: Codable, Identifiable, Sendable {
    public var id: String { target + type }
    public let type: String     // merge, split, rename
    public let target: String
    public let reason: String
    public let suggestion: String
    
    public init(type: String, target: String, reason: String, suggestion: String) {
        self.type = type
        self.target = target
        self.reason = reason
        self.suggestion = suggestion
    }
}

// MARK: - 日志审计 DTO

/// 操作执行状态
public enum LogStatus: String, Codable, Sendable {
    case success
    case failure
    case processing
    
    public var localizedName: String {
        switch self {
        case .success: return L10n.Common.Log.Status.success
        case .failure: return L10n.Common.Log.Status.failure
        case .processing: return L10n.Common.Log.Status.processing
        }
    }
}

/// 操作日志条目模型，记录系统操作的元数据
public struct LogEntry: Identifiable, Codable, Sendable {
    public var id: UUID
    public var action: LogAction
    public var target: String
    public var details: String
    public var timestamp: Date
    public var duration: TimeInterval?
    public var startTime: Date?
    public var endTime: Date?
    public var module: String? // 来源模块，如 SystemVault, AppStore
    public var status: LogStatus?
    public var failureReason: String?
    
    public init(
        id: UUID = UUID(),
        action: LogAction,
        target: String,
        details: String = "",
        timestamp: Date = Date(),
        duration: TimeInterval? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        module: String? = nil,
        status: LogStatus? = nil,
        failureReason: String? = nil
    ) {
        self.id = id
        self.action = action
        self.target = target
        self.details = details
        self.timestamp = timestamp
        self.duration = duration
        self.startTime = startTime
        self.endTime = endTime
        self.module = module
        self.status = status
        self.failureReason = failureReason
    }
}
