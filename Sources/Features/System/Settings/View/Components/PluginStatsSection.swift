// PluginStatsSection.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 插件资源监控组件，展示 Watchdog 2.0 采集的性能排行
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

struct PluginStatsSection: View {
    @ObservedObject var registry = PluginRegistry.shared
    
    var body: some View {
        StandardSection(title: L10n.Plugin.Stats.resourceUsage) {
            if registry.pluginResourceUsage.isEmpty {
                Text(L10n.Plugin.Stats.noUsage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                VStack(spacing: 0) {
                    let sortedUsage = registry.pluginResourceUsage.sorted { $0.value.totalExecutionTime > $1.value.totalExecutionTime }
                    
                    ForEach(Array(sortedUsage.enumerated()), id: \.offset) { index, item in
                        let (id, usage) = item
                        HStack(spacing: 12) {
                            // 状态图标
                            statusIcon(for: usage.status)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(id)
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.appText)
                                
                                let avgMs = (usage.totalExecutionTime / Double(max(1, usage.callCount))) * 1000
                                Text(L10n.Plugin.Stats.callCountFormat(calls: usage.callCount, avgMs: avgMs))
                                    .font(.system(size: 10))
                                    .foregroundStyle(.appSecondary)
                            }
                            
                            Spacer()
                            
                            // 总耗时进度条 (模拟占用感)
                            Text(String(format: "%.2fs", usage.totalExecutionTime))
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(usage.status == .suspended ? .red : .appAccent)
                        }
                        .padding(.vertical, 10)
                        
                        if index < sortedUsage.count - 1 {
                            Divider().opacity(0.3)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
        }
    }
    
    @ViewBuilder
    private func statusIcon(for status: PluginRegistry.ResourceUsage.Status) -> some View {
        ZStack {
            Circle()
                .fill(statusColor(for: status).opacity(0.1))
                .frame(width: 28, height: 28)
            
            Image(systemName: statusImage(for: status))
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(statusColor(for: status))
        }
    }
    
    private func statusColor(for status: PluginRegistry.ResourceUsage.Status) -> Color {
        switch status {
        case .active: return .green
        case .throttled: return .orange
        case .suspended: return .red
        }
    }
    
    private func statusImage(for status: PluginRegistry.ResourceUsage.Status) -> String {
        switch status {
        case .active: return "bolt.fill"
        case .throttled: return "slowmo"
        case .suspended: return "nosign"
        }
    }
}
