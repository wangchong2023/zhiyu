// StoreCapabilities.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：定义存储层的细粒度能力协议，用于在不暴露具体存储实现的情况下提供高级功能（如向量化、搜索）。
// 版本: 1.0
// 修改记录:
//   - 2026-05-07: 初始版本，解耦 IngestService 与 SQLiteStore。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
/// 具备向量化能力的存储协议
@MainActor
protocol VectorIndexableStore: Sendable {
    var embeddingManager: EmbeddingManager { get }
}

/// 具备监控与可观测性的存储协议
@MainActor
protocol MonitorableStore: Sendable {
    func addLog(action: LogAction, target: String, details: String, duration: TimeInterval?, startTime: Date?, endTime: Date?, module: String?)
}
