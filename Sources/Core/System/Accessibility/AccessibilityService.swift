// AccessibilityService.swift
//
// 作者: Wang Chong
// 功能说明: [L0.5] 系统集成层：Provides accessibility enhancements, VoiceOver support, and dynamic type scaling.
// 版本: 1.1
// 修改记录:
//   - 创建: 2026-05-02
//   - 更新: 2026-05-07: 移除 SwiftUI 依赖，将视图扩展与缩放逻辑移至 AppAccessibilityView.swift
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Combine

#if canImport(UIKit)
import UIKit
#endif

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
    
    static func graphNodeAnnouncement(_ node: GraphNode, linkCount: Int) -> String {
        "\(node.title), \(node.pageType.displayName), \(linkCount) " + L10n.Accessibility.links
    }
    
    // MARK: - Post Announcement
    /// 主动向 VoiceOver 系统发送语音公告，提升视障用户的即时状态感知能力
    /// - Parameter text: 公告文案
    public static func postAnnouncement(_ text: String) {
        #if os(iOS)
        UIAccessibility.post(notification: .announcement, argument: text)
        #elseif targetEnvironment(macCatalyst)
        UIAccessibility.post(notification: .announcement, argument: text)
        #endif
    }
}
