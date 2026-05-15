// AIPulseIndicator.swift
//
// 作者: Wang Chong
// 功能说明: AI 脉搏指示器，提供 AI 处理状态的实时视觉反馈与触感反馈。
// MARK: [PR-04] AI 思考指示器 (Pulse) 启动延迟 < 200ms
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI
import Observation

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
        return .appSecondary.opacity(DesignSystem.disabledOpacity) // 0.3
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.small) { // 8
            ZStack {
                Circle()
                    .fill(pulseColor)
                    .frame(width: DesignSystem.smallIconSize / 2, height: DesignSystem.smallIconSize / 2) // 8
                
                if isActive {
                    Circle()
                        .stroke(pulseColor, lineWidth: DesignSystem.borderWidth * 2) // 2
                        .frame(width: DesignSystem.smallIconSize, height: DesignSystem.smallIconSize) // 16
                        .scaleEffect(isAnimating ? 1.5 : 1.0)
                        .opacity(isAnimating ? 0 : DesignSystem.fullOpacity * 0.8) // 0.8
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: DesignSystem.Animation.looseDuration).repeatForever(autoreverses: false)) { // 1.5
                    isAnimating = true
                }
            }
            
            if isActive {
                VStack(alignment: .leading, spacing: DesignSystem.atomic) { // 2
                    Text(store.llmService.isProcessing ? Localized.tr("ai.status.thinking") : Localized.tr("ai.status.scanning"))
                        .font(.system(size: DesignSystem.microFontSize, weight: .bold, design: .rounded)) // 10
                        .foregroundStyle(pulseColor)
                    
                    if !TaskCenter.shared.latestStatus.isEmpty {
                        Text(TaskCenter.shared.latestStatus)
                            .font(.system(size: DesignSystem.microFontSize - 2, design: .monospaced)) // 8
                            .foregroundStyle(.appSecondary.opacity(DesignSystem.fullOpacity * 0.8)) // 0.8
                            .lineLimit(1)
                            .transition(.asymmetric(insertion: .push(from: .bottom), removal: .opacity))
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
        .padding(.horizontal, DesignSystem.small + DesignSystem.atomic) // 10
        .padding(.vertical, DesignSystem.tiny + DesignSystem.atomic) // 6
        .background(
            Capsule()
                .fill(Color.appCard.opacity(DesignSystem.fullOpacity * 0.8)) // 0.8
                .shadow(color: .black.opacity(DesignSystem.shadowOpacity / 2), radius: DesignSystem.borderWidth * 2) // 0.05, 2
        )
        .animation(.spring(response: DesignSystem.Animation.standardDuration * 1.2), value: TaskCenter.shared.latestStatus) // 0.3
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
