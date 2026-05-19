// DesignModifiers.swift
//
// 作者: Wang Chong
// 功能说明: [Shared] 共享标准层：本文件定义了系统全局通用的高品质 UI 微交互与视觉美化样式修饰符（DesignModifiers）。
// 核心职责：
// 1. 弹性物理悬停微动效 (ScaleOnHover)：提供高级阻尼感的弹簧物理缩放。
// 2. 高保真弥散软阴影 (PremiumAmbientShadow)：多层极低透明度扩散阴影，模拟高级毛玻璃环境光深度。
// 3. 霓虹呼吸渐变外框 (GlowingNeonBorder)：提供平滑呼吸高亮外边框，用于激活或焦点提示。
// 版本: 1.0
// 日期: 2026-05-19
// 版权: © 2026 Wang Chong。保留所有权利。

import SwiftUI

// MARK: - 1. 弹性物理悬停修饰器

/// 弹性物理悬停微缩放修饰符
struct ScaleOnHoverModifier: ViewModifier {
    /// 悬停动画的目标缩放比例
    let scale: CGFloat
    
    /// 本地悬停激活状态
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        #if os(watchOS)
        content
        #else
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .onHover { hovering in
                withAnimation(.spring(response: 0.25, dampingFraction: 0.65)) {
                    isHovered = hovering
                }
            }
        #endif
    }
}

// MARK: - 2. 高保真弥散软阴影修饰器

/// 高保真弥散环境光晕多重软阴影修饰符
struct PremiumAmbientShadowModifier: ViewModifier {
    /// 阴影的底色
    let color: Color
    
    /// 物理扩散半径
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            // 第一层：大范围微弱漫反射阴影，确立环境光底色
            .shadow(color: color.opacity(0.06), radius: radius, x: 0, y: radius * 0.4)
            // 第二层：小范围紧致遮蔽阴影，确立物理接缝立体感
            .shadow(color: color.opacity(0.04), radius: radius * 0.4, x: 0, y: radius * 0.15)
    }
}

// MARK: - 3. 霓虹渐变呼吸边框修饰器

/// 霓虹渐变高亮呼吸外框修饰符
struct GlowingNeonBorderModifier: ViewModifier {
    /// 是否开启霓虹高光
    let isGlowing: Bool
    
    /// 覆盖圆角弧度
    let cornerRadius: CGFloat
    
    /// 自定义渐变色阵列
    let gradientColors: [Color]
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: isGlowing ? gradientColors : [Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isGlowing ? 1.5 : 0
                    )
                    // 渐变外光圈发光，营造呼吸高亮
                    .shadow(color: isGlowing ? (gradientColors.first ?? .blue).opacity(0.4) : .clear, radius: isGlowing ? 6 : 0)
                    .animation(.easeInOut(duration: 0.35), value: isGlowing)
            )
    }
}

// MARK: - View 语义链式调用扩展

public extension View {
    /// 注入支持高级阻尼弹性悬停物理微动效
    /// - Parameter scale: 悬停时的缩放比例（默认 1.025）
    func scaleOnHover(scale: CGFloat = 1.025) -> some View {
        #if os(watchOS)
        self
        #else
        self.modifier(ScaleOnHoverModifier(scale: scale))
        #endif
    }
    
    /// 注入多层低透明度环境光晕漫反射阴影，营造绝佳的拟物毛玻璃立体悬浮度
    /// - Parameters:
    ///   - color: 阴影颜色（默认黑色）
    ///   - radius: 阴影发散半径（默认 12）
    func premiumAmbientShadow(color: Color = .black, radius: CGFloat = 12) -> some View {
        self.modifier(PremiumAmbientShadowModifier(color: color, radius: radius))
    }
    
    /// 注入霓虹渐变高亮呼吸外框，用作焦点元素和 Aha Card 激活的微动效容器
    /// - Parameters:
    ///   - isGlowing: 是否亮起
    ///   - cornerRadius: 圆角弧度（默认 12）
    ///   - gradientColors: 渐变色组合，默认采用 [蓝色, 紫色, 青色] 现代高阶配色
    func glowingNeonBorder(
        isGlowing: Bool = true,
        cornerRadius: CGFloat = 12,
        gradientColors: [Color] = [.blue, .purple, .init(red: 0.0, green: 0.8, blue: 0.9)]
    ) -> some View {
        self.modifier(GlowingNeonBorderModifier(isGlowing: isGlowing, cornerRadius: cornerRadius, gradientColors: gradientColors))
    }
}
