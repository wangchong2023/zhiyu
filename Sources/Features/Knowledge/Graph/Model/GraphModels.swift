//
//  GraphModels.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：属于 Model 模块，提供相关的结构体或工具支撑。
//
import Foundation
import CoreGraphics

// MARK: - Graph Node
struct GraphNode: Identifiable {
    let id: UUID
    let title: String
    let pageType: PageType
    var position: CGPoint
    var isHighlighted: Bool = false
    var communityID: Int? = nil
    var communityCohesion: Double? = nil
    var linkCount: Int = 0
}

// MARK: - Graph Edge
struct GraphEdge: Identifiable {
    let id = UUID()
    let source: UUID
    let target: UUID
}
