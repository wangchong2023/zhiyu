// AccessibilityService.swift
//
// 作者: Wang Chong
// 功能说明: Provides accessibility enhancements, VoiceOver support, and dynamic type scaling.
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
        parts.append(page.type.displayName)
        parts.append(page.status.displayName)
        if !page.tags.isEmpty {
            parts.append(L10n.Accessibility.tr("tags") + ": " + page.tags.joined(separator: ", "))
        }
        let wordStr = "\(page.wordCount) " + L10n.Accessibility.tr("words")
        parts.append(wordStr)
        return parts.joined(separator: ", ")
    }
    
    static func graphNodeAnnouncement(_ node: GraphNode, linkCount: Int) -> String {
        "\(node.title), \(node.type.displayName), \(linkCount) " + L10n.Accessibility.tr("links")
    }
    
    // MARK: - Haptic Feedback
#if os(iOS)
    static func playHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func playNotificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType = .success) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
#else
    static func playHaptic() {
        // macOS/watchOS implementation or placeholder
    }
    static func playNotificationHaptic() {
        // macOS/watchOS implementation or placeholder
    }
#endif
}
