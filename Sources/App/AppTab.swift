//
//  AppTab.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 应用层
//  核心职责：属于 App 模块，提供相关的结构体或工具支撑。
//
import Foundation

/// 应用程序顶层主 Tab 定义
/// 每个 Case 对应系统中的一个主要业务功能区。
/// 该枚举遵循 `String` 和 `CaseIterable` 协议，便于 UI 遍历与持久化存储。
enum AppTab: String, CaseIterable {
    /// 知识库核心：包含页面列表、仪表盘等核心资产管理
    case knowledge
    
    /// AI 智能对话：基于 RAG 的语义问答与创作中心
    case chat
    
    /// 知识摄取：OCR、网页裁剪、PDF 导入等数据入口
    case ingest
    
    /// 知识合成：将多个来源聚合为深度知识产出（如思维导图、测验等）
    case synthesis
    
    /// 知识图谱：可视化节点关联与社区发现
    case graph
    
    // MARK: - 辅助属性
    
    /// 获取 Tab 在 UI 上显示的本地化标题
    /// - Returns: 对应的本地化字符串
    var displayTitle: String {
        switch self {
        case .knowledge: return L10n.Common.Tab.knowledge
        case .chat: return L10n.Common.Tab.chat
        case .graph: return L10n.Common.Tab.graph
        case .synthesis: return L10n.Common.Tab.synthesis
        case .ingest: return L10n.Common.Tab.ingest
        }
    }
    
    /// 获取 Tab 在 UI 上显示的 SF Symbols 图标名称
    /// - Returns: 图标名称字符串
    var icon: String {
        switch self {
        case .knowledge: return DesignSystem.Icons.booksVerticalFill
        case .chat: return DesignSystem.Icons.sparkles
        case .graph: return DesignSystem.Icons.hexagonGridFill
        case .synthesis: return DesignSystem.Icons.wand
        case .ingest: return DesignSystem.Icons.trayArrowDown
        }
    }
}
