// GlassStyle.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了智宇 (ZhiYu) 设计系统中的玻璃拟态 (Glassmorphism) 视觉样式。
// 核心职责：
// 1. 提供通用的玻璃质感背景修饰符。
// 2. 封装卡片 (Card) 和容器 (Container) 的阴影、描边及背景样式。
// 3. 实现仪表盘专用的渐变指标卡片效果。
// MARK: [PR-03] 基于 ultraThinMaterial 的玻璃拟态视觉重构，优化 GPU 渲染表现
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 统一的玻璃卡片视图修饰符
/// 使用系统材质 (Material) 结合自定义不透明度实现通用的玻璃质感背景。
public struct GlassCardModifier: ViewModifier {
    // MARK: - Properties
    
    /// 材质的不透明度
    public let opacity: Double
    /// 圆角半径
    public let cornerRadius: CGFloat
    
    // MARK: - Initialization
    
    /// 初始化玻璃卡片修饰符
    /// - Parameters:
    ///   - opacity: 默认 1.0
    ///   - cornerRadius: 默认使用全局卡片圆角规范
    public init(opacity: Double = 1.0, cornerRadius: CGFloat = Spacing.cardRadius) {
        self.opacity = opacity
        self.cornerRadius = cornerRadius
    }
    
    // MARK: - Body
    
    public func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial.opacity(opacity))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.appBorder.opacity(0.4), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// MARK: - View 扩展

public extension View {
    /// 应用玻璃拟态卡片样式
    /// - Parameters:
    ///   - opacity: 材质不透明度
    ///   - cornerRadius: 圆角半径
    /// - Returns: 装饰后的视图
    func appGlassCardStyle(opacity: Double = 1.0, cornerRadius: CGFloat = Spacing.cardRadius) -> some View {
        self.modifier(GlassCardModifier(opacity: opacity, cornerRadius: cornerRadius))
    }
    
    /// 应用标准卡片容器样式
    /// 提供统一的内边距、背景和阴影效果。
    /// - Parameter cornerRadius: 圆角半径
    /// - Returns: 装饰后的视图
    func appCardStyle(cornerRadius: CGFloat = Spacing.cardRadius) -> some View {
        self.padding(Spacing.large)
            .background(.ultraThinMaterial)
            .background(Color.appCard.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.appBorder.opacity(0.4), lineWidth: Spacing.borderWidth)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    /// 应用通用页面容器样式
    /// - Parameters:
    ///   - background: 背景颜色
    ///   - borderColor: 边框颜色
    ///   - cornerRadius: 圆角半径
    ///   - padding: 是否添加标准内边距
    /// - Returns: 装饰后的视图
    func appContainer(
        background: Color = .appCard,
        borderColor: Color = .appBorder,
        cornerRadius: CGFloat = Spacing.cardRadius,
        padding: Bool = true
    ) -> some View {
        self.padding(padding ? Spacing.standardPadding : 0)
            .background(
                ZStack {
                    Rectangle().fill(.ultraThinMaterial).opacity(0.4) // 降低材质干扰
                    background.opacity(0.9) // 优化通透度
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor.opacity(0.25), lineWidth: 0.5) // 稍微增强边框，匹配任务中心
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }
    
    /// 仪表盘指标卡片风格 (Metric Card Style)
    /// 带有微弱的渐变效果和加大的圆角规范。
    /// - Parameters:
    ///   - color: 强调色背景
    ///   - cornerRadius: 默认使用仪表盘专用圆角
    /// - Returns: 装饰后的视图
    func appMetricCardStyle(color: Color = .appAccent, cornerRadius: CGFloat = Spacing.Metrics.dashboardRadius) -> some View {
        self.background(.ultraThinMaterial)
            .background(
                ZStack {
                    Color.appCard.opacity(0.8) // 提高亮度
                    LinearGradient(
                        colors: [color.opacity(0.15), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color.opacity(0.2), lineWidth: 0.5) // 使用强调色淡边框
            )
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}
