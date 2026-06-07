//
//  PerformanceDashboardView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：构建 PerformanceDashboard 界面的 UI 视图层组件。
//
import SwiftUI

// MARK: - Performance Dashboard View
/// 性能监控看板主视图
/// 负责实时展示内存占用、页面规模、图谱密度及核心算法耗时，帮助开发者诊断系统性能瓶颈
struct PerformanceDashboardView: View {
    @ObservedObject var service: PerformanceService
    @Environment(\.dismiss) private var dismiss
    @State private var timer: Timer?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.wide) {
                    // Memory
                    MetricCardView(
                        title: L10n.Common.Perf.memory,
                        value: String(format: "%.1f MB", service.metrics.memoryUsageMB),
                        icon: "memorychip",
                        color: .blue
                    )
                    
                    // Page Stats
                    HStack(spacing: DesignSystem.medium) {
                        MetricCardView(
                            title: L10n.Common.Perf.pages,
                            value: "\(service.metrics.pageCount)",
                            icon: "doc.fill",
                            color: .green
                        )
                        MetricCardView(
                            title: L10n.Common.Perf.words,
                            value: "\(service.metrics.totalWords)",
                            icon: "textformat",
                            color: .purple
                        )
                    }
                    
                    // Graph Stats
                    HStack(spacing: DesignSystem.medium) {
                        MetricCardView(
                            title: L10n.Common.Perf.nodes,
                            value: "\(service.metrics.graphNodeCount)",
                            icon: "circle.fill",
                            color: .orange
                        )
                        MetricCardView(
                            title: L10n.Common.Perf.edges,
                            value: "\(service.metrics.graphEdgeCount)",
                            icon: "line.diagonal",
                            color: .pink
                        )
                    }
                    
                    // Timing
                    VStack(alignment: .leading, spacing: DesignSystem.medium) {
                        Text(L10n.Common.Perf.timing)
                            .font(.headline)
                            .foregroundStyle(.appText)
                        
                        TimingRowView(label: L10n.Common.Perf.save, duration: service.metrics.saveDuration, color: .green)
                        TimingRowView(label: L10n.Common.Perf.load, duration: service.metrics.loadDuration, color: .blue)
                        TimingRowView(label: L10n.Common.Perf.lint, duration: service.metrics.lintDuration, color: .orange)
                        TimingRowView(label: L10n.Common.Perf.graphLayout, duration: service.metrics.graphLayoutDuration, color: .purple)
                        TimingRowView(label: L10n.Common.Perf.search, duration: service.metrics.searchDuration, color: .pink)
                    }
                    .padding()
                    .background(Color.appCard)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
                    
                    // Last Updated
                    Text(L10n.Common.Perf.lastUpdated + ": " + service.metrics.lastUpdated.formatted(Date.FormatStyle(locale: Localized.currentLocale)))
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                }
                .padding()
            }
            .background(PageBackgroundView(accentColor: .appAccent))
            .navigationTitle(L10n.Common.Perf.title)
.appNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        service.updateMemoryUsage()
                    } label: {
                        Image(systemName: DesignSystem.Icons.refresh)
                    }
                }
            }
            .onAppear {
                service.updateMemoryUsage()
                timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak service] _ in
                    Task { @MainActor in
                        service?.updateMemoryUsage()
                    }
                }
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
    }
}

// MARK: - Metric Card
/// 性能指标卡片小组件
struct MetricCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.small) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.appText)
            Text(title)
                .font(.caption)
                .foregroundStyle(.appSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
    }
}

// MARK: - Timing Row
/// 耗时分析行小组件，具备动态进度条展示
struct TimingRowView: View {
    let label: String
    let duration: TimeInterval
    let color: Color
    
    private var barWidth: CGFloat {
        let maxDuration: CGFloat = 1.0
        return min(CGFloat(duration) / maxDuration, 1.0) * 200
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.medium) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.appText)
                .frame(width: 100, alignment: .leading)
            
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: DesignSystem.microRadius)
                    .fill(color.opacity(0.3))
                    .frame(width: geo.size.width, height: DesignSystem.small)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: DesignSystem.microRadius)
                            .fill(color)
                            .frame(width: max(barWidth, duration > 0 ? DesignSystem.tiny : 0), height: DesignSystem.small)
                    }
            }
            .frame(height: DesignSystem.small)
            
            Text(String(format: "%.3fs", duration))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.appSecondary)
                .frame(width: 60, alignment: .trailing)
        }
    }
}
