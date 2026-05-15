// DashboardModels.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：仪表盘模块相关数据模型
// 版本: 1.0
// 修改记录:
//   - 2026-05-15: 从 KnowledgeDashboardView 提取，支持架构解耦。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 知识密度信息，用于图表展示
public struct DensityInfo: Identifiable, Sendable {
    public let id = UUID()
    public let name: String
    public let inbound: Double
    public let outbound: Double
    
    public init(name: String, inbound: Double, outbound: Double) {
        self.name = name
        self.inbound = inbound
        self.outbound = outbound
    }
}
