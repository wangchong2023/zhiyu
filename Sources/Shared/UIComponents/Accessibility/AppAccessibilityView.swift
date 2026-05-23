//
//  AppAccessibilityView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：构建 AppAccessibility 界面的 UI 视图层组件。
//
import SwiftUI

// MARK: - View Extension for Accessibility
extension View {
    /// 为视图添加标准的无障碍标签、提示和特征
    func appAccessibility(label: String, hint: String? = nil, traits: AccessibilityTraits = .isStaticText) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
    
    /// 为知识库页面列表项配置无障碍元素
    func appPageRow(page: KnowledgePage) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(AccessibilityService.pageAnnouncement(page))
            .accessibilityHint(L10n.Accessibility.tapToOpen)
            .accessibilityAddTraits(.isButton)
    }
    
    /// 为图谱节点配置无障碍元素
    func appGraphNode(title: String, type: PageType, linkCount: Int) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title), \(type.displayName), \(linkCount) " + L10n.Accessibility.links)
            .accessibilityHint(L10n.Accessibility.tapToOpen)
            .accessibilityAddTraits(.isButton)
    }
    
    /// 根据“减弱动态效果”设置应用条件动画
    func appAnimation(_ animation: Animation = .easeInOut(duration: 0.3)) -> some View {
        self.modifier(ConditionalAnimationModifier(animation: animation))
    }
}

// MARK: - Dependency for Reduce Motion
struct AccessibilityReduceMotionKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// 减弱动态效果的环境变量
    var accessibilityReduceMotion: Bool {
        get { self[AccessibilityReduceMotionKey.self] }
        set { self[AccessibilityReduceMotionKey.self] = newValue }
    }
}

// MARK: - Conditional Animation Modifier
/// 条件动画修饰符
/// 负责在“减弱动态效果”开启时禁用动画，否则应用指定的动画效果
struct ConditionalAnimationModifier: ViewModifier {
    let animation: Animation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    func body(content: Content) -> some View {
        // 使用一个始终变化的 value (UUID) 来确保动画能被触发
        content.animation(reduceMotion ? .none : animation, value: UUID())
    }
}

// MARK: - SwiftUI Bridge for Scaling
extension AccessibilityService {
    /// 视图层使用的字体缩放逻辑，桥接到 SwiftUI 的 ContentSizeCategory
    func scaledFont(base: CGFloat, category: ContentSizeCategory) -> CGFloat {
        let multiplier: CGFloat
        switch category {
        case .extraSmall: multiplier = 0.82
        case .small: multiplier = 0.88
        case .medium: multiplier = 0.95
        case .large: multiplier = 1.0
        case .extraLarge: multiplier = 1.12
        case .extraExtraLarge: multiplier = 1.23
        case .extraExtraExtraLarge: multiplier = 1.35
        case .accessibilityMedium: multiplier = 1.5
        case .accessibilityLarge: multiplier = 1.65
        case .accessibilityExtraLarge: multiplier = 1.8
        case .accessibilityExtraExtraLarge: multiplier = 2.0
        case .accessibilityExtraExtraExtraLarge: multiplier = 2.2
        @unknown default: multiplier = 1.0
        }
        return base * multiplier
    }
}
