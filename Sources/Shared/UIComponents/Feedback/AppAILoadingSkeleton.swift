// AppAILoadingSkeleton.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 增强型 AI 骨架屏，针对本地大模型慢加载场景提供丰富的视觉与信息反馈
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 增强型 AI 骨架屏
/// 支持展示当前的 RAG 阶段，并提供类似神经元跳动的动画效果
public struct AppAILoadingSkeleton: View {
    let stage: TaskStage
    
    public init(stage: TaskStage = .general) {
        self.stage = stage
    }
    
    private var stageColor: Color {
        switch stage {
        case .embedding: return .cyan
        case .retrieval: return .blue
        case .synthesis: return .purple
        default: return .appAccent
        }
    }
    
    private var stageText: String {
        switch stage {
        case .embedding: return "INITIALIZING NEURAL WEIGHTS..."
        case .retrieval: return "SCANNING LOCAL KNOWLEDGE..."
        case .synthesis: return "SYNTHESIZING CONCEPTS..."
        default: return "AI IS THINKING..."
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            // 1. 顶部状态标签
            HStack(spacing: DesignSystem.small) {
                Circle()
                    .fill(stageColor)
                    .frame(width: 6, height: 6)
                    .modifier(PulsingDot(delay: 0))
                
                Text(stageText)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(stageColor)
            }
            .padding(.horizontal, DesignSystem.small)
            .padding(.vertical, 4)
            .background(stageColor.opacity(0.1))
            .clipShape(Capsule())
            
            // 2. 多行模拟文本骨架
            VStack(alignment: .leading, spacing: DesignSystem.small) {
                skeletonRow(widthRatio: 0.9)
                skeletonRow(widthRatio: 0.85)
                skeletonRow(widthRatio: 0.6)
            }
        }
        .padding(DesignSystem.medium)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.mediumRadius)
                .stroke(stageColor.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func skeletonRow(widthRatio: CGFloat) -> some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            stageColor.opacity(0.05),
                            stageColor.opacity(0.15),
                            stageColor.opacity(0.05)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: geo.size.width * widthRatio, height: 12)
                .shimmerApp()
        }
        .frame(height: 12)
    }
}
