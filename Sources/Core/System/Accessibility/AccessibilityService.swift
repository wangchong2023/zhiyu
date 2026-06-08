//
//  AccessibilityService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0.5] 系统集成层
//  核心职责：实现 Accessibility 模块的核心业务逻辑服务。
//
import Foundation
import Combine

// MARK: - Accessibility Service
/// Provides accessibility enhancements, VoiceOver support, and dynamic type scaling.
@MainActor
final class AccessibilityService: ObservableObject {
    @Published var isVoiceOverRunning: Bool = false
    @Published var isReduceMotionEnabled: Bool = false
    @Published var isHighContrastEnabled: Bool = false
    
    // MARK: - Animation Control
    var shouldAnimate: Bool {
        !isReduceMotionEnabled
    }
    
    // MARK: - VoiceOver Helpers
    /// pageAnnouncement
    /// - Parameter page: page
    /// - Returns: 字符串
    static func pageAnnouncement(_ page: KnowledgePage) -> String {
        var parts: [String] = []
        parts.append(page.title)
        parts.append(page.pageType.displayName)
        parts.append(page.status.displayName)
        if !page.tags.isEmpty {
            parts.append(L10n.Accessibility.tags + ": " + page.tags.joined(separator: ", "))
        }
        let wordStr = "\(page.wordCount) " + L10n.Accessibility.words
        parts.append(wordStr)
        return parts.joined(separator: ", ")
    }
    
    /// graphNodeAnnouncement
    /// - Parameter node: node
    /// - Parameter linkCount: 链接计数
    /// - Returns: 字符串
    static func graphNodeAnnouncement(_ node: GraphNode, linkCount: Int) -> String {
        "\(node.title), \(node.pageType.displayName), \(linkCount) " + L10n.Accessibility.links
    }
    
    // MARK: - Post Announcement
    /// 主动向 VoiceOver 系统发送语音公告，提升视障用户的即时状态感知能力
    /// - Parameter text: 公告文案
    public static func postAnnouncement(_ text: String) {
        @Inject var platformService: any AccessibilityServiceProtocol
        platformService.postAnnouncement(text)
    }
}