//
//  MaintenanceService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：实现 Maintenance 模块的核心业务逻辑服务。
//
import Foundation
import Observation
import GRDB

/// 系统维护服务 (L1-Infra)
/// 负责处理非核心业务的系统级管理任务。
@MainActor
public final class MaintenanceService {
    
    @ObservationIgnored @Inject private var pageStore: any AnyPageStoreCapabilities
    @ObservationIgnored @Inject private var vaultService: any VaultServiceProtocol
    @ObservationIgnored @Inject private var backupService: BackupService
    @ObservationIgnored @Inject private var logger: any LoggerProtocol
    @ObservationIgnored @Inject private var undoService: UndoService

    public init() {}
    
    // MARK: - 演示数据与种子

    /// 生成演示数据
    @discardableResult

    /// 生成DemoData
    /// - Returns: 数值
    public func generateDemoData() async -> Int {
        let vaults = vaultService.vaults
        guard !vaults.isEmpty else {
            // 没有笔记本时仅注入当前活跃数据库
            do {
                return try await DemoDataGenerator.generate(in: pageStore)
            } catch {
                logger.addLog(action: .error, target: "Demo", details: "Maintenance_Failed1", module: "Maintenance")
                return 0
            }
        }
        var totalCount = 0
        for vault in vaults {
            vaultService.selectVault(vault)
            // 等待数据库切换完成
            try? await Task.sleep(nanoseconds: 300_000_000)
            do {
                let count = try await DemoDataGenerator.generate(in: pageStore)
                totalCount += count
            } catch {
                logger.addLog(action: .error, target: vault.name, details: "DemoData_Failed", module: "Maintenance")
            }
        }
        return totalCount
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
