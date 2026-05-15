// SystemStatsCoordinator.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：系统资源监控功能协调器，负责 AI 消耗分析、存储统计及数据库维护。
// 版本: 1.1
// 修改记录:
//   - 2026-05-15: 适配垂直化仓储架构，迁移统计与清理逻辑至 Governance/Vector 仓库。
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
    @ObservationIgnored @Inject private var knowledgeStore: KnowledgePageRepository
    @ObservationIgnored @Inject private var vectorStore: VectorDataRepository
    @ObservationIgnored @Inject private var governanceStore: AIGovernanceRepository
    @ObservationIgnored @Inject private var logger: any LoggerProtocol
    @ObservationIgnored @Inject private var haptic: any HapticFeedbackProtocol

    init() {}

    // ── 业务动作 ──

    /// 加载系统统计数据
    func loadStats() async {
        let startTime = Date()
        
        // 1. AI 性能与资源消耗统计 (容错处理)
        if let daily = try? await governanceStore.fetchDailyAIStats(days: 30) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let components = calendar.dateComponents([.year, .month], from: today)
            let startDate = calendar.date(from: components)!
            let numberOfDays = calendar.dateComponents([.day], from: startDate, to: today).day! + 1
            
            var statsMap: [String: DailyAIUsage] = [:]
            for i in 0..<numberOfDays {
                if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                    let ds = dateFormatter.string(from: date)
                    statsMap[ds] = DailyAIUsage(date: date, dateString: ds, tokens: 0, requests: 0)
                }
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
        
        if let monthly = try? await governanceStore.fetchMonthlyTokenStats() {
            self.monthlyStats = monthly.map { MonthlyToken(month: $0.month, total: $0.total) }
        }
        
        _ = try? await governanceStore.fetchAverageMetrics()
        
        // 2. 存储空间分布统计
        let dbSize = sqliteStore.getStorageStats().databaseSize
        let logsSize = sqliteStore.getStorageStats().logsSize
        let exportsSize = sqliteStore.getStorageStats().exportsSize
        
        let categories = [
            StorageCategory(
                label: L10n.Dashboard.System.database,
                value: dbSize,
                count: 1,
                color: .blue
            ),
            StorageCategory(
                label: L10n.Dashboard.System.logs,
                value: logsSize,
                count: logger.logEntries.count,
                color: .orange
            ),
            StorageCategory(
                label: L10n.Dashboard.tr("stats.storageImport"),
                value: 0, // 页面内容暂不单独计算字节
                count: (try? await knowledgeStore.count()) ?? 0,
                color: .green
            ),
            StorageCategory(
                label: L10n.Dashboard.tr("stats.storageExport"),
                value: exportsSize,
                count: logger.logEntries.filter { $0.action == .export }.count,
                color: .purple
            )
        ]
        
        self.storageCategories = categories
        self.totalStorage = categories.reduce(0) { $0 + $1.value }
        self.exportSize = exportsSize
        self.exportCount = logger.logEntries.filter { $0.action == .export }.count
        
        // 3. 页面统计
        self.totalPages = (try? await knowledgeStore.count()) ?? 0
        
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
        do {
            let count = try await vectorStore.cleanupOrphanedChunks()
            self.cleanedCount = count
            haptic.trigger(.success)
            await loadStats() // 刷新统计
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
