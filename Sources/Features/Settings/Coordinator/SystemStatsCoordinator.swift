// SystemStatsCoordinator.swift
//
// 作者: Wang Chong
// 功能说明: 系统资源监控功能协调器，负责 AI 消耗分析、存储统计及数据库维护。
// 版本: 1.0
// 修改记录:
//   - 2026-05-15: 初始版本，从 SystemStatsView 剥离业务逻辑。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI
import Observation

@MainActor
@Observable
final class SystemStatsCoordinator {
    // ── 状态属性 ──
    var dailyStats: [DailyAIUsage] = []
    var monthlyStats: [MonthlyToken] = []
    var totalStorage: Int64 = 0
    var provenance: (importedCount: Int, importedSize: Int64, createdCount: Int, createdSize: Int64) = (0, 0, 0, 0)
    var exportCount: Int = 0
    var exportSize: Int64 = 0
    var avgLatency: Int = 0
    var maxLatency: Int = 0
    var minLatency: Int = 0
    var latencyCount: Int = 0
    var storageCategories: [StorageCategory] = []
    var totalPages: Int = 0
    var isLoading = true
    var isCleaning = false
    var cleanedCount: Int? = nil

    // ── 基础设施依赖 ──
    @ObservationIgnored @Inject private var sqliteStore: SQLiteStore
    @ObservationIgnored @Inject private var logger: any LoggerProtocol
    @ObservationIgnored @Inject private var haptic: any HapticFeedbackProtocol

    init() {}

    // ── 业务动作 ──

    /// 加载系统统计数据
    func loadStats() async {
        let startTime = Date()
        let pageStore = ServiceContainer.shared.resolve(KnowledgePageStore.self)
        
        // 1. AI 性能与资源消耗统计 (容错处理)
            if let daily = try? pageStore.fetchDailyAIStats() {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "YYYY-MM-dd"
                
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let components = calendar.dateComponents([.year, .month], from: today)
                let startDate = calendar.date(from: components)!
                let numberOfDays = calendar.dateComponents([.day], from: startDate, to: today).day! + 1
                
                var statsMap: [String: DailyAIUsage] = [:]
                for i in 0..<numberOfDays {
                    let date = calendar.date(byAdding: .day, value: i, to: startDate)!
                    let ds = dateFormatter.string(from: date)
                    statsMap[ds] = DailyAIUsage(date: date, dateString: ds, tokens: 0, requests: 0)
                }
                
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
            }
            
            if let monthly = try? pageStore.fetchMonthlyTokenStats() {
                self.monthlyStats = monthly.map { MonthlyToken(month: $0.month, total: $0.total) }
            }
            
            if let latencyStats = try? pageStore.fetchLatencyStats() {
                self.avgLatency = latencyStats.avg
                self.maxLatency = latencyStats.max
                self.minLatency = latencyStats.min
                self.latencyCount = latencyStats.count
            }
            
            // 2. 存储空间分布统计 (直接从数据库获取，不依赖内存缓存)
            let storageDetails = (try? pageStore.fetchStorageStats()) ?? (total: 0, byType: [:], dbSize: 0)
            let storageStats = sqliteStore.getStorageStats() // 获取物理文件大小
            let exportLogs = logger.logEntries.filter { $0.action == .export }
            
            let categories = [
                StorageCategory(
                    label: L10n.Dashboard.System.database,
                    value: storageStats.databaseSize,
                    count: 1,
                    color: .blue
                ),
                StorageCategory(
                    label: L10n.Dashboard.System.logs,
                    value: storageStats.logsSize,
                    count: logger.logEntries.count,
                    color: .orange
                ),
                StorageCategory(
                    label: L10n.Dashboard.tr("stats.storageImport"),
                    value: storageDetails.total,
                    count: (try? pageStore.count()) ?? 0,
                    color: .green
                ),
                StorageCategory(
                    label: L10n.Dashboard.tr("stats.storageExport"),
                    value: storageStats.exportsSize,
                    count: exportLogs.count,
                    color: .purple
                )
            ]
            
            self.storageCategories = categories
            self.totalStorage = categories.reduce(0) { $0 + $1.value }
            self.exportSize = storageStats.exportsSize
            self.exportCount = exportLogs.count
            
            // 3. 溯源数据统计
            if let prov = try? pageStore.fetchProvenanceStats() {
                self.provenance = (prov.importedCount, prov.importedSize, prov.createdCount, prov.createdSize)
                self.totalPages = (try? pageStore.count()) ?? (prov.importedCount + prov.createdCount)
            }
            
            let endTime = Date()
            logger.addLog(
                action: .update,
                target: L10n.Dashboard.tr("stats.navigationTitleMonitor"),
                details: L10n.Dashboard.updateSuccess,
                duration: endTime.timeIntervalSince(startTime),
                startTime: startTime,
                endTime: endTime,
                module: "Dashboard"
            )
        
        self.isLoading = false
    }

    /// 执行数据库深度清理
    func cleanupData() async {
        isCleaning = true
        let pageStore = ServiceContainer.shared.resolve(KnowledgePageStore.self)
        
        do {
            let count = try pageStore.cleanupOrphanedChunks()
            self.cleanedCount = count
            haptic.trigger(.success)
            await loadStats() // 刷新存储统计
        } catch {
            logger.error("❌ [SystemStats] 数据清理失败", error: error)
        }
        isCleaning = false
    }

    /// 字节格式化助手
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    /// 标签图标选择器
    func iconForCategory(_ label: String) -> String {
        if label == L10n.Dashboard.System.database { return "cylinder.split.1x2.fill" }
        if label == L10n.Dashboard.System.logs { return "doc.text.below.ecg.fill" }
        if label == L10n.Dashboard.tr("stats.storageImport") { return "books.vertical.fill" }
        if label == L10n.Dashboard.tr("stats.storageExport") { return "square.and.arrow.up.fill" }
        return "folder.fill"
    }
}
