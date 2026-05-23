//
//  DashboardModels.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：属于 Model 模块，提供相关的结构体或工具支撑。
//
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
