// AppCardComponents.swift
//
// 作者: Wang Chong
// 功能说明: struct StatCard
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
//   - 2026-05-07: 系统性重构，从 WikiCardComponents 重命名为 AppCardComponents，术语统一为“应用卡片子组件”
// 日期: 2026-05-07
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

// MARK: - Stat Card
/// 统计指标卡片小组件
/// 负责以紧凑网格形式展示关键业务指标（如页面总数、最近新增、同步成功率等）
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: AppUI.medium - AppUI.atomic) { // 10
            // 带发光效果的图标
            ZStack {
                Circle()
                    .fill(color.opacity(AppUI.glassOpacity * 1.2))
                    .frame(width: AppUI.largeIconSize * 1.6, height: AppUI.largeIconSize * 1.6) // 52

                Image(systemName: icon)
                    .font(.title2.weight(.medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(AppUI.secondaryOpacity)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text(value)
                .font(.system(size: AppUI.Metrics.heroValueSize - 2, weight: .bold, design: .rounded)) // 26
                .foregroundStyle(.appText)

            Text(title)
                .font(.caption)
                .foregroundStyle(.appSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppUI.standardPadding)
        .background(Color.appCard.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: AppUI.medium))
        .shadow(color: .black.opacity(AppUI.shadowOpacity * 1.5), radius: AppUI.shadowRadius - 2, x: 0, y: AppUI.shadowY) // 0.06, 8, 4
    }
}

// MARK: - Quick Action Row
struct QuickActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppUI.medium + AppUI.atomic * 2) { // 14
                // 渐变图标背景
                ZStack {
                    RoundedRectangle(cornerRadius: AppUI.small)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(AppUI.glassOpacity * 2), color.opacity(AppUI.glassOpacity * 0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: AppUI.Metrics.iconBoxSize + 4, height: AppUI.Metrics.iconBoxSize + 4) // 44

                    Image(systemName: icon)
                        .font(.system(size: AppUI.titleIconSize, weight: .semibold))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: AppUI.atomic * 1.5) { // 3
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.appText)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.appSecondary.opacity(AppUI.dimmedOpacity))
            }
            .padding(AppUI.medium + AppUI.atomic * 2) // 14
            .background(Color.appCard.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: AppUI.medium))
            .shadow(color: .black.opacity(isPressed ? AppUI.shadowOpacity : AppUI.shadowOpacity * 2), radius: isPressed ? AppUI.shadowRadius / 2.5 : AppUI.shadowRadius / 1.25, x: 0, y: isPressed ? AppUI.shadowY / 2 : AppUI.shadowY) // 4:8, 2:4
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
                }
        )
    }
}

// MARK: - Guide Step Row
struct GuideStepRow: View {
    let number: Int
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: AppUI.medium + AppUI.atomic * 2) { // 14
            // 带数字序号的渐变圆
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.appAccent, .appAccent.opacity(AppUI.secondaryOpacity)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: AppUI.largeIconSize, height: AppUI.largeIconSize) // 32
                    .shadow(color: .appAccent.opacity(AppUI.disabledOpacity), radius: AppUI.shadowRadius / 2.5, x: 0, y: AppUI.shadowY / 2) // 0.3, 4, 2

                Text("\(number)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.appText)

            Spacer()
        }
    }
}

// MARK: - Page Row View
struct PageRowView: View {
    let page: KnowledgePage
    var compact: Bool = false
    @Environment(AppStore.self) var store
    
    var body: some View {
        HStack(spacing: AppUI.medium) {
            // Type icon
            Image(systemName: page.displayIcon)
                .font(.body)
                .foregroundStyle(Color.fromModelColorName(page.type.colorName))
                .frame(width: AppUI.largeIconSize, height: AppUI.largeIconSize) // 32
                .background(Color.fromModelColorName(page.type.colorName).opacity(AppUI.glassOpacity * 1.5))
                .clipShape(RoundedRectangle(cornerRadius: AppUI.smallRadius))
            
            VStack(alignment: .leading, spacing: AppUI.atomic * 1.5) { // 3
                Text(page.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.appText)
                    .lineLimit(1)
                
                if !compact {
                    HStack(spacing: AppUI.small) {
                        Text(page.type.displayName)
                            .font(.caption2)
                            .padding(.horizontal, AppUI.small - AppUI.atomic) // 6
                            .padding(.vertical, AppUI.atomic)
                            .background(Color.fromModelColorName(page.type.colorName).opacity(AppUI.glassOpacity * 2))
                            .clipShape(Capsule())
                            .foregroundStyle(Color.fromModelColorName(page.type.colorName))
                        
                        Text(page.updated.formatted(Date.FormatStyle(date: .numeric, time: .omitted, locale: Localized.currentLocale)))
                            .font(.caption2)
                            .foregroundStyle(.appSecondary)
                        
                        if !page.tags.isEmpty {
                            Text(page.tags.prefix(2).joined(separator: ", "))
                                .font(.caption2)
                                .foregroundStyle(.appSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Status indicator
            Circle()
                .fill(Color.fromModelColorName(page.status.colorName))
                .frame(width: AppUI.smallIconSize / 2.5, height: AppUI.smallIconSize / 2.5) // 8
        }
        .padding(.horizontal, AppUI.medium)
        .padding(.vertical, AppUI.medium - AppUI.atomic) // 10
        .background(Color.appCard.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: AppUI.smallRadius))
        .contentShape(Rectangle()) // 确保整行可点
    }
}
