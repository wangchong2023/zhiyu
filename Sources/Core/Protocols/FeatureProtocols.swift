// FeatureProtocols.swift
//
// 作者: Wang Chong
// 功能说明: 业务功能模块协议定义，用于解耦 Features 层内部组件依赖。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// AI 知识综合服务协议
protocol AISynthesisServiceProtocol: Sendable {
    func summarize(content: String) async throws -> String
    func generateMindMap(content: String) async throws -> String
    func generateInsightfulQuestions(pages: [KnowledgePage]) async throws -> [String]
    // 根据需要补充其他业务方法
}

/// 聊天服务协议
protocol ChatServiceProtocol: Sendable {
    // 定义 ChatService 的能力
}
