// PerformanceDashboardView.swift
//
// 作者: Wang Chong
// 功能说明: 本文件定义了性能监控看板视图，用于展示系统资源占用与操作耗时等核心指标。
// 日期: 2026-05-07
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
                VStack(spacing: 20) {
                    // Memory
                    MetricCardView(
                        title: Localized.tr("perf.memory"),
                        value: String(format: "%.1f MB", service.metrics.memoryUsageMB),
                        icon: "memorychip",
                        color: .blue
                    )
                    
                    // Page Stats
                    HStack(spacing: 12) {
                        MetricCardView(
                            title: Localized.tr("perf.pages"),
                            value: "\(service.metrics.pageCount)",
                            icon: "doc.fill",
                            color: .green
                        )
                        MetricCardView(
                            title: Localized.tr("perf.words"),
                            value: "\(service.metrics.totalWords)",
                            icon: "textformat",
                            color: .purple
                        )
                    }
                    
                    // Graph Stats
                    HStack(spacing: 12) {
                        MetricCardView(
                            title: Localized.tr("perf.nodes"),
                            value: "\(service.metrics.graphNodeCount)",
                            icon: "circle.fill",
                            color: .orange
                        )
                        MetricCardView(
                            title: Localized.tr("perf.edges"),
                            value: "\(service.metrics.graphEdgeCount)",
                            icon: "line.diagonal",
                            color: .pink
                        )
                    }
                    
                    // Timing
                    VStack(alignment: .leading, spacing: 12) {
                        Text(Localized.tr("perf.timing"))
                            .font(.headline)
                            .foregroundStyle(.appText)
                        
                        TimingRowView(label: Localized.tr("perf.save"), duration: service.metrics.saveDuration, color: .green)
                        TimingRowView(label: Localized.tr("perf.load"), duration: service.metrics.loadDuration, color: .blue)
                        TimingRowView(label: Localized.tr("perf.lint"), duration: service.metrics.lintDuration, color: .orange)
                        TimingRowView(label: Localized.tr("perf.graphLayout"), duration: service.metrics.graphLayoutDuration, color: .purple)
                        TimingRowView(label: Localized.tr("perf.search"), duration: service.metrics.searchDuration, color: .pink)
                    }
                    .padding()
                    .background(Color.appCard)
                    .clipShape(RoundedRectangle(cornerRadius: AppUI.cardRadius))
                    
                    // Last Updated
                    Text(Localized.tr("perf.lastUpdated") + ": " + service.metrics.lastUpdated.formatted(Date.FormatStyle(locale: Localized.currentLocale)))
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                }
                .padding()
            }
            .background(AppUI.Background.pageBackground(accentColor: .appAccent))
            .navigationTitle(Localized.tr("perf.title"))
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        service.updateMemoryUsage()
                    } label: {
                        Image(systemName: "arrow.clockwise")
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
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.appText)
            Text(title)
                .font(.caption)
                .foregroundStyle(.appSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: AppUI.cardRadius))
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
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.appText)
                .frame(width: 100, alignment: .leading)
            
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: AppUI.microRadius)
                    .fill(color.opacity(0.3))
                    .frame(width: geo.size.width, height: AppUI.small)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: AppUI.microRadius)
                            .fill(color)
                            .frame(width: max(barWidth, duration > 0 ? AppUI.tiny : 0), height: AppUI.small)
                    }
            }
            .frame(height: AppUI.small)
            
            Text(String(format: "%.3fs", duration))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.appSecondary)
                .frame(width: 60, alignment: .trailing)
        }
    }
}
