//
//  SystemStatsView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：构建 SystemStats 界面的 UI 视图层组件。
//
import SwiftUI
import Charts

// MARK: - 资源监控视图
/// [L3] 表现层：资源监控视图 (原资源监控)
/// 提供 AI 资源消耗、存储空间分布及数据溯源的多维度监控。
struct SystemStatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppStore.self) var store
    @EnvironmentObject var themeManager: ThemeManager
    
    // 使用协调器管理状态与交互
    @State private var coordinator = SystemStatsCoordinator()
    @State private var selectedTab: Tab = .performance
    
    enum Tab: String, CaseIterable {
        case performance = "performance"
        case storage = "storage"
        
        var title: String {
            switch self {
            case .performance: return L10n.Dashboard.stats.tabPerf
            case .storage: return L10n.Dashboard.stats.tabStorage
            }
        }
    }
    
    var body: some View {
        ZStack {
            themeManager.pageBackground()
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    // 分段选择器
                    Picker("", selection: $selectedTab) {
                        ForEach(Tab.allCases, id: \.self) { tab in
                            Text(tab.title).tag(tab)
                        }
                    }
                    #if !os(watchOS)
                .pickerStyle(.segmented)
                #endif
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.medium)
                    
                    if coordinator.isLoading {
                        VStack {
                            ProgressView()
                                .padding(.vertical, DesignSystem.large * 2.5)
                        }
                    } else {
                        switch selectedTab {
                        case .performance:
                            performanceSection
                        case .storage:
                            storageSection
                        }
                    }
                }
                .padding(.bottom, DesignSystem.large * 2) // 底部留白
            }
            .background(PageBackgroundView(accentColor: .appAccent))
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle(L10n.Dashboard.stats.navigationTitleMonitor)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.Common.done) {
                    dismiss()
                }
                .bold()
            }
        }
        .task {
            await coordinator.loadStats()
        }
    }
    
    // MARK: - 性能与 AI 资源分区
    @ViewBuilder
    private var performanceSection: some View {
        Group {
            // 1. API 请求卡片
            StandardSection(title: L10n.Dashboard.apiRequests + " (\(L10n.Dashboard.stats.rangeThirtyDays))") {
                VStack(alignment: .leading, spacing: Spacing.tiny) {
                    HStack(alignment: .firstTextBaseline, spacing: DesignSystem.small) {
                        Text("\(coordinator.dailyStats.reduce(0) { $0 + $1.requests })")
                            .font(.system(size: DesignSystem.titleFontSize, weight: .bold, design: .rounded))
                            .foregroundStyle(.appText)
                        Text(L10n.Dashboard.stats.requestsUsage)
                            .font(.caption)
                            .foregroundStyle(.appSecondary)
                    }
                    
                    ChartView(stats: coordinator.dailyStats, type: .requests)
                        .frame(height: DesignSystem.Metrics.chartHeight - 40)
                }
                .padding(Spacing.medium)
            }
            
            // 2. Token 消耗卡片
            StandardSection(title: L10n.Dashboard.stats.tokensUsage + " (\(L10n.Dashboard.stats.rangeThirtyDays))") {
                VStack(alignment: .leading, spacing: Spacing.tiny) {
                    HStack(alignment: .firstTextBaseline, spacing: DesignSystem.small) {
                        Text("\(coordinator.dailyStats.reduce(0) { $0 + $1.tokens })")
                            .font(.system(size: DesignSystem.titleFontSize, weight: .bold, design: .rounded))
                            .foregroundStyle(.appText)
                        Text(L10n.Dashboard.tokens)
                            .font(.caption)
                            .foregroundStyle(.appSecondary)
                    }
                    
                    ChartView(stats: coordinator.dailyStats, type: .tokens)
                        .frame(height: DesignSystem.Metrics.chartHeight - 40)
                }
                .padding(Spacing.medium)
            }
            
            // 3. 响应时延卡片
            StandardSection(title: L10n.Dashboard.stats.latencyTitle + " (\(L10n.Dashboard.stats.rangeThirtyDays))") {
                VStack(alignment: .leading, spacing: DesignSystem.standardPadding) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                            Text(L10n.Dashboard.stats.avgLatencyShort)
                                .font(.caption)
                                .foregroundStyle(.appSecondary)
                            
                            HStack(alignment: .firstTextBaseline, spacing: DesignSystem.tiny) {
                                Text("\(coordinator.avgLatency)")
                                    .font(.system(size: DesignSystem.displayFontSize, weight: .bold, design: .rounded))
                                    .foregroundColor(.appText)
                                Text(L10n.Dashboard.unitMs)
                                    .font(.system(size: DesignSystem.subheadlineFontSize, weight: .semibold))
                                    .foregroundColor(.appSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill((coordinator.avgLatency > AppConstants.Performance.latencyWarningThreshold ? Color.orange : Color.appAccent).opacity(0.1))
                                .frame(width: 44, height: 44)
                            Image(systemName: DesignSystem.Icons.timer)
                                .font(.title3.bold())
                                .foregroundColor(coordinator.avgLatency > AppConstants.Performance.latencyWarningThreshold ? Color.orange : .appAccent)
                        }
                    }
                    
                    Divider()
                        .opacity(DesignSystem.softOpacity)
                    
                    HStack(spacing: 0) {
                        latencySubValue(label: L10n.Dashboard.stats.maxLatency, value: "\(coordinator.maxLatency)")
                        divider
                        latencySubValue(label: L10n.Dashboard.stats.minLatency, value: "\(coordinator.minLatency)")
                        divider
                        latencySubValue(label: L10n.Dashboard.stats.measureCount, value: "\(coordinator.latencyCount)")
                    }
                }
                .padding(Spacing.medium)
            }
            
            // 4. 插件资源占用
            PluginStatsSection()
        }
    }
    
    // MARK: - 存储与治理分区
    @ViewBuilder
    private var storageSection: some View {
        Group {
            // 1. 知识库资产分布 (饼图 + 详细图例)
            StandardSection(title: L10n.Dashboard.stats.storageDistribution) {
                VStack(spacing: Spacing.medium) {
                    if coordinator.storageCategories.isEmpty {
                        ProgressView()
                            .frame(height: DesignSystem.Metrics.chartHeight - 20)
                    } else if coordinator.storageCategories.allSatisfy({ $0.value == 0 }) {
                        VStack(spacing: Spacing.medium) {
                            Image(systemName: DesignSystem.Icons.chartPie)
                                .font(.system(size: DesignSystem.Gallery.iconSize))
                                .foregroundStyle(.appSecondary.opacity(DesignSystem.softOpacity))
                            Text(L10n.Common.Global.noData)
                                .font(.caption)
                                .foregroundStyle(.appSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignSystem.Metrics.chartHeight - 20)
                    } else {
                        HStack(spacing: Spacing.medium) {
                            chartContainer
                                #if !os(watchOS)
        .frame(maxWidth: .infinity, alignment: .center)
        #endif
                            
                            legendContainer
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, Spacing.small)
                    }
                }
                .padding(Spacing.medium)
            }
            
            // 2. 存储空间分布列表
            StandardSection(title: L10n.Dashboard.stats.storageDetails) {
                ForEach(coordinator.storageCategories.indices, id: \.self) { index in
                    let category = coordinator.storageCategories[index]
                    HStack(spacing: Spacing.standardPadding) {
                        Image(systemName: coordinator.iconForCategory(category.label))
                            .foregroundStyle(category.color)
                            .frame(width: DesignSystem.giant)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                            Text(category.label)
                                .foregroundStyle(.appText)
                            
                            if category.label == L10n.Dashboard.System.database {
                                Text(L10n.Dashboard.stats.multiVaultDesc(category.count))
                                    .font(.system(size: DesignSystem.microFontSize))
                                    .foregroundStyle(.appSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: DesignSystem.atomic) {
                            HStack(spacing: DesignSystem.tiny) {
                                Text(coordinator.formatBytes(category.value))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.appText)
                            }
                            
                            if coordinator.totalStorage > 0 {
                                let percent = Int(Double(category.value) / Double(coordinator.totalStorage) * 100)
                                Text("\(percent)%")
                                    .font(.system(size: DesignSystem.microFontSize, design: .rounded))
                                    .foregroundStyle(.appSecondary)
                            }
                        }
                    }
                    .appListRowStyle(showDivider: index < coordinator.storageCategories.count - 1)
                }
            }
            
            // 2.5 各笔记本存储占用 (仅在存在多笔记本时渲染)
            if !coordinator.vaultStorageItems.isEmpty {
                StandardSection(title: L10n.Dashboard.stats.vaultStorageTitle) {
                    ForEach(coordinator.vaultStorageItems.indices, id: \.self) { index in
                        let item = coordinator.vaultStorageItems[index]
                        HStack(spacing: Spacing.standardPadding) {
                            // 笔记本专属图标
                            ZStack {
                                Circle()
                                    .fill(Color.appAccent.opacity(0.1))
                                    .frame(width: 32, height: 32)
                                Image(systemName: item.icon.isEmpty ? "books.vertical.fill" : item.icon)
                                    .font(.system(size: DesignSystem.captionFontSize))
                                    .foregroundStyle(.appAccent)
                            }
                            
                            VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                                Text(item.name)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.appText)
                                
                                // 当前是否处于激活/选中使用中
                                if item.id == VaultService.shared.selectedVaultID {
                                    Text(L10n.Dashboard.stats.activeVaultStatus)
                                        .font(.caption2)
                                        .foregroundStyle(Color.green)
                                } else {
                                    Text(L10n.Dashboard.stats.inactiveVaultStatus)
                                        .font(.caption2)
                                        .foregroundStyle(.appSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: DesignSystem.atomic) {
                                Text(coordinator.formatBytes(item.size))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.appText)
                                
                                // 计算所占总数据库大小的百分比
                                let dbTotal = coordinator.storageCategories.first { $0.label == L10n.Dashboard.System.database }?.value ?? 1
                                let percent = Int(Double(item.size) / Double(max(1, dbTotal)) * 100)
                                Text("\(percent)%")
                                    .font(.system(size: DesignSystem.microFontSize, design: .rounded))
                                    .foregroundStyle(.appSecondary)
                            }
                        }
                        .appListRowStyle(showDivider: index < coordinator.vaultStorageItems.count - 1)
                    }
                }
            }
            
            // 3. 治理与维护
            StandardSection(title: L10n.Dashboard.maintenance) {
                VStack(alignment: .leading, spacing: DesignSystem.medium) {
                    Button(action: { Task { await coordinator.cleanupData() } }) {
                        HStack {
                            Label(L10n.Dashboard.cleanupAction, systemImage: "sparkles")
                            Spacer()
                            if coordinator.isCleaning {
                                ProgressView()
                            } else {
                                Image(systemName: DesignSystem.Icons.forward)
                                    .font(.caption)
                                    .foregroundStyle(.appSecondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.appAccent)
                    
                    if let count = coordinator.cleanedCount {
                        Text("\(L10n.Dashboard.cleanedPrefix) \(count) \(L10n.Dashboard.cleanedSuffix)")
                            .font(.caption)
                            .foregroundColor(Color.green)
                    }
                }
                .padding(Spacing.medium)
            }
        }
    }
    
    // MARK: - 辅助组件
    
    private var chartContainer: some View {
        ZStack {
            Chart(coordinator.storageCategories) { category in
                SectorMark(
                    angle: .value("Size", Double(category.value)),
                    innerRadius: .ratio(0.65),
                    angularInset: 3
                )
                .cornerRadius(6)
                .foregroundStyle(category.color)
            }
            .chartLegend(.hidden)
            .frame(height: DesignSystem.Metrics.chartHeight - 40)
            
            VStack(spacing: DesignSystem.tiny) {
                Text(coordinator.formatBytes(coordinator.totalStorage))
                    .font(.system(size: DesignSystem.titleFontSize + 2, weight: .bold, design: .rounded))
                    .foregroundStyle(.appAccent)
                Text(L10n.Dashboard.totalStorage)
                    .font(.system(size: DesignSystem.microFontSize, weight: .black))
                    .foregroundStyle(.appSecondary)
                    .kerning(1)
                    .textCase(.uppercase)
            }
        }
    }
    
    private var legendContainer: some View {
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            ForEach(coordinator.storageCategories) { category in
                HStack(spacing: DesignSystem.tiny) {
                    Circle()
                        .fill(category.color)
                        .frame(width: DesignSystem.tiny + 2, height: DesignSystem.tiny + 2)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(category.label)
                            .font(DesignSystem.caption2Font)
                            .foregroundStyle(.appText)
                            .lineLimit(1)
                        HStack(spacing: DesignSystem.tiny) {
                            Text(coordinator.formatBytes(category.value))
                            let percent = coordinator.totalStorage > 0 ? Int(Double(category.value) / Double(coordinator.totalStorage) * 100) : 0
                            Text("(\(percent)%)")
                        }
                        .font(.system(size: DesignSystem.microFontSize))
                        .foregroundStyle(.appSecondary)
                    }
                }
            }
        }
    }
    
    // MARK: - 时延卡片辅助
    
    private func latencySubValue(label: String, value: String) -> some View {
        VStack(alignment: .center, spacing: DesignSystem.tiny) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.appSecondary)
            
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.appText)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var divider: some View {
        Divider()
            .frame(height: 16)
            .padding(.horizontal, DesignSystem.tiny)
    }
}

// MARK: - 子视图：资源图表实现
struct ChartView: View {
    enum ChartType {
        case requests
        case tokens
    }
    
    let stats: [DailyAIUsage]
    let type: ChartType
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedDate: Date?
    
    var body: some View {
        if stats.isEmpty {
            VStack(spacing: DesignSystem.small) {
                Image(systemName: DesignSystem.Icons.chartLine)
                    .font(.system(size: DesignSystem.displayFontSize))
                    .foregroundStyle(.appSecondary.opacity(DesignSystem.softOpacity))
                Text(L10n.Common.Global.noData)
                    .font(.caption2)
                    .foregroundStyle(.appSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Metrics.chartHeight - 60)
            .background(Color.appCard.opacity(DesignSystem.softOpacity))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
        } else {
            switch type {
            case .requests:
                requestsChart
            case .tokens:
                tokensChart
            }
        }
    }
    
    @ViewBuilder
    private var requestsChart: some View {
        let monthRange = currentMonthRange()
        let start = monthRange.start
        let end = monthRange.end.addingTimeInterval(86400)
        let domainX = start...end
        let domainY = 0.0...(max(100.0, maxValue() * 1.2))
        
        Chart {
            ForEach(stats) { stat in
                AreaMark(
                    x: .value(L10n.Dashboard.chartDate, stat.date, unit: .day),
                    y: .value(L10n.Dashboard.chartValue, Double(stat.requests))
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.01)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                
                LineMark(
                    x: .value(L10n.Dashboard.chartDate, stat.date, unit: .day),
                    y: .value(L10n.Dashboard.chartValue, Double(stat.requests))
                )
                .foregroundStyle(themeManager.accentColor)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
            
            if let selectedDate {
                RuleMark(x: .value(L10n.Dashboard.chartSelected, selectedDate, unit: .day))
                    .foregroundStyle(Color.appSecondary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [2]))
                    .annotation(position: .automatic, alignment: .center, spacing: DesignSystem.tiny) {
                        if let stat = stats.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
                            tooltipView(stat: stat)
                        }
                    }
                
                if let stat = stats.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
                    PointMark(
                        x: .value(L10n.Dashboard.chartSelected, selectedDate, unit: .day),
                        y: .value(L10n.Dashboard.chartValue, Double(stat.requests))
                    )
                    .symbol {
                        Circle()
                            .stroke(themeManager.accentColor, lineWidth: 2)
                            .background(Circle().fill(.white))
                            .frame(width: DesignSystem.small, height: DesignSystem.small)
                    }
                }
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartXAxis { xAxisMarks }
        .chartYAxis { yAxisMarks }
        .chartXScale(domain: domainX)
        .chartYScale(domain: domainY)
    }
    
    @ViewBuilder
    private var tokensChart: some View {
        let monthRange = currentMonthRange()
        let start = monthRange.start
        let end = monthRange.end.addingTimeInterval(86400)
        let domainX = start...end
        let domainY = 0.0...(max(100.0, maxValue() * 1.2))
        
        Chart {
            ForEach(stats) { stat in
                BarMark(
                    x: .value(L10n.Dashboard.chartDate, stat.date, unit: .day),
                    y: .value(L10n.Dashboard.chartValue, Double(stat.tokens)),
                    width: .fixed(DesignSystem.small)
                )
                .foregroundStyle(themeManager.accentColor.opacity(0.7).gradient)
                .cornerRadius(1)
            }
            
            if let selectedDate {
                RuleMark(x: .value(L10n.Dashboard.chartSelected, selectedDate, unit: .day))
                    .foregroundStyle(Color.appSecondary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [2]))
                    .annotation(position: .automatic, alignment: .center, spacing: DesignSystem.tiny) {
                        if let stat = stats.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
                            tooltipView(stat: stat)
                        }
                    }
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartXAxis { xAxisMarks }
        .chartYAxis { yAxisMarks }
        .chartXScale(domain: domainX)
        .chartYScale(domain: domainY)
    }
    
    @AxisContentBuilder
    private var xAxisMarks: some AxisContent {
        AxisMarks(values: .stride(by: .day, count: 7)) { value in
            AxisGridLine().foregroundStyle(.appBorder.opacity(DesignSystem.softOpacity))
            AxisValueLabel(anchor: .topTrailing) {
                if let date = value.as(Date.self) {
                    Text(formatDate(date))
                        .font(.system(size: DesignSystem.microFontSize))
                        .foregroundStyle(.appSecondary)
                }
            }
        }
    }
    
    @AxisContentBuilder
    private var yAxisMarks: some AxisContent {
        AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
            AxisGridLine().foregroundStyle(.appBorder.opacity(0.5))
            AxisValueLabel {
                if let intValue = value.as(Int.self) {
                    Text("\(intValue)")
                        .font(.system(size: DesignSystem.microFontSize))
                        .foregroundStyle(.appSecondary)
                }
            }
        }
    }
    
    private func currentMonthRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else { return (now, now) }
        return (startOfMonth, endOfMonth)
    }
    
    private func tooltipView(stat: DailyAIUsage) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.tiny) {
            Text(stat.date, format: .dateTime.year().month().day())
                .font(.system(size: DesignSystem.captionFontSize, weight: .bold))
                .foregroundStyle(.appText)
            
            HStack(spacing: DesignSystem.tiny) {
                Text(type == .requests ? L10n.Dashboard.apiRequests : L10n.Dashboard.tokens)
                    .font(.system(size: DesignSystem.caption2FontSize))
                    .foregroundStyle(.appSecondary)
                Text("\(type == .requests ? stat.requests : stat.tokens)")
                    .font(.system(size: DesignSystem.caption2FontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(.appText)
            }
        }
        .padding(.horizontal, DesignSystem.medium)
        .padding(.vertical, DesignSystem.small)
        .background {
            RoundedRectangle(cornerRadius: Spacing.Chip.cornerRadius, style: .continuous)
                .fill(Color.appCard)
                .appStandardShadow()
        }
    }
    
    private func maxValue() -> Double {
        let maxVal = stats.map { type == .requests ? Double($0.requests) : Double($0.tokens) }.max() ?? 100
        return maxVal == 0 ? 100 : maxVal
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M-d"
        return formatter.string(from: date)
    }
}
