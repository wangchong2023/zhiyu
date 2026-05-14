// StatCard.swift
//
// 作者: Wang Chong
// 功能说明: 本文件定义了统计指标卡片小组件，用于在仪表盘等页面展示核心业务数据。
// MARK: [PR-03] 统一统计指标卡片规范，优化视觉展示与多端适配
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 统计指标卡片小组件
/// 负责以紧凑网格形式展示关键业务指标（如页面总数、最近新增、同步成功率等）。
public struct StatCard: View {
    // MARK: - Properties
    
    public let title: String
    public let value: String
    public let icon: String
    public let color: Color

    // MARK: - Initialization
    
    public init(title: String, value: String, icon: String, color: Color) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
    }

    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: Spacing.medium - Spacing.atomic) { // 10
            // 带发光效果的图标
            ZStack {
                Circle()
                    .fill(color.opacity(DesignSystem.glassOpacity * 1.2))
                    .frame(width: DesignSystem.Metrics.largeIconBoxSize * 1.2, height: DesignSystem.Metrics.largeIconBoxSize * 1.2)

                Image(systemName: icon)
                    .font(.title2.weight(.medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(DesignSystem.secondaryOpacity)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text(value)
                .font(.system(size: DesignSystem.Metrics.heroValueSize - 2, weight: .bold, design: .rounded)) // 30
                .foregroundStyle(.appText)

            Text(title)
                .font(.caption)
                .foregroundStyle(.appSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.standardPadding)
        .background(Color.appCard.opacity(DesignSystem.surfaceOpacity))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
        .shadow(color: .black.opacity(DesignSystem.shadowOpacity * 1.5), radius: DesignSystem.shadowRadius - 2, x: 0, y: DesignSystem.shadowY)
    }
}
