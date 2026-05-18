// OnboardingOverlay.swift
//
// 作者: Wang Chong
// 功能说明: [Shared] 本文件定义了新手引导蒙层视图，用于向新用户展示系统的核心能力与操作指引。
// 日期: 2026-05-07
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

// MARK: - Onboarding Overlay
/// 引导蒙层组件
/// 负责在引导流程中展示各步骤的视觉元素、描述信息及操作按钮，采用沉浸式背景与弹性动画。
struct OnboardingOverlay: View {
    @ObservedObject var service: OnboardingService
    
    var body: some View {
        if let step = service.currentStep {
            ZStack {
                Color.black.opacity(Colors.Opacity.secondaryOpacity * 0.875) // 0.7
                    .ignoresSafeArea()
                    .onTapGesture { 
                        withAnimation {
                            service.nextStep()
                        }
                    }
                
                VStack(spacing: Spacing.loosePadding) { // 24
                    Image(systemName: step.icon)
                        .font(.system(size: Spacing.iconHuge * 1.25))
                        .foregroundStyle(.appAccent)
                    
                    VStack(spacing: Spacing.tightPadding) { // 8
                        Text(step.title)
                            .font(.title2.bold())
                        Text(step.description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.huge) // 32
                    }
                    
                    Button(action: { 
                        withAnimation {
                            service.nextStep()
                        }
                    }) {
                        Text(step == .vault ? L10n.Onboarding.Action.start : L10n.Onboarding.Action.next)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.huge * 1.25) // 40
                            .padding(.vertical, Spacing.medium) // 12
                            .background(Color.appAccent)
                            .clipShape(Capsule())
                    }
                    
                    Button(L10n.Onboarding.Action.skip) {
                        withAnimation {
                            service.completeOnboarding()
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.appSecondary)
                }
                .padding(Spacing.giant * 1.5)
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.largeRadius * 1.5))
                .shadow(radius: Spacing.giant)
                .padding(Spacing.giant)
                .transition(.scale.combined(with: .opacity))
            }
            .zIndex(999)
        }
    }
}
