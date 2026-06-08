//
//  AppModels.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 应用层
//  核心职责：全局状态管理（AppStore），持有应用级 @Observable 状态树。
//
import Foundation

// MARK: - 引导层类型

/// 用户引导层 (Coach Mark) 类型枚举
/// 标识需要向用户展示的一次性引导提示类型
public enum CoachMarkType: String, Sendable {
    /// 图谱探索引导
    case graphDiscovery = "graph_discovery"
}

// MARK: - 工具栏路由项

/// 应用内工具页面路由枚举
/// 对应侧边栏或工具栏中的各功能入口，与 SidebarSelection 共同构成路由系统
public enum ToolItem: String, CaseIterable, Hashable {
    case pageList     = "index"
    case dashboard    = "dashboard"
    case tagCloud     = "tagCloud"
    case taskCenter   = "chat"
    case chat         = "chat_ai"
    case synthesis    = "synthesis"
    case weeklyReport = "weeklyReport"
    case log          = "log"
    case collab       = "collab"
    case pluginMarket = "pluginMarket"
    case search       = "search"
    case ingest       = "ingest"
    case graph        = "graph"
    case lint         = "lint"
    case healthCheck  = "healthCheck"
    case sources      = "sources"
}

// MARK: - 知识增长趋势数据点

/// 知识库增长趋势数据点
/// 用于仪表盘折线图展示知识页面历史增长趋势
public struct KnowledgeGrowthPoint: Identifiable {
    /// 唯一标识符
    public let id = UUID()
    /// 该数据点对应的日期
    public let date: Date
    /// 截至该日期的知识页面累计数量
    public let count: Int

    public init(date: Date, count: Int) {
        self.date = date
        self.count = count
    }
}