// SystemStatsView.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了知识管理系统的资源监控中心（SystemMonitorView）。
// 作为系统的“仪表盘”，该视图为用户提供了关于 AI 资源消耗、存储分布及 RAG 质量评估的深度可观测性：
// 1. Token 消耗分析：展示最近 30 天的 Token 使用趋势，帮助用户掌握 AI 运行成本。
// 2. 存储空间分布：分类统计不同业务层级（Entity, Concept 等）的磁盘占用。
// 3. 知识溯源监控：新增“导入 vs 自建”维度统计，量化知识库的自动化程度。
// 4. 性能与质量评估：实时展示平均响应时延及基于 RAGAS 标准的 Faithfulness、Relevance 指标。
// 5. 自动化维护：提供孤立数据块清理入口，保障数据库的长期高性能运行。
// 版本: 1.2
// 修改记录:
//   - 2026-05-06: 重命名为“资源监控”，引入分段 Tab 布局，增加知识溯源（导入/自建）统计维度。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI
import Charts

// MARK: - 模型定义
struct DailyAIUsage: Identifiable {
    let id = UUID()
    let date: Date
    let dateString: String
    let tokens: Int
    let requests: Int
}

struct MonthlyToken: Identifiable {
    let id = UUID()
    let month: String
    let total: Int
}


// MARK: - 资源监控视图
/// [L3] 表现层：资源监控视图 (原资源监控)
/// 提供 AI 资源消耗、存储空间分布及数据溯源的多维度监控。
struct SystemStatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Inject private var sqliteStore: SQLiteStore
    
    struct StorageCategory: Identifiable {
        let id = UUID()
        let label: String
        let value: Int64
        let count: Int
        let color: Color
    }
    
    enum Tab: String, CaseIterable {
        case performance = "performance"
        case storage = "storage"
        
        var title: String {
            switch self {
            case .performance: return L10n.Dashboard.tr("stats.tabPerf")
            case .storage: return L10n.Dashboard.tr("stats.tabStorage")
            }
        }
    }
    
    // ── 数据状态 ──
    @State private var selectedTab: Tab = .performance
    @State private var dailyStats: [DailyAIUsage] = []
    @State private var monthlyStats: [MonthlyToken] = []
    @State private var totalStorage: Int64 = 0
    @State private var provenance: (importedCount: Int, importedSize: Int64, createdCount: Int, createdSize: Int64) = (0, 0, 0, 0)
    @State private var exportCount: Int = 0
    @State private var exportSize: Int64 = 0 // 导出总大小
    @State private var totalExportSize: Int64 = 0
    @State private var avgLatency: Int = 0
    @State private var storageCategories: [StorageCategory] = []
    @State private var totalPages: Int = 0
    @Environment(AppStore.self) var store
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingDetails = false
    @State private var isLoading = true
    @State private var isCleaning = false
    @State private var cleanedCount: Int? = nil
    
    var body: some View {
        ZStack {
            themeManager.pageBackground()
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    // 分段选择器
                    StandardSection {
                        Picker("", selection: $selectedTab) {
                            ForEach(Tab.allCases, id: \.self) { tab in
                                Text(tab.title).tag(tab)
                            }
                        }
                        #if !os(watchOS)
                        .pickerStyle(.segmented)
                        #endif
                        .padding(Spacing.tiny)
                    }
                    .padding(.top, Spacing.medium)
                    
                    if isLoading {
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
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle(L10n.Dashboard.tr("stats.navigationTitleMonitor"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadStats()
        }
    }
}
    
    // MARK: - 性能与 AI 资源分区
    @ViewBuilder
    private var performanceSection: some View {
        Group {
            // 1. API 请求卡片
            StandardSection(title: L10n.Dashboard.apiRequests) {
                VStack(alignment: .leading, spacing: Spacing.tiny) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(dailyStats.reduce(0) { $0 + $1.requests })")
                            .font(.system(size: DesignSystem.titleFontSize, weight: .bold, design: .rounded))
                            .foregroundStyle(.appText)
                        Text(L10n.Dashboard.tr("stats.requestsUsage"))
                            .font(.caption)
                            .foregroundStyle(.appSecondary)
                    }
                    
                    ChartView(stats: dailyStats, type: .requests)
                        .frame(height: DesignSystem.Metrics.chartHeight - 40)
                }
                .padding(Spacing.medium)
            }
            
            // 2. Token 消耗卡片
            StandardSection(title: L10n.Dashboard.tr("stats.tokensUsage")) {
                VStack(alignment: .leading, spacing: Spacing.tiny) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(dailyStats.reduce(0) { $0 + $1.tokens })")
                            .font(.system(size: DesignSystem.titleFontSize, weight: .bold, design: .rounded))
                            .foregroundStyle(.appText)
                        Text(L10n.Dashboard.tokens)
                            .font(.caption)
                            .foregroundStyle(.appSecondary)
                    }
                    
                    ChartView(stats: dailyStats, type: .tokens)
                        .frame(height: DesignSystem.Metrics.chartHeight - 40)
                }
                .padding(Spacing.medium)
            }
            
            // 3. 响应时延卡片
            StandardSection(title: L10n.Dashboard.tr("stats.avgLatency")) {
                HStack(spacing: Spacing.standardPadding) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill((avgLatency > AppConstants.Performance.latencyWarningThreshold ? Color.orange : Color.appAccent).opacity(0.15))
                                    .frame(width: DesignSystem.Metrics.iconBoxSize - 8, height: DesignSystem.Metrics.iconBoxSize - 8)
                                Image(systemName: "timer")
                                    .font(.system(size: DesignSystem.subheadlineFontSize, weight: .bold))
                                    .foregroundColor(avgLatency > AppConstants.Performance.latencyWarningThreshold ? Color.orange : .appAccent)
                            }
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(avgLatency)")
                                    .font(.system(size: DesignSystem.displayFontSize, weight: .bold, design: .rounded))
                                    .foregroundColor(.appText)
                                Text(L10n.Dashboard.unitMs)
                                    .font(.system(size: DesignSystem.subheadlineFontSize, weight: .semibold))
                                    .foregroundColor(.appSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(Spacing.medium)
            }
        }
    }
    
    // MARK: - 存储与治理分区
    @ViewBuilder
    private var storageSection: some View {
        Group {
            // 1. 知识库资产分布 (饼图 + 详细图例)
            StandardSection(title: L10n.Dashboard.tr("stats.storageDistribution")) {
                VStack(spacing: Spacing.medium) {
                    if storageCategories.isEmpty {
                        ProgressView()
                            .frame(height: DesignSystem.Metrics.chartHeight - 20)
                    } else if storageCategories.allSatisfy({ $0.value == 0 }) {
                        VStack(spacing: Spacing.medium) {
                            Image(systemName: "chart.pie")
                                .font(.system(size: DesignSystem.Gallery.iconSize))
                                .foregroundStyle(.appSecondary.opacity(0.3))
                            Text(L10n.Common.Empty.tr("noData"))
                                .font(.caption)
                                .foregroundStyle(.appSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignSystem.Metrics.chartHeight - 20)
                    } else {
                        HStack(spacing: Spacing.medium) {
                            #if os(watchOS)
                            chartContainer
                            #else
                            chartContainer
                                .frame(maxWidth: .infinity)
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
            StandardSection(title: L10n.Dashboard.tr("stats.storageDetails")) {
                ForEach(storageCategories.indices, id: \.self) { index in
                    let category = storageCategories[index]
                    HStack(spacing: Spacing.standardPadding) {
                        Image(systemName: iconForCategory(category.label))
                            .foregroundStyle(category.color)
                            .frame(width: DesignSystem.giant)
                        
                        Text(category.label)
                            .foregroundStyle(.appText)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(formatBytes(category.value))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.appText)
                            }
                            
                            if totalStorage > 0 {
                                let percent = Int(Double(category.value) / Double(totalStorage) * 100)
                                Text("\(percent)%")
                                    .font(.system(size: DesignSystem.microFontSize, design: .rounded))
                                    .foregroundStyle(.appSecondary)
                            }
                        }
                    }
                    .appListRowStyle(showDivider: index < storageCategories.count - 1)
                }
            }
            
            // 3. 治理与维护
            StandardSection(title: L10n.Dashboard.maintenance) {
                VStack(alignment: .leading, spacing: 12) {
                    Button(action: { Task { await cleanupData() } }) {
                        HStack {
                            Label(L10n.Dashboard.cleanupAction, systemImage: "sparkles")
                            Spacer()
                            if isCleaning {
                                ProgressView()
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.appSecondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.appAccent)
                    
                    if let count = cleanedCount {
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
            Chart(storageCategories) { category in
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
            
            VStack(spacing: 4) {
                Text(formatBytes(totalStorage))
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
            ForEach(storageCategories) { category in
                HStack(spacing: DesignSystem.tiny) {
                    Circle()
                        .fill(category.color)
                        .frame(width: DesignSystem.tiny + 2, height: DesignSystem.tiny + 2)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(category.label)
                            .font(DesignSystem.caption2Font)
                            .foregroundStyle(.appText)
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            Text(formatBytes(category.value))
                            let percent = totalStorage > 0 ? Int(Double(category.value) / Double(totalStorage) * 100) : 0
                            Text("(\(percent)%)")
                        }
                        .font(.system(size: DesignSystem.microFontSize))
                        .foregroundStyle(.appSecondary)
                    }
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    
    private func iconForCategory(_ label: String) -> String {
        if label == L10n.Dashboard.System.database { return "cylinder.split.1x2.fill" }
        if label == L10n.Dashboard.System.logs { return "doc.text.below.ecg.fill" }
        if label == L10n.Dashboard.tr("stats.storageImport") { return "books.vertical.fill" }
        if label == L10n.Dashboard.tr("stats.storageExport") { return "square.and.arrow.up.fill" }
        return "folder.fill"
    }
    
    // MARK: - 溯源行组件
    struct ProvenanceRow: View {
        let title: String
        let icon: String
        let color: Color
        let count: Int
        let size: Int64
        
        var body: some View {
            HStack {
                ZStack {
                    Circle().fill(color.opacity(0.1)).frame(width: DesignSystem.Metrics.iconBoxSize - 8, height: DesignSystem.Metrics.iconBoxSize - 8)
                    Image(systemName: icon).font(.system(size: DesignSystem.subheadlineFontSize)).foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline).fontWeight(.medium)
                    Text("\(count) \(L10n.Dashboard.tr("index.pages"))").font(.caption).foregroundStyle(.appSecondary)
                }
                
                Spacer()
                
                Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.appSecondary)
            }
        }
    }
    
        
    // MARK: - 统一空状态视图
    private var emptyView: some View {
        VStack(spacing: DesignSystem.tiny) {
            Image(systemName: "chart.bar.xaxis")
                .font(.title)
                .foregroundColor(.appSecondary.opacity(0.3))
            Text(L10n.Common.Empty.tr("noData"))
                .font(.caption)
                .foregroundColor(.appSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.small)
    }
    
    // MARK: - 辅助方法
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
        
    // MARK: - 数据加载与清理
    
    private func loadStats() async {
        let startTime = Date()
        let store = ServiceContainer.shared.resolve(KnowledgePageStore.self)
        
        do {
            // 1. 性能类数据
            let daily = try store.fetchDailyAIStats()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YYYY-MM-dd"
            
            // 获取当前月份范围，响应用户“展示当月”的需求
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let components = calendar.dateComponents([.year, .month], from: today)
            let startDate = calendar.date(from: components)!
            
            // 计算从 1 号到今天共有多少天
            let numberOfDays = calendar.dateComponents([.day], from: startDate, to: today).day! + 1
            
            // 构建当月至今的底座数据
            var statsMap: [String: DailyAIUsage] = [:]
            for i in 0..<numberOfDays {
                let date = calendar.date(byAdding: .day, value: i, to: startDate)!
                let ds = dateFormatter.string(from: date)
                statsMap[ds] = DailyAIUsage(date: date, dateString: ds, tokens: 0, requests: 0)
            }
            
            // 填充实际数据
            for item in daily {
                if let date = dateFormatter.date(from: item.date), statsMap[item.date] != nil {
                    statsMap[item.date] = DailyAIUsage(
                        date: date,
                        dateString: item.date,
                        tokens: item.tokens,
                        requests: item.requests
                    )
                }
            }
            
            self.dailyStats = statsMap.values.sorted { $0.date < $1.date }
            let monthly = try store.fetchMonthlyTokenStats()
            self.monthlyStats = monthly.map { MonthlyToken(month: $0.month, total: $0.total) }
            self.avgLatency = try store.fetchAverageLatency()
            
            // 2. 存储数据 (逻辑更新：使用 SQLiteStore 的真实物理统计数据)
            let storageStats = sqliteStore.getStorageStats()
            
            // 计算导出大小
            let exportLogs = Logger.shared.logEntries.filter { $0.action == .export }
            
            // 组装分类
            let categories = [
                StorageCategory(
                    label: Localized.tr("storage.category.database"),
                    value: storageStats.databaseSize,
                    count: 1,
                    color: .blue
                ),
                StorageCategory(
                    label: Localized.tr("storage.category.logs"),
                    value: storageStats.logsSize,
                    count: Logger.shared.logEntries.count,
                    color: .orange
                ),
                StorageCategory(
                    label: Localized.tr("storage.category.imports"),
                    value: storageStats.importsSize,
                    count: sqliteStore.pages.filter { $0.sourceType != nil }.count,
                    color: .green
                ),
                StorageCategory(
                    label: Localized.tr("storage.category.exports"),
                    value: storageStats.exportsSize,
                    count: exportLogs.count,
                    color: .purple
                )
            ]
            
            self.storageCategories = categories
            self.totalStorage = categories.reduce(0) { $0 + $1.value }
            self.totalExportSize = storageStats.exportsSize
            self.exportSize = storageStats.exportsSize
            self.exportCount = exportLogs.count
            
            let prov = try store.fetchProvenanceStats()
            self.provenance = (prov.importedCount, prov.importedSize, prov.createdCount, prov.createdSize)
            self.totalPages = (try? store.count()) ?? (prov.importedCount + prov.createdCount)
            
            let endTime = Date()
            Logger.shared.addLog(
                action: .update,
                target: L10n.Dashboard.tr("stats.navigationTitleMonitor"),
                details: L10n.Dashboard.updateSuccess,
                duration: endTime.timeIntervalSince(startTime),
                startTime: startTime,
                endTime: endTime,
                module: "Dashboard"
            )
            
            self.isLoading = false
            
        } catch {
            print("Failed to load monitor stats: \(error)")
            ToastManager.shared.show(type: .error, message: L10n.Dashboard.updateFailed)
            await MainActor.run { self.isLoading = false }
        }
    }
    
    private func cleanupData() async {
        isCleaning = true
        let store = ServiceContainer.shared.resolve(KnowledgePageStore.self)
        
        do {
            let count = try store.cleanupOrphanedChunks()
            self.cleanedCount = count
            isCleaning = false
            HapticFeedback.shared.trigger(.success)
            await loadStats() // 刷新存储统计
        } catch {
            Logger.shared.error(L10n.Dashboard.cleanupFailed, error: error)
            isCleaning = false
        }
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
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: DesignSystem.displayFontSize))
                    .foregroundStyle(.appSecondary.opacity(0.3))
                Text(L10n.Common.Empty.tr("noData"))
                    .font(.caption2)
                    .foregroundStyle(.appSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Metrics.chartHeight - 60)
            .background(Color.appCard.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
        } else {
            Chart {
                ForEach(stats) { stat in
                    let value = type == .requests ? Double(stat.requests) : Double(stat.tokens)
                    
                    if type == .requests {
                        AreaMark(
                            x: .value(L10n.Dashboard.chartDate, stat.date, unit: .day),
                            y: .value(L10n.Dashboard.chartValue, value)
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
                            y: .value(L10n.Dashboard.chartValue, value)
                        )
                        .foregroundStyle(themeManager.accentColor)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                    } else {
                        BarMark(
                            x: .value(L10n.Dashboard.chartDate, stat.date, unit: .day),
                            y: .value(L10n.Dashboard.chartValue, value),
                            width: .fixed(DesignSystem.small)
                        )
                        .foregroundStyle(themeManager.accentColor.opacity(0.7).gradient)
                        .cornerRadius(1)
                    }
                }
                
                // 交互指示器
                if let selectedDate {
                    RuleMark(x: .value(L10n.Dashboard.chartSelected, selectedDate, unit: .day))
                        .foregroundStyle(Color.appSecondary.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [2]))
                        .annotation(position: .automatic, alignment: .center, spacing: 4) {
                            if let stat = stats.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
                                tooltipView(stat: stat)
                            }
                        }
                    
                    if type == .requests, let stat = stats.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
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
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisGridLine().foregroundStyle(.appBorder.opacity(0.3))
                    AxisValueLabel(anchor: .topTrailing) {
                        if let date = value.as(Date.self) {
                            Text(formatDate(date))
                                .font(.system(size: DesignSystem.microFontSize))
                                .foregroundStyle(.appSecondary)
                        }
                    }
                }
            }
            .chartYAxis {
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
            .chartXScale(domain: currentMonthRange().start...currentMonthRange().end.addingTimeInterval(86400)) // 增加一天偏移，防止月底标签截断
            .chartYScale(domain: 0...(max(100, maxValue() * 1.2)))
        }
    }
    
    private func currentMonthRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        let startOfMonth = calendar.date(from: components)!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        return (startOfMonth, endOfMonth)
    }
    
    private func tooltipView(stat: DailyAIUsage) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(stat.date, format: .dateTime.year().month().day())
                .font(.system(size: DesignSystem.captionFontSize, weight: .bold))
                .foregroundStyle(.appText)
            
            HStack(spacing: 4) {
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
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.appCard)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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
