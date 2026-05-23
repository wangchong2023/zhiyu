//
//  LLMServiceProtocol.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：定义 LLMService 模块的抽象契约接口。
//
import Foundation
import Combine

// MARK: - LLM 对话服务协议 (核心推理与对话)

@MainActor
protocol LLMChatServiceProtocol: AnyObject, Sendable {
    var isEnabled: Bool { get }

    // MARK: - 核心对话与推理
    func chat(query: String, history: [ChatMessageDTO], pages: [any KnowledgePageRepresentable]) async throws -> ChatMessageDTO
    func chatStream(query: String, history: [ChatMessageDTO], pages: [any KnowledgePageRepresentable]) -> AsyncThrowingStream<String, Error>

    /// 通用生成接口
    /// - Parameters:
    ///   - prompt: 提示词
    ///   - systemPrompt: 可选的系统提示词
    func generate(prompt: String, systemPrompt: String) async throws -> String
}

// MARK: - LLM 知识维护服务协议

@MainActor
protocol LLMKnowledgeServiceProtocol: AnyObject, Sendable {
    func smartIngest(title: String, rawContent: String, pages: [any KnowledgePageRepresentable]) async throws -> SmartIngestResultDTO
    func discoverPotentialLinks(content: String, existingTitles: [String]) async throws -> [String]
    func foldContent(existingContent: String, newContent: String, title: String) async throws -> String
    func analyzeForRefactoring(pages: [any KnowledgePageRepresentable]) async throws -> [RefactorSuggestionDTO]
}

// MARK: - LLM 检索增强服务协议

@MainActor
protocol LLMRetrievalServiceProtocol: AnyObject, Sendable {
    func rewriteQuery(_ query: String) async -> String
    func expandQuery(_ query: String) async -> [String]
    func rerank(query: String, candidates: [any KnowledgePageRepresentable]) async throws -> [any KnowledgePageRepresentable]
    func rerankChunks(query: String, chunks: [PageChunk]) async -> [PageChunk]
    func generateHypotheticalDocument(query: String) async -> String
}

// MARK: - LLM 服务组合协议

/// 继承所有子协议，保持向后兼容
@MainActor
protocol LLMServiceProtocol: ObservableObject, LLMChatServiceProtocol, LLMKnowledgeServiceProtocol, LLMRetrievalServiceProtocol {}
