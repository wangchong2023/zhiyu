// SplashView.swift
//
// 作者: Wang Chong
// 功能说明: 启动画面：名言引导 + 程序化生成的书本 + 神经网络星空背景
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

// MARK: - SplashView
/// 启动画面：名言引导 + 程序化生成的书本 + 神经网络星空背景
struct SplashView: View {
    @State private var quoteOpacity: Double = 0
    @State private var authorOpacity: Double = 0
    @State private var logoOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -300 // 初始位移，用于名言闪光动画
    @State private var starTwinkle = false
    @State private var nodeGlow = false
    
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // MARK: - 程序化背景
            SplashBackgroundView(starTwinkle: starTwinkle, nodeGlow: nodeGlow)
                .ignoresSafeArea()
            
            // 内容
            VStack(spacing: 0) {
                Spacer()
                
                // App Logo / 名称
                VStack(spacing: DesignSystem.medium) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: DesignSystem.Gallery.mainIconSize, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.appAccent, Color.appAccent.opacity(DesignSystem.secondaryOpacity)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(logoOpacity)
                    
                    Text(Localized.tr("splash.appName"))
                        .font(.system(size: DesignSystem.titleFontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .opacity(logoOpacity)
                }
                .padding(.bottom, DesignSystem.Gallery.splashLogoBottomPadding)
                
                // 名言
                VStack(spacing: DesignSystem.standardPadding) {
                    Text(Localized.tr("splash.quote"))
                        .font(.system(size: DesignSystem.bodyFontSize, weight: .medium, design: .serif))
                        .foregroundStyle(.white.opacity(DesignSystem.pressedOpacity))
                        .multilineTextAlignment(.center)
                        .lineSpacing(DesignSystem.small)
                        .padding(.horizontal, DesignSystem.Metrics.largeIconBoxSize)
                        .opacity(quoteOpacity)
                    
                    // 闪光效果
                    Text(Localized.tr("splash.quote"))
                        .font(.system(size: DesignSystem.bodyFontSize, weight: .medium, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.clear, .white.opacity(DesignSystem.secondaryOpacity), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .multilineTextAlignment(.center)
                        .lineSpacing(DesignSystem.small)
                        .padding(.horizontal, DesignSystem.Metrics.largeIconBoxSize)
                        .offset(x: shimmerOffset)
                        .mask(
                            Text(Localized.tr("splash.quote"))
                                .font(.system(size: DesignSystem.bodyFontSize, weight: .medium, design: .serif))
                                .multilineTextAlignment(.center)
                                .lineSpacing(DesignSystem.small)
                                .padding(.horizontal, DesignSystem.Metrics.largeIconBoxSize)
                        )
                        .opacity(quoteOpacity > DesignSystem.pressedOpacity * 0.5 ? DesignSystem.glassOpacity * 4 : 0)
                    
                    // 署名 (仅保留装饰线)
                    HStack(spacing: 0) {
                        Text("— ")
                            .foregroundStyle(.white.opacity(DesignSystem.secondaryOpacity))
                        Text(Localized.tr("splash.author"))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.appAccent.opacity(DesignSystem.secondaryOpacity), Color.appAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .font(.system(size: DesignSystem.captionFontSize, weight: .medium, design: .serif))
                    .opacity(authorOpacity)
                }
                
                Spacer()
                
                // 继续按钮
                Button(action: {
                    withAnimation(.easeInOut(duration: DesignSystem.Animation.standardDuration)) {
                        onDismiss()
                    }
                }) {
                    HStack(spacing: DesignSystem.small) {
                        Text(Localized.tr("splash.enter"))
                            .font(.system(size: DesignSystem.subheadlineFontSize, weight: .semibold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(DesignSystem.caption2Font)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, DesignSystem.huge)
                    .padding(.vertical, DesignSystem.medium)
                    .background(
                        Capsule()
                            .fill(Color.appAccent.opacity(DesignSystem.glassOpacity * 2))
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.appAccent.opacity(DesignSystem.disabledOpacity), lineWidth: DesignSystem.borderWidth)
                            )
                    )
                }
                .opacity(authorOpacity)
                .padding(.bottom, DesignSystem.Gallery.splashButtonBottomPadding)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - 动画序列
    private func startAnimations() {
        // 背景动画启动
        starTwinkle = true
        nodeGlow = true
        
        // Logo 淡入
        withAnimation(.easeOut(duration: DesignSystem.Animation.slowDuration)) {
            logoOpacity = 1
        }

        
        // 名言淡入
        DispatchQueue.main.asyncAfter(deadline: .now() + DesignSystem.Animation.Splash.quoteDelay) {
            withAnimation(.easeOut(duration: DesignSystem.Animation.looseDuration * 0.8)) {
                quoteOpacity = 1
            }
        }
        
        // 署名淡入
        DispatchQueue.main.asyncAfter(deadline: .now() + DesignSystem.Animation.Splash.authorDelay) {
            withAnimation(.easeOut(duration: DesignSystem.Animation.slowDuration)) {
                authorOpacity = 1
            }
        }
        
        // 闪光扫过
        DispatchQueue.main.asyncAfter(deadline: .now() + DesignSystem.Animation.Splash.shimmerDelay) {
            withAnimation(.easeInOut(duration: DesignSystem.Animation.looseDuration)) {
                shimmerOffset = DesignSystem.Decorator.shimmerPhaseShift * 0.5
            }
        }
        
        // 5 秒后自动进入（仅在用户未手动点击时）
        DispatchQueue.main.asyncAfter(deadline: .now() + DesignSystem.Animation.Splash.autoDismissDelay) {
            withAnimation(.easeInOut(duration: DesignSystem.Animation.standardDuration)) {
                onDismiss()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SplashView(onDismiss: {})
}
