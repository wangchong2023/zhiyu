//
//  GraphDataProvider.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：属于 Service 模块，提供相关的结构体或工具支撑。
//
import Foundation
import Combine

/// 图谱数据提供者协议 (Module Designer 视角：实现视图与具体 Store 的解耦)
@MainActor
protocol GraphDataProvider: ObservableObject {
    var pages: [KnowledgePage] { get }
    var clusters: [GraphClusteringService.Cluster] { get }
    var isScanningAI: Bool { get }
    
    // AI 状态
    var isAIProcessing: Bool { get }
    
    /// 触发图谱重新布局
    func requestRelayout()
}
