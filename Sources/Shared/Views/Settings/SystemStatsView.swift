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
struct DailyToken: Identifiable {
    let id = UUID()
    let dateString: String
    let total: Int
}

struct MonthlyToken: Identifiable {
    let id = UUID()
    let month: String
    let total: Int
}

struct StorageItem: Identifiable {
    let id = UUID()
    let type: String
    let size: Int64
}

// MARK: - 资源监控视图
/// [L3] 表现层：资源监控视图 (原资源监控)
/// 提供 AI 资源消耗、存储空间分布及数据溯源的多维度监控。
struct SystemStatsView: View {
    @Environment(\.dismiss) private var dismiss
    
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
    @State private var dailyStats: [DailyToken] = []
    @State private var monthlyStats: [MonthlyToken] = []
    @State private var totalStorage: Int64 = 0
    @State private var storageByType: [StorageItem] = []
    @State private var provenance: (importedCount: Int, importedSize: Int64, createdCount: Int, createdSize: Int64) = (0, 0, 0, 0)
    @State private var exportCount: Int = 0
    @State private var totalExportSize: Int64 = 0
    @State private var avgLatency: Int = 0
    @State private var evalStats: [String: Double] = [:]
    @State private var isLoading = true
    @State private var isCleaning = false
    @State private var cleanedCount: Int? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // 分段选择器：降低页面拥挤感，实现功能解耦
            Picker("", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppUI.standardPadding)
            .padding(.vertical, AppUI.tightPadding)
            .background(Color.appBackground)
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    switch selectedTab {
                    case .performance:
                        performanceSection
                    case .storage:
                        storageSection
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(L10n.Dashboard.tr("stats.navigationTitleMonitor"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadStats()
        }
    }
    
    // MARK: - 性能与 AI 资源分区
    @ViewBuilder
    private var performanceSection: some View {
        Section(header: Text(L10n.Dashboard.tr("stats.aiResources"))) {
            VStack(alignment: .leading, spacing: AppUI.small) {
                Text("\(L10n.Dashboard.tr("stats.tokenTrend")) (\(AppConstants.Storage.observabilityWindowDays)\(L10n.Common.tr("unit.day")))")
                    .font(.subheadline)
                    .foregroundColor(.appSecondary)
                
                if dailyStats.isEmpty {
                    emptyView
                } else {
                    Chart {
                        ForEach(dailyStats) { stat in
                            BarMark(
                                x: .value(L10n.Common.tr("date"), stat.dateString),
                                y: .value("Tokens", stat.total)
                            )
                            .foregroundStyle(Color.appAccent.gradient)
                        }
                    }
                    .frame(height: AppUI.Metrics.chartHeight)
                    .padding(.vertical, AppUI.small)
                }
            }
            .padding(.vertical, AppUI.tiny)
            
            HStack(spacing: AppUI.standardPadding) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill((avgLatency > AppConstants.Performance.latencyWarningThreshold ? Color.orange : Color.appAccent).opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: "timer")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(avgLatency > AppConstants.Performance.latencyWarningThreshold ? Color.orange : .appAccent)
                        }
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.Dashboard.tr("stats.avgLatency"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.appSecondary)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(avgLatency)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.appText)
                            Text("ms")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.appSecondary)
                        }
                    }
                }
                .padding(AppUI.standardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    ZStack {
                        Color.appCard
                        LinearGradient(
                            colors: [(avgLatency > AppConstants.Performance.latencyWarningThreshold ? Color.orange : Color.appAccent).opacity(0.08), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: AppUI.Metrics.dashboardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppUI.Metrics.dashboardRadius)
                        .stroke(
                            LinearGradient(
                                colors: [.appBorder.opacity(0.8), .appBorder.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 5)
            }
            .padding(.vertical, AppUI.tiny)
        }
        
        Section(header: Text(L10n.Dashboard.tr("stats.benchmark"))) {
            qualityGrid
        }
    }
    
    // MARK: - 存储与治理分区
    @ViewBuilder
    private var storageSection: some View {
        Section(header: Text(L10n.Dashboard.tr("stats.storageDistribution"))) {
            HStack {
                Text(L10n.Dashboard.tr("stats.totalStorage"))
                Spacer()
                Text(formatBytes(totalStorage))
                    .fontWeight(.bold)
            }
            
            if storageByType.isEmpty {
                emptyView
            } else {
                ForEach(storageByType) { item in
                    HStack {
                        Circle()
                            .fill(colorForType(item.type))
                            .frame(width: AppUI.microIconSize, height: AppUI.microIconSize)
                        Text(displayName(for: item.type))
                        Spacer()
                        Text(formatBytes(item.size))
                            .foregroundColor(.appSecondary)
                    }
                }
            }
        }
        
        // 导入与导出统计：量化导入与自建资产
        Section(header: Text(L10n.Dashboard.tr("stats.provenance"))) {
            HStack {
                Label(L10n.Dashboard.tr("stats.imported"), systemImage: "arrow.down.doc")
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(provenance.importedCount) \(L10n.Dashboard.tr("index.pages"))")
                    Text(formatBytes(provenance.importedSize))
                        .font(.caption)
                        .foregroundColor(.appSecondary)
                }
            }
            HStack {
                Label(L10n.Dashboard.tr("stats.manuallyCreated"), systemImage: "pencil.and.outline")
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(provenance.createdCount) \(L10n.Dashboard.tr("index.pages"))")
                    Text(formatBytes(provenance.createdSize))
                        .font(.caption)
                        .foregroundColor(.appSecondary)
                }
            }
            HStack {
                Label(L10n.Dashboard.tr("stats.exportedRecent"), systemImage: "arrow.up.doc")
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(exportCount) \(L10n.Dashboard.tr("pages"))")
                    Text(formatBytes(totalExportSize))
                        .font(.caption)
                        .foregroundColor(.appSecondary)
                }
            }
        }
        
        Section(header: Text(L10n.Dashboard.tr("stats.maintenance"))) {
            Button(action: {
                Task { await cleanupData() }
            }) {
                HStack {
                    Text(L10n.Dashboard.tr("stats.cleanupAction"))
                    Spacer()
                    if isCleaning {
                        ProgressView()
                    } else {
                        Image(systemName: "sparkles")
                    }
                }
            }
            .disabled(isCleaning)
            
            if let count = cleanedCount {
                Text("\(L10n.Dashboard.tr("stats.cleanedPrefix")) \(count) \(L10n.Dashboard.tr("stats.cleanedSuffix"))")
                    .font(.caption)
                    .foregroundColor(Color.green)
            }
            
        }
    }
    
    private var qualityGrid: some View {
        HStack(spacing: AppUI.standardPadding) {
            metricCard(title: L10n.Dashboard.tr("stats.faithfulness"), value: evalStats[EvaluationMetric.faithfulness.rawValue] ?? 0, icon: "checkmark.shield", color: .appAccent)
            metricCard(title: L10n.Dashboard.tr("stats.relevance"), value: evalStats[EvaluationMetric.relevance.rawValue] ?? 0, icon: "target", color: .appAccent)
            metricCard(title: L10n.Dashboard.tr("stats.precision"), value: evalStats[EvaluationMetric.precision.rawValue] ?? 0, icon: "scope", color: .appAccent)
        }
        .padding(.vertical, AppUI.small)
    }

    private func metricCard(title: String, value: Double, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(color)
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.appSecondary)
                    .lineLimit(1)
                
                Text(String(format: "%.2f", value))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.appText)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                Color.appCard
                LinearGradient(
                    colors: [color.opacity(0.08), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: AppUI.Metrics.dashboardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppUI.Metrics.dashboardRadius)
                .stroke(
                    LinearGradient(
                        colors: [.appBorder.opacity(0.8), .appBorder.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - 统一空状态视图
    private var emptyView: some View {
        VStack(spacing: AppUI.tiny) {
            Image(systemName: "chart.bar.xaxis")
                .font(.title)
                .foregroundColor(.appSecondary.opacity(0.3))
            Text(L10n.Common.Empty.tr("noData"))
                .font(.caption)
                .foregroundColor(.appSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppUI.small)
    }
    
    // MARK: - 辅助方法
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func displayName(for type: String) -> String {
        if type == "system.database" {
            return L10n.Dashboard.tr("stats.system.database")
        } else if type == "system.logs" {
            return L10n.Dashboard.tr("stats.system.logs")
        } else if let pageType = PageType(rawValue: type) {
            return pageType.displayName
        }
        return type
    }
    
    private func colorForType(_ type: String) -> Color {
        if type == "system.database" {
            return .indigo
        } else if type == "system.logs" {
            return .secondary
        } else if let pageType = PageType(rawValue: type) {
            return .fromModelColorName(pageType.colorName)
        }
        return .gray
    }
    
    // MARK: - 数据加载与清理
    
    private func loadStats() async {
        let startTime = Date()
        let store = ServiceContainer.shared.resolve(KnowledgePageStore.self)
        
        do {
            // 1. 性能类数据
            let daily = try store.fetchDailyTokenStats()
            self.dailyStats = daily.map { DailyToken(dateString: $0.date, total: $0.total) }
            let monthly = try store.fetchMonthlyTokenStats()
            self.monthlyStats = monthly.map { MonthlyToken(month: $0.month, total: $0.total) }
            self.avgLatency = try store.fetchAverageLatency()
            self.evalStats = try store.fetchEvaluationStats()
            
            // 2. 存储与溯源类数据
            let storage = try store.fetchStorageStats()
            
            // 获取日志文件大小
            let logSize = (try? FileManager.default.attributesOfItem(atPath: (Logger.shared as Logger).logsFileURL.path)[.size] as? Int64) ?? 0
            
            // 构建存储列表，加入数据库和日志
            var items: [StorageItem] = storage.byType.map { StorageItem(type: $0.key, size: $0.value) }
            items.append(StorageItem(type: "system.database", size: storage.dbSize))
            items.append(StorageItem(type: "system.logs", size: logSize))
            
            self.totalStorage = storage.total + storage.dbSize + logSize
            self.storageByType = items.sorted { $0.size > $1.size }
            
            let prov = try store.fetchProvenanceStats()
            self.provenance = (prov.importedCount, prov.importedSize, prov.createdCount, prov.createdSize)
            
            // 计算最近导出次数与大小 (从 Logger 获取)
            let exportLogs = Logger.shared.logEntries.filter { $0.action == .export }
            self.exportCount = exportLogs.count
            
            // 解析日志中的 size:XXXX 字段
            var totalSize: Int64 = 0
            let regex = try? NSRegularExpression(pattern: "size:(\\d+)")
            for log in exportLogs {
                if let match = regex?.firstMatch(in: log.details, range: NSRange(log.details.startIndex..., in: log.details)),
                   let range = Range(match.range(at: 1), in: log.details),
                   let size = Int64(log.details[range]) {
                    totalSize += size
                }
            }
            self.totalExportSize = totalSize
            
            let endTime = Date()
            Logger.shared.addLog(
                action: .update,
                target: L10n.Dashboard.tr("stats.navigationTitleMonitor"),
                details: "系统监控数据更新成功",
                duration: endTime.timeIntervalSince(startTime),
                startTime: startTime,
                endTime: endTime,
                module: "Dashboard"
            )
            isLoading = false
        } catch {
            Logger.shared.error("加载监控数据失败", error: error)
            isLoading = false
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
            Logger.shared.error("清理孤立数据失败", error: error)
            isCleaning = false
        }
    }
}
