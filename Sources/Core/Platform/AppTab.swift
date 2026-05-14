// AppTab.swift
//
// 作者: Wang Chong
// 功能说明: 应用程序主 Tab 定义
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-04
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 应用程序顶层主 Tab 定义
/// 每个 Case 对应应用底部的 TabBar 按钮或 iPad 模式下的顶层导航分类。
enum AppTab: String, CaseIterable {
    /// 知识库核心：包含页面列表、仪表盘等核心资产管理
    case knowledge
    
    /// AI 智能对话：基于 RAG 的语义问答与创作中心
    case chat
    
    /// 知识摄取：OCR、网页裁剪、PDF 导入等数据入口
    case ingest
    
    /// 全局搜索：混合检索与语义过滤引擎
    case search
    
    /// 知识图谱：可视化节点关联与社区发现
    case graph
    
    var displayTitle: String {
        switch self {
        case .knowledge: return Localized.tr("tab.knowledge")
        case .chat: return Localized.tr("tab.chat")
        case .graph: return Localized.tr("tab.graph")
        case .search: return Localized.tr("tab.search")
        case .ingest: return Localized.tr("tab.ingest")
        }
    }
    
    var icon: String {
        switch self {
        case .knowledge: return "books.vertical.fill"
        case .chat: return "sparkles"
        case .graph: return "circle.hexagongrid.fill"
        case .search: return "magnifyingglass"
        case .ingest: return "tray.and.arrow.down.fill"
        }
    }
}
