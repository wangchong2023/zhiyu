// AppTab.swift
//
// 作者: Wang Chong
// 功能说明: 本文件定义了应用程序的主 Tab (AppTab)，作为全局导航架构的核心分类。
// 这些分类直接映射到 iOS 底部的 TabBar 以及 iPad/Mac 模式下的适配侧边栏。
//
// 版本: 1.1
// 修改记录:
//   - 2026-05-04: 初始功能实现。
//   - 2026-05-15: 导航架构现代化重构：
//     1. 移除独立搜索 Tab，将其整合至知识库侧边栏。
//     2. 将“知识合成”升级为一级 Tab，强化 AI 产出能力。
//
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
        case .knowledge: return Localized.tr("tab.knowledge")
        case .chat: return Localized.tr("tab.chat")
        case .graph: return Localized.tr("tab.graph")
        case .synthesis: return Localized.tr("tab.synthesis")
        case .ingest: return Localized.tr("tab.ingest")
        }
    }
    
    /// 获取 Tab 在 UI 上显示的 SF Symbols 图标名称
    /// - Returns: 图标名称字符串
    var icon: String {
        switch self {
        case .knowledge: return "books.vertical.fill"
        case .chat: return DesignSystem.Icons.sparkles
        case .graph: return "circle.hexagongrid.fill"
        case .synthesis: return "wand.and.stars"
        case .ingest: return "tray.and.arrow.down.fill"
        }
    }
}
