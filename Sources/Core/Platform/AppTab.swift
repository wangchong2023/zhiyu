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

/// 应用程序主 Tab 定义
enum AppTab: String, CaseIterable {
    case knowledge = "wiki" // 保持原始 RawValue 以保证 UserDefaults 兼容性
    case chat
    case ingest
    case search
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
