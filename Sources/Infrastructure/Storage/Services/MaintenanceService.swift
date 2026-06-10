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
        Logger.shared.warning(">>> [MaintenanceService] generateDemoData START")
        // 确保两个默认演示笔记本存在，不存在则创建
        let demoVaultConfigs: [(name: String, icon: String, description: String)] = [
            (L10n.Vault.defaultName, IconTokens.defaultBook, L10n.Vault.defaultDescription),
            (L10n.Vault.researchName, IconTokens.defaultResearch, L10n.Vault.researchDescription)
        ]

        var existingVaults = vaultService.vaults
        for config in demoVaultConfigs {
            if !existingVaults.contains(where: { $0.name == config.name }) {
                vaultService.createVault(name: config.name, icon: config.icon, description: config.description)
                logger.addLog(action: .create, target: config.name, details: "DemoData_VaultCreated", module: "Maintenance")
            }
        }

        // 重新获取（可能新增了笔记本）
        existingVaults = vaultService.vaults
        guard !existingVaults.isEmpty else {
            do {
                return try await DemoDataGenerator.generate(in: pageStore)
            } catch {
                logger.addLog(action: .error, target: "Demo", details: "Maintenance_Failed1", module: "Maintenance")
                return 0
            }
        }

        var totalCount = 0
        for vault in existingVaults {
            do {
                // 使用同步等待版本确保数据库切换完成后才写入
                try await vaultService.selectVaultAndWait(vault)
                logger.addLog(action: .create, target: vault.name, details: "DemoData_DB_Switched", module: "Maintenance")
                let count = try await DemoDataGenerator.generate(in: pageStore)
                totalCount += count
                logger.addLog(action: .create, target: vault.name, details: "DemoData_Injected_\(count)", module: "Maintenance")
                // 数据注入后刷新页数到元数据
                await vaultService.refreshPageCount(for: vault.id)
                logger.addLog(action: .create, target: vault.name, details: "DemoData_PageCountRefreshed", module: "Maintenance")
                logger.addLog(action: .create, target: vault.name, details: "DemoData_Injected_\(count)", module: "Maintenance")
            } catch {
                logger.addLog(action: .error, target: vault.name, details: "DemoData_Failed: \(error.localizedDescription)", module: "Maintenance")
            }
        }
        Logger.shared.warning(">>> [MaintenanceService] generateDemoData END, totalCount=\(totalCount)")
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
        Logger.shared.warning("[MaintenanceService] clearAllDeveloperData called — RESETTING DATABASE")
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
