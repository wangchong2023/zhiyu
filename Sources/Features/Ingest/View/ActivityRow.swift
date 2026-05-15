// ActivityRow.swift
//
// 作者: Wang Chong
// 功能说明: 摄入活动行展示组件。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

struct ActivityRow: View {
    let task: GlobalTask
    @Environment(Router.self) var router
    var body: some View {
        Button(action: { if let id = task.associatedPageID { HapticFeedback.shared.trigger(.selection); router.navigateToPage(id: id) } }) {
            HStack(spacing: DesignSystem.medium) {
                ZStack {
                    Circle().fill(taskColor.opacity(DesignSystem.glassOpacity)).frame(width: DesignSystem.Metrics.smallIconBoxSize + DesignSystem.atomic * 2, height: DesignSystem.Metrics.smallIconBoxSize + DesignSystem.atomic * 2)
                    Image(systemName: taskIcon).font(.system(size: DesignSystem.subheadlineFontSize)).foregroundStyle(taskColor)
                }
                VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                    Text(task.name + ": " + task.target).font(.system(size: DesignSystem.subheadlineFontSize, weight: .medium)).foregroundStyle(.appText).lineLimit(1)
                    Text(task.startTime.formatted(Date.FormatStyle(locale: Localized.currentLocale))).font(.system(size: DesignSystem.captionFontSize)).foregroundStyle(.appSecondary)
                }
                Spacer()
                if task.associatedPageID != nil { Image(systemName: "chevron.right").font(.system(size: DesignSystem.captionFontSize, weight: .bold)).foregroundStyle(.appSecondary.opacity(DesignSystem.disabledOpacity)) }
            }.padding(.vertical, DesignSystem.tightPadding + DesignSystem.atomic).padding(.horizontal, DesignSystem.medium)
        }.buttonStyle(.plain)
    }
    private var taskColor: Color {
        switch task.status {
        case .completed: return .green
        case .failed: return .red
        case .running: return .blue
        case .pending: return .gray
        }
    }
    private var taskIcon: String {
        switch task.status {
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle.fill"
        case .running: return "arrow.triangle.2.circlepath"
        case .pending: return "clock"
        }
    }
}
