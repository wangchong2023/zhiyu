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
    @State private var shimmerOffset: CGFloat = -200
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
                VStack(spacing: AppUI.medium) { // 12
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: AppUI.Metrics.heroValueSize * 1.69, weight: .light)) // 44
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.appAccent, Color.appAccent.opacity(AppUI.fullOpacity * 0.7)], // 0.7
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(logoOpacity)
                    
                    Text(Localized.tr("splash.appName"))
                        .font(.system(size: AppUI.Metrics.titleFontSize, weight: .bold, design: .rounded)) // 28
                        .foregroundStyle(.white)
                        .opacity(logoOpacity)
                }
                .padding(.bottom, AppUI.Metrics.heroValueSize * 2.3) // 60
                
                // 名言
                VStack(spacing: AppUI.standardPadding) { // 16
                    Text(Localized.tr("splash.quote"))
                        .font(.system(size: AppUI.Metrics.bodyFontSize, weight: .medium, design: .serif)) // 17
                        .foregroundStyle(.white.opacity(AppUI.fullOpacity * 0.9)) // 0.9
                        .multilineTextAlignment(.center)
                        .lineSpacing(AppUI.tiny + AppUI.atomic) // 6
                        .padding(.horizontal, AppUI.Metrics.largeIconSize) // 40
                        .opacity(quoteOpacity)
                    
                    // 闪光效果
                    Text(Localized.tr("splash.quote"))
                        .font(.system(size: AppUI.Metrics.bodyFontSize, weight: .medium, design: .serif)) // 17
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.clear, .white.opacity(AppUI.fullOpacity * 0.6), .clear], // 0.6
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .multilineTextAlignment(.center)
                        .lineSpacing(AppUI.tiny + AppUI.atomic) // 6
                        .padding(.horizontal, AppUI.Metrics.largeIconSize) // 40
                        .offset(x: shimmerOffset)
                        .mask(
                            Text(Localized.tr("splash.quote"))
                                .font(.system(size: AppUI.Metrics.bodyFontSize, weight: .medium, design: .serif)) // 17
                                .multilineTextAlignment(.center)
                                .lineSpacing(AppUI.tiny + AppUI.atomic) // 6
                                .padding(.horizontal, AppUI.Metrics.largeIconSize) // 40
                        )
                        .opacity(quoteOpacity > AppUI.fullOpacity * 0.5 ? AppUI.glassOpacity * 4 : 0) // 0.5, 0.4
                    
                    // 署名 (仅保留装饰线)
                    HStack(spacing: 0) {
                        Text("— ")
                            .foregroundStyle(.white.opacity(AppUI.fullOpacity * 0.5)) // 0.5
                        Text(Localized.tr("splash.author"))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.appAccent.opacity(AppUI.fullOpacity * 0.8), Color.appAccent], // 0.8
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .font(.system(size: AppUI.Metrics.captionFontSize, weight: .medium, design: .serif)) // 14
                    .opacity(authorOpacity)
                }
                
                Spacer()
                
                // 继续按钮
                Button(action: {
                    withAnimation(.easeInOut(duration: AppUI.Animation.standardDuration)) { // 0.5
                        onDismiss()
                    }
                }) {
                    HStack(spacing: AppUI.small) { // 8
                        Text(Localized.tr("splash.enter"))
                            .font(.system(size: AppUI.Metrics.subHeadlineFontSize, weight: .semibold, design: .rounded)) // 15
                        Image(systemName: "arrow.right")
                            .font(.system(size: AppUI.Metrics.caption2FontSize, weight: .semibold)) // 13
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppUI.Metrics.heroValueSize * 1.23) // 32
                    .padding(.vertical, AppUI.small + AppUI.tiny) // 14
                    .background(
                        Capsule()
                            .fill(Color.appAccent.opacity(AppUI.glassOpacity * 2.5)) // 0.25
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.appAccent.opacity(AppUI.fullOpacity * 0.5), lineWidth: AppUI.borderWidth) // 0.5, 1
                            )
                    )
                }
                .opacity(authorOpacity)
                .padding(.bottom, AppUI.Metrics.heroValueSize * 1.9) // 50
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
        withAnimation(.easeOut(duration: AppUI.Animation.slowDuration)) { // 0.8
            logoOpacity = 1
        }
        
        // 名言淡入
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: AppUI.Animation.looseDuration * 0.8)) { // 1.2
                quoteOpacity = 1
            }
        }
        
        // 署名淡入
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeOut(duration: AppUI.Animation.slowDuration)) { // 0.8
                authorOpacity = 1
            }
        }
        
        // 闪光扫过
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeInOut(duration: AppUI.Animation.looseDuration)) { // 1.5
                shimmerOffset = 200
            }
        }
        
        // 5 秒后自动进入（仅在用户未手动点击时）
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            withAnimation(.easeInOut(duration: AppUI.Animation.standardDuration)) { // 0.5
                onDismiss()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SplashView(onDismiss: {})
}
