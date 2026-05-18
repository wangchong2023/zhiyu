// AIProcessingStatusBanner.swift
//
// 作者: Wang Chong
// 功能说明: [Shared] 全局 AI 任务处理状态条。
//           当系统正在进行后台 AI 分析、知识合成或治理扫描时，在页面顶部展示动态图标与状态描述。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 全局 AI 任务处理状态条
struct AIProcessingStatusBanner: View {
    @ObservedObject var taskCenter = TaskCenter.shared
    @State private var rotationAngle: Double = 0
    @State private var isAnimating = false
    
    var body: some View {
        if let activeTask = taskCenter.tasks.first(where: { 
            if case .running = $0.status { return true }
            if case .pending = $0.status { return true }
            return false
        }) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // 1. 动态 AI 思考图标
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.appAccent.opacity(0.2), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: DesignSystem.Icons.sparkles)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(LinearGradient(colors: [.appAccent, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .rotationEffect(.degrees(rotationAngle))
                    }
                    
                    // 2. 任务状态文本
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activeTask.name)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.appText)
                        
                        Text(taskCenter.latestStatus.isEmpty ? L10n.AI.Task.tr("processing") : taskCenter.latestStatus)
                            .font(.system(size: 11))
                            .foregroundStyle(.appSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // 3. 进度指示 (如果是执行中)
                    if case .running(let progress, _) = activeTask.status {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.appAccent)
                    }
                }
                .padding(.horizontal, DesignSystem.medium)
                .padding(.vertical, 10)
                .background(Color.appCard.opacity(0.8))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(LinearGradient(colors: [.appAccent.opacity(0.3), .purple.opacity(0.1)], startPoint: .leading, endPoint: .trailing), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                startAnimation()
            }
        } else {
            EmptyView()
        }
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
}
