// AIPulseIndicator.swift
//
// 作者: Wang Chong
// 功能说明: AI 脉搏指示器 (PM 视角：增强用户对 AI 处理状态的感知)
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// AI 脉搏指示器
/// 负责增强用户对 AI 处理状态（如思考、全库扫描）的感知，提供动态波纹动画及实时状态文本展示
struct AIPulseIndicator: View {
    @Environment(AppStore.self) var store
    @State private var isAnimating = false
    
    private var isActive: Bool {
        store.llmService.isProcessing || store.isScanningAI
    }
    
    private var pulseColor: Color {
        if store.llmService.isProcessing {
            return .purple // AI 正在思考
        } else if store.isScanningAI {
            return .appAccent // 正在全库扫描
        }
        return .appSecondary.opacity(AppUI.disabledOpacity) // 0.3
    }
    
    var body: some View {
        HStack(spacing: AppUI.small) { // 8
            ZStack {
                Circle()
                    .fill(pulseColor)
                    .frame(width: AppUI.smallIconSize / 2, height: AppUI.smallIconSize / 2) // 8
                
                if isActive {
                    Circle()
                        .stroke(pulseColor, lineWidth: AppUI.borderWidth * 2) // 2
                        .frame(width: AppUI.smallIconSize, height: AppUI.smallIconSize) // 16
                        .scaleEffect(isAnimating ? 1.5 : 1.0)
                        .opacity(isAnimating ? 0 : AppUI.fullOpacity * 0.8) // 0.8
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: AppUI.Animation.looseDuration).repeatForever(autoreverses: false)) { // 1.5
                    isAnimating = true
                }
            }
            
            if isActive {
                VStack(alignment: .leading, spacing: AppUI.atomic) { // 2
                    Text(store.llmService.isProcessing ? Localized.tr("ai.status.thinking") : Localized.tr("ai.status.scanning"))
                        .font(.system(size: AppUI.microFontSize, weight: .bold, design: .rounded)) // 10
                        .foregroundStyle(pulseColor)
                    
                    if !TaskCenter.shared.latestStatus.isEmpty {
                        Text(TaskCenter.shared.latestStatus)
                            .font(.system(size: AppUI.microFontSize - 2, design: .monospaced)) // 8
                            .foregroundStyle(.appSecondary.opacity(AppUI.fullOpacity * 0.8)) // 0.8
                            .lineLimit(1)
                            .transition(.asymmetric(insertion: .push(from: .bottom), removal: .opacity))
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
        .padding(.horizontal, AppUI.small + AppUI.atomic) // 10
        .padding(.vertical, AppUI.tiny + AppUI.atomic) // 6
        .background(
            Capsule()
                .fill(Color.appCard.opacity(AppUI.fullOpacity * 0.8)) // 0.8
                .shadow(color: .black.opacity(AppUI.shadowOpacity / 2), radius: AppUI.borderWidth * 2) // 0.05, 2
        )
        .animation(.spring(response: AppUI.Animation.standardDuration * 1.2), value: TaskCenter.shared.latestStatus) // 0.3
        .animation(.spring(), value: isActive)
        .onChange(of: isActive) { oldValue, newValue in
            if newValue {
                startHapticPulse()
            }
        }
    }
    
    private func startHapticPulse() {
        Task {
            while isActive {
                HapticFeedback.shared.trigger(.pulse)
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s 脉搏周期
            }
        }
    }
}
