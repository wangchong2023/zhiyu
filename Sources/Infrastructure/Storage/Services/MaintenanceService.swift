// MaintenanceService.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：系统维护服务，负责演示数据注入、数据重置、物理备份调度及日志清理。
// 版本: 1.0
// 修改记录:
//   - 2026-05-18: 从 AppStore 剥离维护逻辑，实现职责单一化。
// 版权: © 2026 Wang Chong。保留所有权利。

import Foundation
import Observation
import GRDB

/// 系统维护服务 (L1-Infra)
/// 负责处理非核心业务的系统级管理任务。
@MainActor
public final class MaintenanceService {
    
    @ObservationIgnored @Inject private var pageStore: any AnyPageStoreCapabilities
    @ObservationIgnored @Inject private var backupService: BackupService
    @ObservationIgnored @Inject private var logger: any LoggerProtocol
    @ObservationIgnored @Inject private var undoService: UndoService

    public init() {}
    
    // MARK: - 演示数据与种子

    /// 生成演示数据
    @discardableResult
    public func generateDemoData() async -> Int {
        do {
            let count = try await DemoDataGenerator.generate(in: pageStore)
            return count
        } catch {
            logger.addLog(action: .error, target: "Demo", details: "Failed to generate demo data: \(error.localizedDescription)", module: "Maintenance")
            return 0
        }
    }

    /// 填充默认引导内容
    public func seedDefaultContent(pages: [KnowledgePage]) async {
        if pages.isEmpty {
            await pageStore.seedDefaultContent { [weak self] a, t, d in
                Task { @MainActor [weak self] in
                    self?.logger.addLog(action: a, target: t, details: d, module: "Maintenance")
                }
            }
        }
    }

    // MARK: - 系统重置

    /// 清除所有开发者数据 (重置系统)
    public func clearAllDeveloperData() async {
        undoService.clear()
        try? await pageStore.resetDatabase()
        AppEventBus.shared.publish(.pagesCleared)
    }

    // MARK: - 磁盘与日志

    /// 保存关键状态至磁盘并触发备份
    public func saveToDisk(pages: [KnowledgePage]) async {
        await logger.saveToDisk()
        backupService.createBackup(pages: pages)
    }

    /// 从磁盘重新加载数据
    public func loadFromDisk() async {
        await pageStore.reloadFromDisk()
        await logger.loadFromDisk()
    }

    /// 清理所有日志
    public func clearLogs() async {
        await logger.clearAllLogs()
    }
}
