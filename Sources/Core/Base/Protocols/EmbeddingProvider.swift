//
//  EmbeddingProvider.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：属于 Protocols 模块，提供相关的结构体或工具支撑。
//
import Foundation

/// 抽象 Embedding 能力协议
protocol EmbeddingProvider {
    func embed(text: String) async throws -> [Float]
    func search(query: String, topK: Int) -> [(id: UUID, score: Float)]
}
