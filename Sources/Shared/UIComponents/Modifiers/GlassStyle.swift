import SwiftUI

// MARK: @PR-03: 玻璃拟态视觉效果重构，使用了 ultraThinMaterial 材质

/// 统一的玻璃卡片修饰符
public struct GlassCardModifier: ViewModifier {
    public let opacity: Double
    public let cornerRadius: CGFloat
    
    public init(opacity: Double = 1.0, cornerRadius: CGFloat = Spacing.cardRadius) {
        self.opacity = opacity
        self.cornerRadius = cornerRadius
    }
    
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
    func appGlassCardStyle(opacity: Double = 1.0, cornerRadius: CGFloat = Spacing.cardRadius) -> some View {
        self.modifier(GlassCardModifier(opacity: opacity, cornerRadius: cornerRadius))
    }
    
    /// 标准卡片容器样式
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
    
    /// 通用容器样式
    func appContainer(
        background: Color = .appCard.opacity(0.7),
        borderColor: Color = .appBorder,
        cornerRadius: CGFloat = Spacing.cardRadius,
        padding: Bool = true
    ) -> some View {
        self.padding(padding ? Spacing.standardPadding : 0)
            .background(.ultraThinMaterial)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor.opacity(0.4), lineWidth: Spacing.borderWidth)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
    
    /// 仪表盘指标卡片风格 (Metric Card Style)
    func appMetricCardStyle(color: Color = .appAccent, cornerRadius: CGFloat = Spacing.Metrics.dashboardRadius) -> some View {
        self.background(.ultraThinMaterial)
            .background(
                ZStack {
                    Color.appCard.opacity(0.7)
                    LinearGradient(
                        colors: [color.opacity(0.12), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [.appBorder.opacity(0.5), .appBorder.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}
