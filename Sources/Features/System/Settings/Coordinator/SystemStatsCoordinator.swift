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
    
    // ── 内部类型定义与多笔记本存储状态 ──
    struct VaultStorageItem: Identifiable, Sendable {
        let id: UUID
        let name: String
        let icon: String
        let size: Int64
    }
    
    /// 各多笔记本 (Vault) 的精细化存储大小发布列表
    var vaultStorageItems: [VaultStorageItem] = []

    // ── 基础设施依赖 ──
    @ObservationIgnored @Inject private var pageStore: any AnyPageStoreCapabilities
    @ObservationIgnored @Inject private var knowledgeRepo: any KnowledgeRepository
    @ObservationIgnored @Inject private var vectorRepo: any VectorRepository
    @ObservationIgnored @Inject private var governanceRepo: any GovernanceRepository
    @ObservationIgnored @Inject private var logger: any LoggerProtocol
    @ObservationIgnored @Inject private var haptic: any HapticFeedbackProtocol

    init() {}

    // ── 业务动作 ──

    /// 加载系统统计数据
    func loadStats() async {
        let startTime = Date()
        
        // 1. AI 性能与资源消耗统计 (容错处理)
        if let daily = try? await governanceRepo.fetchDailyAIStats(days: 30) {
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
        
        if let monthly = try? await governanceRepo.fetchMonthlyTokenStats() {
            self.monthlyStats = monthly.map { MonthlyToken(month: $0.month, total: $0.total) }
        }
        
        _ = try? await governanceRepo.calculateAverageRAGScores(days: 30)
        
        // 2. 存储空间分布统计
        let stats = await pageStore.getStorageStats()
        let dbSize = stats.databaseSize
        let logsSize = stats.logsSize
        let exportsSize = stats.exportsSize
        
        let allLogEntries = await logger.getLogEntries()
        
        let categories = [
            StorageCategory(
                label: L10n.Dashboard.System.database,
                value: dbSize,
                count: VaultService.shared.vaults.count,
                color: .blue
            ),
            StorageCategory(
                label: L10n.Dashboard.System.logs,
                value: logsSize,
                count: allLogEntries.count,
                color: .orange
            ),
            StorageCategory(
                label: L10n.Dashboard.stats.storageImport,
                value: 0, // 页面内容暂不单独计算字节
                count: (try? await knowledgeRepo.count()) ?? 0,
                color: .green
            ),
            StorageCategory(
                label: L10n.Dashboard.stats.storageExport,
                value: exportsSize,
                count: allLogEntries.filter { $0.action == .export }.count,
                color: .purple
            )
        ]
        
        self.storageCategories = categories
        self.totalStorage = categories.reduce(0) { $0 + $1.value }
        self.exportSize = exportsSize
        self.exportCount = allLogEntries.filter { $0.action == .export }.count
        
        // 4. 级联提取各个笔记本 (Vault) 沙盒目录下的物理占用大小，并依据大小降序排列
        var items: [VaultStorageItem] = []
        let fileManager = FileManager.default
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let vaultsDir = appSupport.appendingPathComponent(AppConstants.Storage.vaultsDirectoryName)
            
            for vault in VaultService.shared.vaults {
                let vaultDir = vaultsDir.appendingPathComponent(vault.id.uuidString)
                var totalVaultSize: Int64 = 0
                if let enumerator = fileManager.enumerator(at: vaultDir, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) {
                    // 使用 nextObject() 代替 for-in 以避免 Swift 6 异步上下文下的迭代器不安全警告
                    while let fileURL = enumerator.nextObject() as? URL {
                        if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                           let fileSize = resourceValues.fileSize {
                            totalVaultSize += Int64(fileSize)
                        }
                    }
                }
                
                items.append(VaultStorageItem(
                    id: vault.id,
                    name: vault.name,
                    icon: vault.icon ?? "",
                    size: totalVaultSize
                ))
            }
        }
        self.vaultStorageItems = items.sorted { $0.size > $1.size }
        
        // 3. 页面统计
        self.totalPages = (try? await knowledgeRepo.count()) ?? 0
        
        let endTime = Date()
        logger.addLog(
            action: .update,
            target: L10n.Dashboard.stats.navigationTitleMonitor,
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
            let count = try await vectorRepo.cleanupOrphanedChunks()
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
        if label == L10n.Dashboard.stats.storageImport { return "books.vertical.fill" }
        if label == L10n.Dashboard.stats.storageExport { return "square.and.arrow.up.fill" }
        return "folder.fill"
    }
}
