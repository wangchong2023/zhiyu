// AppDecorators.swift
//
// 作者: Wang Chong
// 功能说明: 智宇 (ZhiYu) 全局 UI 装饰器与跨层级导航动作封装。
// 核心原则：
// 1. 去硬编码：所有布局数值必须引用 AppUI 模式。
// 2. 视觉一致性：通过 Decorator Pattern 确保全工程光影、动画、反馈感官统一。
// 版本: 1.11 (补全缺失组件并优化工业级规范)
// 修改记录:
//   - 2026-05-07: 系统性重构，从 Wiki 术语重构为 App/Page 术语，术语统一为“应用 UI 装饰器”
// 日期: 2026-05-07
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

// MARK: - Navigation Action
/// 提供一种跨视图层级触发导航的方式，绕过对单一全局 Path 的硬编码依赖。
struct NavigateAction: Sendable {
    private let action: @Sendable (KnowledgePage) -> Void
    
    init(action: @escaping @Sendable (KnowledgePage) -> Void) {
        self.action = action
    }
    
    func callAsFunction(_ page: KnowledgePage) {
        action(page)
    }
}

struct NavigateActionKey: EnvironmentKey {
    static let defaultValue = NavigateAction(action: { _ in })
}

extension EnvironmentValues {
    var navigate: NavigateAction {
        get { self[NavigateActionKey.self] }
        set { self[NavigateActionKey.self] = newValue }
    }
}

// MARK: - App Decorators

// MARK: - Glass Card
struct AppGlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = AppUI.cardRadius
    var isHighlighted: Bool = false

    init(
        cornerRadius: CGFloat = AppUI.cardRadius,
        isHighlighted: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.isHighlighted = isHighlighted
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppUI.Layout.cardContentPadding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.appCard.opacity(0.6))
                    if isHighlighted {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.appAccent.opacity(0.3), lineWidth: AppUI.borderWidth)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: .black.opacity(isHighlighted ? 0.15 : 0.08), 
                radius: isHighlighted ? AppUI.Decorator.shadowRadiusLarge : AppUI.Decorator.shadowRadiusSmall, 
                x: 0, 
                y: isHighlighted ? AppUI.Decorator.shadowOffsetYLarge : AppUI.Decorator.shadowOffsetYSmall
            )
    }
}

// MARK: - Shimmer Loading
struct AppShimmer: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        LinearGradient(
            colors: [
                .clear,
                Color.appAccent.opacity(0.15),
                .clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .offset(x: phase)
        .onAppear {
            withAnimation(.linear(duration: AppUI.Decorator.shimmerDuration).repeatForever(autoreverses: false)) {
                phase = AppUI.Decorator.shimmerPhaseShift
            }
        }
    }
}

// MARK: - Shimmer Modifier
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -AppUI.Decorator.shimmerPhaseShift / 2

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.2),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * AppUI.Decorator.shimmerWidthRatio)
                    .offset(x: phase)
                    .onAppear {
                        withAnimation(.linear(duration: AppUI.Decorator.shimmerDuration).repeatForever(autoreverses: false)) {
                            phase = geometry.size.width * AppUI.Decorator.shimmerEndRatio
                        }
                    }
                }
            )
            .clipped()
    }
}

extension View {
    func shimmerApp() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Glow Effect
struct AppGlow: View {
    let icon: String
    var color: Color = .appAccent
    var size: CGFloat = AppUI.huge

    var body: some View {
        ZStack {
            // 外层光晕
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size * AppUI.Decorator.glowScaleLarge, height: size * AppUI.Decorator.glowScaleLarge)
                .blur(radius: AppUI.Decorator.glowBlurMedium)

            // 内层光晕
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: size * AppUI.Decorator.glowScaleMedium, height: size * AppUI.Decorator.glowScaleMedium)
                .blur(radius: AppUI.Decorator.glowBlurSmall)

            // 中心图标
            Image(systemName: icon)
                .font(.system(size: size * 0.5, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Section Divider
struct AppDivider: View {
    var icon: String? = nil
    var title: String? = nil
    var color: Color = .appBorder

    var body: some View {
        HStack(spacing: AppUI.medium) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
            }
            if let title = title {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.appSecondary)
            }
            Rectangle()
                .fill(color)
                .frame(height: 1)
        }
    }
}

// MARK: - Accent Line
struct AppAccentLine: View {
    var color: Color = .appAccent
    var width: CGFloat = AppUI.Decorator.accentLineWidth

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: width)
            .clipShape(RoundedRectangle(cornerRadius: AppUI.tiny))
    }
}

// MARK: - Badge
struct AppBadge: View {
    let text: String
    var color: Color = .appAccent
    var isPill: Bool = true

    var body: some View {
        Group {
            if isPill {
                Text(text)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppUI.small)
                    .padding(.vertical, AppUI.atomic + 1)
                    .background(color)
                    .clipShape(Capsule())
            } else {
                Text(text)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: AppUI.Decorator.badgeMinSize, height: AppUI.Decorator.badgeMinSize)
                    .background(color)
                    .clipShape(Circle())
            }
        }
    }
}

// MARK: - Pulse Indicator
struct AppPulseDot: View {
    var color: Color = .appAccent
    var size: CGFloat = AppUI.small

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: size * 2, height: size * 2)
                .scaleEffect(isPulsing ? AppUI.Decorator.pulseScale : 1.0)
                .opacity(isPulsing ? 0 : 1)

            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(.easeOut(duration: AppUI.Decorator.pulseDuration).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Dot Pattern
struct AppDotPattern: View {
    var dotColor: Color = .appBorder
    var spacing: CGFloat = AppUI.wide
    var dotSize: CGFloat = AppUI.atomic

    var body: some View {
        Canvas { context, size in
            let cols = Int(size.width / spacing) + 1
            let rows = Int(size.height / spacing) + 1
            for row in 0..<rows {
                for col in 0..<cols {
                    let x = CGFloat(col) * spacing
                    let y = CGFloat(row) * spacing
                    let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(dotColor.opacity(0.4))
                    )
                }
            }
        }
    }
}

// MARK: - Card Accent
struct AppCardAccent: View {
    var color: Color = .appAccent
    var height: CGFloat = AppUI.Decorator.accentLineWidth

    var body: some View {
        RoundedRectangle(cornerRadius: AppUI.tiny)
            .fill(color)
            .frame(height: height)
    }
}

// MARK: - Icon Box
struct AppIconBox: View {
    let icon: String
    var color: Color = .appAccent
    var size: CGFloat = AppUI.Gallery.iconSize

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppUI.small)
                .fill(color.opacity(0.12))

            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: .medium))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Skeleton Loader
struct AppSkeleton: View {
    var height: CGFloat = AppUI.large
    var cornerRadius: CGFloat = AppUI.tiny

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.appSecondary.opacity(0.15))
            .frame(height: height)
            .shimmerApp()
    }
}

// MARK: - Quiz Presentation
struct QuizPresentationModifier: ViewModifier {
    @Binding var activeQuiz: QuizModel?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            content
                .sheet(item: $activeQuiz) { quiz in
                    QuizView(quiz: quiz)
                        .frame(minWidth: AppUI.Decorator.desktopSheetMinWidth, minHeight: AppUI.Decorator.desktopSheetMinHeight)
                }
        } else {
            #if os(iOS) && !targetEnvironment(macCatalyst)
            content
                .fullScreenCover(item: $activeQuiz) { quiz in
                    QuizView(quiz: quiz)
                }
            #else
            content
                .sheet(item: $activeQuiz) { quiz in
                    QuizView(quiz: quiz)
                }
            #endif
        }
    }
}

extension View {
    func quizPresentation(activeQuiz: Binding<QuizModel?>) -> some View {
        modifier(QuizPresentationModifier(activeQuiz: activeQuiz))
    }
}

// MARK: - Button Styles
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? AppUI.Action.pressScale : 1.0)
            .animation(.easeOut(duration: AppUI.Action.animationDuration), value: configuration.isPressed)
    }
}
