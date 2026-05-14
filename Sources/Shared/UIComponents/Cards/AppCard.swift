// AppCard.swift
//
// 作者: Wang Chong
// 功能说明: 本文件定义了智宇 (ZhiYu) 的卡片组件体系，包括标准卡片、带边框卡片及玻璃拟态卡片。
// 核心职责：
// 1. 提供统一样式的容器，封装圆角、内边距和背景。
// 2. 支持普通色块背景、玻璃拟态背景及强调色边框。
// MARK: [PR-03] 统一卡片容器规范，优化视觉层级与渲染效率
// 版本: 1.2
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

// MARK: - App Card Modifier

/// 应用卡片背景的视图修饰符
/// 负责注入一致的内边距、背景色及圆角样式。
public struct AppCardModifier: ViewModifier {
    public var cornerRadius: CGFloat = Spacing.cardRadius
    public var padding: CGFloat = Spacing.Layout.cardContentPadding
    public var backgroundColor: Color = .appCard

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - App Card (Container)

/// 标准卡片容器组件
/// 提供符合设计系统的阴影、圆角及背景封装。
public struct AppCard<Content: View>: View {
    public let content: Content
    public var cornerRadius: CGFloat = Spacing.cardRadius
    public var padding: CGFloat = Spacing.Layout.cardContentPadding

    public init(
        cornerRadius: CGFloat = Spacing.cardRadius,
        padding: CGFloat = Spacing.Layout.cardContentPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - App Bordered Card

/// 带描边效果的卡片
/// 适用于需要视觉分割或引导点击的入口区域。
public struct AppBorderedCard<Content: View>: View {
    public let content: Content
    public var cornerRadius: CGFloat = Spacing.cardRadius
    public var borderColor: Color = .appBorder

    public init(
        cornerRadius: CGFloat = Spacing.cardRadius,
        borderColor: Color = .appBorder,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.content = content()
    }

    public var body: some View {
        content
            .padding(.vertical, Spacing.standardPadding)
            .padding(.horizontal, Spacing.medium)
            .frame(maxWidth: .infinity)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: Spacing.borderWidth)
            )
    }
}

// MARK: - App Glass Card

/// 玻璃拟态风格卡片
/// 使用系统材质 (Material) 结合阴影实现高阶视觉层次感。
public struct AppGlassCard<Content: View>: View {
    public let content: Content
    public var cornerRadius: CGFloat = Spacing.cardRadius
    public var isHighlighted: Bool = false

    public init(
        cornerRadius: CGFloat = Spacing.cardRadius,
        isHighlighted: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.isHighlighted = isHighlighted
        self.content = content()
    }

    public var body: some View {
        content
            .padding(Spacing.Layout.cardContentPadding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.appCard.opacity(DesignSystem.translucentOpacity))
                    if isHighlighted {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.appAccent.opacity(DesignSystem.accentStrokeOpacity), lineWidth: DesignSystem.borderWidth)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: .black.opacity(isHighlighted ? DesignSystem.glassOpacity : DesignSystem.shadowOpacity * 0.75), 
                radius: isHighlighted ? Spacing.Decorator.shadowRadiusLarge : Spacing.Decorator.shadowRadiusSmall, 
                x: 0, 
                y: isHighlighted ? Spacing.Decorator.shadowOffsetYLarge : Spacing.Decorator.shadowOffsetYSmall
            )
    }
}

// MARK: - App Card Accent

/// 卡片顶部的装饰性条纹
/// 用于通过颜色标识卡片类别或状态。
public struct AppCardAccent: View {
    public var color: Color = .appAccent
    public var height: CGFloat = Spacing.Decorator.accentLineWidth

    public init(color: Color = .appAccent, height: CGFloat = Spacing.Decorator.accentLineWidth) {
        self.color = color
        self.height = height
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: Spacing.tiny)
            .fill(color)
            .frame(height: height)
    }
}

// MARK: - View Extension

public extension View {
    /// 应用标准卡片背景
    func appCard(
        cornerRadius: CGFloat = Spacing.cardRadius, 
        padding: CGFloat = Spacing.Layout.cardContentPadding
    ) -> some View {
        modifier(AppCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}
