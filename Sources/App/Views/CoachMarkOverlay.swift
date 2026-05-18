// CoachMarkOverlay.swift
//
// 作者: Wang Chong
// 功能说明: [L3] 引导层组件：本文件实现了功能引导（Coach Marks）覆盖层，用于在用户首次进入特定功能时提供视觉提示和操作指引。
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 功能引导弹窗 (Coach Marks)
struct CoachMarkOverlay: View {
    let type: AppStore.CoachMarkType
    @Binding var selectedTab: AppTab
    let onDismiss: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(DesignSystem.coachMarkBackgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture { dismissWithAnimation() }
            
            VStack(spacing: DesignSystem.giant) {
                // 图标
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.appAccent, .appSource], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: DesignSystem.Gallery.splashIconSize, height: DesignSystem.Gallery.splashIconSize)
                        .shadow(color: .appAccent.opacity(DesignSystem.disabledOpacity), radius: DesignSystem.medium, y: DesignSystem.small + DesignSystem.atomic)
                    
                    Image(systemName: iconName)
                        .font(.system(size: DesignSystem.Metrics.titleFontSize * DesignSystem.Metrics.coachMarkIconScale, weight: .bold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .opacity(isAnimating ? 1.0 : 0)
                
                VStack(spacing: DesignSystem.medium) {
                    Text(title)
                        .font(.title3.bold())
                        .foregroundStyle(.appText)
                    
                    Text(desc)
                        .font(.subheadline)
                        .foregroundStyle(.appSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .offset(y: isAnimating ? 0 : DesignSystem.loosePadding)
                .opacity(isAnimating ? DesignSystem.fullOpacity : 0)
                
                Button(action: performAction) {
                    Text(actionText)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, DesignSystem.Metrics.coachMarkActionHorizontalPadding)
                        .padding(.vertical, DesignSystem.medium)
                        .background(
                            Capsule()
                                .fill(Color.appAccent)
                        )
                }
                .scaleEffect(isAnimating ? DesignSystem.fullOpacity : DesignSystem.Metrics.coachMarkScaleMultiplier)
                .opacity(isAnimating ? DesignSystem.fullOpacity : 0)
                
                Button(action: dismissWithAnimation) {
                    Text(L10n.Common.skip)
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                }
                .padding(.top, DesignSystem.tiny)
            }
            .padding(DesignSystem.giant + DesignSystem.Metrics.heroValueSize * 0.5)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.largeRadius + DesignSystem.Metrics.coachMarkRadiusOffset)
                    .fill(Color.appCard)
                    .shadow(color: .black.opacity(DesignSystem.glassOpacity * 2), radius: DesignSystem.Metrics.coachMarkShadowRadius, x: 0, y: DesignSystem.Metrics.coachMarkShadowY)
            )
            .padding(DesignSystem.giant)
        }
        .onAppear {
            withAnimation(.spring(response: DesignSystem.Animation.standardDuration, dampingFraction: DesignSystem.Animation.standardDamping * 0.875)) {
                isAnimating = true
            }
        }
    }
    
    private var iconName: String {
        switch type {
        case .graphDiscovery: return "circle.hexagongrid.fill"
        }
    }
    
    private var title: String {
        switch type {
        case .graphDiscovery: return L10n.Coachmark.graphDiscoveryTitle
        }
    }
    
    private var desc: String {
        switch type {
        case .graphDiscovery: return L10n.Coachmark.graphDiscoveryDesc
        }
    }
    
    private var actionText: String {
        switch type {
        case .graphDiscovery: return L10n.Coachmark.graphDiscoveryAction
        }
    }
    
    private func performAction() {
        HapticFeedback.shared.trigger(.success)
        switch type {
        case .graphDiscovery:
            withAnimation {
                selectedTab = .graph
            }
        }
        dismissWithAnimation()
    }
    
    private func dismissWithAnimation() {
        withAnimation(.easeIn(duration: DesignSystem.Animation.fastDuration)) {
            isAnimating = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + DesignSystem.Animation.fastDuration) {
            onDismiss()
        }
    }
}
