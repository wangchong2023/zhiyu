// MedalComponents.swift
//
// 作者: Wang Chong
// 功能说明: 奖章卡片视图
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-03
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 奖章卡片视图
struct MedalCard: View {
    let medal: MedalService.Medal
    let isEarned: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                let baseColor = Color(hex: medal.colorHex)
                let fillColor = isEarned ? baseColor.opacity(AppUI.glassOpacity) : Color.appBorder.opacity(0.1)
                
                Circle()
                    .fill(fillColor)
                    .frame(width: AppUI.Gallery.itemSize, height: AppUI.Gallery.itemSize)
                
                Image(systemName: medal.icon)
                    .font(.system(size: AppUI.Gallery.iconSize, weight: .bold))
                    .foregroundStyle(isEarned ? baseColor : .appSecondary.opacity(0.5))
                
                if !isEarned {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .padding(AppUI.tiny)
                        .background(Circle().fill(.ultraThinMaterial))
                        .offset(x: AppUI.Gallery.badgeOffset, y: AppUI.Gallery.badgeOffset)
                }
            }
            
            VStack(spacing: AppUI.tiny) {
                Text(Localized.tr(medal.titleKey))
                    .font(.system(size: AppUI.subheadlineFontSize, weight: .bold))
                    .foregroundStyle(isEarned ? .appText : .appSecondary)
                
                Text(Localized.tr(medal.descKey))
                    .font(.system(size: AppUI.microFontSize))
                    .foregroundStyle(.appSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(AppUI.standardPadding)
        .frame(maxWidth: .infinity)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: AppUI.Gallery.itemRadius))
        .overlay {
            let overlayColor = isEarned ? Color(hex: medal.colorHex).opacity(0.3) : Color.appBorder.opacity(0.1)
            RoundedRectangle(cornerRadius: AppUI.Gallery.itemRadius)
                .stroke(overlayColor, lineWidth: 1)
        }
        .shadow(color: isEarned ? Color(hex: medal.colorHex).opacity(0.1) : .clear, radius: 10, y: 4)
        .grayscale(isEarned ? 0 : 1)
        .opacity(isEarned ? 1 : 0.7)
    }
}

/// 奖章奖励弹窗
struct MedalRewardPopup: View {
    let medal: MedalService.Medal
    let onDismiss: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)
            
            VStack(spacing: 24) {
                // 顶部闪烁装饰
                ZStack {
                    let baseColor = Color(hex: medal.colorHex)
                    Circle()
                        .fill(baseColor.opacity(0.2))
                        .frame(width: AppUI.Gallery.displayIconSize, height: AppUI.Gallery.displayIconSize)
                        .blur(radius: AppUI.Gallery.blurRadius)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                    
                    Image(systemName: medal.icon)
                        .font(.system(size: AppUI.Gallery.mainIconSize, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [baseColor, baseColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: baseColor.opacity(0.5), radius: 20, y: 10)
                        .scaleEffect(isAnimating ? 1.1 : 0.9)
                }
                .padding(.top, AppUI.Gallery.blurRadius)
                
                VStack(spacing: 12) {
                    Text(Localized.tr("medal.congrats"))
                        .font(.subheadline.bold())
                        .foregroundStyle(.appAccent)
                        .kerning(2)
                    
                    Text(Localized.tr(medal.titleKey))
                        .font(.title.bold())
                        .foregroundStyle(.appText)
                    
                    Text(Localized.tr(medal.descKey))
                        .font(.body)
                        .foregroundStyle(.appSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Button(action: onDismiss) {
                    let baseColor = Color(hex: medal.colorHex)
                    Text(L10n.Common.tr("awesome"))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: AppUI.Gallery.callToActionWidth, height: AppUI.Gallery.callToActionHeight)
                        .background {
                            Capsule()
                                .fill(LinearGradient(colors: [baseColor, baseColor.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                        }
                        .shadow(color: baseColor.opacity(0.3), radius: 10, y: 5)
                }
                .padding(.bottom, AppUI.Gallery.blurRadius)
                .scaleEffect(isAnimating ? 1 : 0.9)
            }
            .background(
                RoundedRectangle(cornerRadius: AppUI.Gallery.containerRadius)
                    .fill(Color.appCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppUI.Gallery.containerRadius)
                            .stroke(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                    )
            )
            .padding(AppUI.Gallery.containerPadding)
            .scaleEffect(isAnimating ? 1 : 0.5)
            .opacity(isAnimating ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
                isAnimating = true
            }
        }
    }
}
