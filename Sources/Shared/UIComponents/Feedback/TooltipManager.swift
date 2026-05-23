//
//  TooltipManager.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：属于 Feedback 模块，提供相关的结构体或工具支撑。
//
import SwiftUI

/// 管理引导提示的显示状态，支持首次使用检测。
@MainActor
class TooltipManager: ObservableObject {
    static let shared = TooltipManager()

    @Published var activeTooltip: TooltipType?
    @Published var shownTooltips: Set<String> = []

    private let defaults = UserDefaults.standard
    private let shownKey = "app_shown_tooltips"

    enum TooltipType: String, CaseIterable {
        case createPage = "create_page"
        case appLink = "page_link"
        case graphFilter = "graph_filter"
        case ingest = "ingest"
        case chat = "chat"
        case tag = "tag"

        var titleKey: String {
            switch self {
            case .createPage: return "tooltip.createPage.title"
            case .appLink: return "tooltip.appLink.title"
            case .graphFilter: return "tooltip.graphFilter.title"
            case .ingest: return "tooltip.ingest.title"
            case .chat: return "tooltip.chat.title"
            case .tag: return "tooltip.tag.title"
            }
        }

        var descriptionKey: String {
            switch self {
            case .createPage: return "tooltip.createPage.desc"
            case .appLink: return "tooltip.appLink.desc"
            case .graphFilter: return "tooltip.graphFilter.desc"
            case .ingest: return "tooltip.ingest.desc"
            case .chat: return "tooltip.chat.desc"
            case .tag: return "tooltip.tag.desc"
            }
        }

        var icon: String {
            switch self {
            case .createPage: return "plus.circle.fill"
            case .appLink: return "link"
            case .graphFilter: return "line.3.horizontal.decrease.circle"
            case .ingest: return "tray.and.arrow.down.fill"
            case .chat: return "brain.head.profile"
            case .tag: return "tag.fill"
            }
        }
    }

    private init() {
        shownTooltips = Set(defaults.stringArray(forKey: shownKey) ?? [])
    }

    func markShown(_ tooltip: TooltipType) {
        shownTooltips.insert(tooltip.rawValue)
        defaults.set(Array(shownTooltips), forKey: shownKey)
    }

    func isShown(_ tooltip: TooltipType) -> Bool {
        shownTooltips.contains(tooltip.rawValue)
    }

    func resetAll() {
        shownTooltips.removeAll()
        defaults.removeObject(forKey: shownKey)
    }

    var pendingTooltips: [TooltipType] {
        TooltipType.allCases.filter { !isShown($0) }
    }
}
