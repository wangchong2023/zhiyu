//
//  AppTab.swift
//  ZhiYu
//
//  系统层级：[Domain] 领域模型层
//  核心职责：定义应用底座全局主标签页枚举（AppTab），包含标题及 SF Symbols 图标绑定。
//

import Foundation

/// 主标签页枚举
public enum AppTab: String, CaseIterable, Sendable {
    case knowledge
    case chat
    case ingest
    case synthesis
    case graph

    private enum Icon {
        static let knowledge = "book.fill"
        static let chat = "bubble.left.and.bubble.right.fill"
        static let ingest = "tray.and.arrow.down.fill"
        static let synthesis = "wand.and.stars"
        static let graph = "point.3.connected.trianglepath.dotted"
    }

    public var displayTitle: String {
        switch self {
        case .knowledge: return L10n.Common.Tab.knowledge
        case .chat: return L10n.Common.Tab.chat
        case .ingest: return L10n.Common.Tab.ingest
        case .synthesis: return L10n.Common.Tab.synthesis
        case .graph: return L10n.Common.Tab.graph
        }
    }

    public var icon: String {
        switch self {
        case .knowledge: return Icon.knowledge
        case .chat: return Icon.chat
        case .ingest: return Icon.ingest
        case .synthesis: return Icon.synthesis
        case .graph: return Icon.graph
        }
    }
}
