// FeatureProtocols.swift
//
// 作者: Wang Chong
// 功能说明: [L1.5] 领域中心层：业务功能模块协议定义，用于解耦 Features 层内部组件依赖。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 身份认证服务协议
@MainActor
public protocol AuthServiceProtocol {
    var isAuthenticated: Bool { get }
    var isGuest: Bool { get }
    var currentUser: User? { get }
    func continueAsGuest()
    func login(identity: String, password: String) async -> Bool
    func register(phone: String, code: String, password: String) async -> Bool
    func logout()
}

/// 笔记本/库管理服务协议
@MainActor
public protocol VaultServiceProtocol {
    var vaults: [Vault] { get }
    var selectedVaultID: UUID? { get }
    var currentVault: Vault? { get }
    func selectVault(_ vault: Vault)
    func exitVault()
    func createVault(name: String, icon: String?, description: String?)
    func updateVault(id: UUID, name: String, icon: String?, description: String?)
    func renameVault(id: UUID, newName: String)
    func deleteVault(id: UUID)
}

/// AI 知识综合服务协议
public protocol AISynthesisServiceProtocol: Sendable {
    func summarize(content: String) async throws -> String
    func generateMindMap(content: String) async throws -> String
    func generateInsightfulQuestions(pages: [KnowledgePage]) async throws -> [String]
}

/// 聊天服务协议
@MainActor
protocol ChatServiceProtocol: Sendable {
    func loadHistory() -> [ChatMessage]
    func clearHistory()
    func streamChat(query: String, pages: [KnowledgePage]) -> AsyncThrowingStream<String, Error>
    func saveAssistantMessage(_ content: String)
    func saveUserMessage(_ content: String)
}
