//
//  PluginStatsSection.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：系统设置：LLM 配置、性能监控、插件管理、iCloud、备份。
//
import SwiftUI

struct PluginStatsSection: View {
    @ObservedObject var registry = PluginRegistry.shared
    
    var body: some View {
        StandardSection(title: L10n.Plugin.Stats.resourceUsage) {
            if registry.pluginResourceUsage.isEmpty {
                AppEmptyState.simple(icon: "puzzlepiece.extension", title: L10n.Plugin.Stats.noUsage)
                    .padding()
            } else {
                VStack(spacing: 0) {
                    let sortedUsage = registry.pluginResourceUsage.sorted { $0.value.totalExecutionTime > $1.value.totalExecutionTime }
                    
                    ForEach(Array(sortedUsage.enumerated()), id: \.offset) { index, item in
                        let (id, usage) = item
                        HStack(spacing: DesignSystem.medium) {
                            // 状态图标
                            statusIcon(for: usage.status)
                            
                            VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                                Text(id)
                                    .font(.footnote.weight(.bold))
                                    .foregroundStyle(.appText)
                                
                                let avgMs = (usage.totalExecutionTime / Double(max(1, usage.callCount))) * 1000
                                Text(L10n.Plugin.Stats.callCountFormat(calls: usage.callCount, avgMs: avgMs))
                                    .font(.caption2)
                                    .foregroundStyle(.appSecondary)
                            }
                            
                            Spacer()
                            
                            // 总耗时进度条 (模拟占用感)
                            Text(String(format: "%.2fs", usage.totalExecutionTime))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(usage.status == .suspended ? .red : .appAccent)
                        }
                        .padding(.vertical, 10)
                        
                        if index < sortedUsage.count - 1 {
                            Divider().opacity(DesignSystem.Opacity.shadow)
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.medium)
            }
        }
    }
    
    @ViewBuilder
    private func statusIcon(for status: PluginRuntime.ResourceUsage.Status) -> some View {
        ZStack {
            Circle()
                .fill(statusColor(for: status).opacity(DesignSystem.Opacity.subtle))
                .frame(width: DesignSystem.IconSize.medium, height: DesignSystem.IconSize.medium)
            
            Image(systemName: statusImage(for: status))
                .font(.caption.weight(.bold))
                .foregroundStyle(statusColor(for: status))
        }
    }
    
    private func statusColor(for status: PluginRuntime.ResourceUsage.Status) -> Color {
        switch status {
        case .active: return .green
        case .throttled: return .orange
        case .suspended: return .red
        }
    }
    
    private func statusImage(for status: PluginRuntime.ResourceUsage.Status) -> String {
        switch status {
        case .active: return "bolt.fill"
        case .throttled: return "slowmo"
        case .suspended: return "nosign"
        }
    }
}
