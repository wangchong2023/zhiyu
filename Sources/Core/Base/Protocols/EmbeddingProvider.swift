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

/// 抽象的文本嵌入向量化（Embedding）服务提供商协议。
protocol EmbeddingProvider {
    /// 将给定的非结构化文本异步编码为高维浮点向量。
    ///
    /// - Parameter text: 待向量化的原始正文字符串。
    /// - Returns: 计算出的特征值向量数组。
    /// - Throws: 异常于模型推理或网络分发失败。
    func embed(text: String) async throws -> [Float]
    
    /// 根据查询词快速计算并返回 TopK 个最相似的页面或分块 ID。
    ///
    /// - Parameters:
    ///   - query: 查询关键字或句。
    ///   - topK: 最多召回的候选数量。
    /// - Returns: 匹配命中的页面 UUID 标识和相似度得分列表。
    func search(query: String, topK: Int) -> [(id: UUID, score: Float)]
}

