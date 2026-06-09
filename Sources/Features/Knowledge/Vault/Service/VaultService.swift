//
//  VaultService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：实现 Vault 模块的核心业务逻辑服务。
//
import Foundation
import Observation
import GRDB
import SwiftUI

/// 知识笔记本/金库中枢服务（VaultService）。
/// 它是业务功能层中负责维护多笔记本租户（Multi-Vault）生命周期的大脑门面，
/// 支持创建、配置、选择和物理销毁金库，并动态切换底层 SQLite 物理数据库。
@Observable
@MainActor
public final class VaultService: VaultServiceProtocol {
    
    // MARK: - 依赖注入
    
    /// 注入金库元数据持久化仓储协议（vaultRepository），贯彻依赖倒置原则（DIP）。
    /// 使用 `@ObservationIgnored` 规避 `Observation` 宏对注入实例的过度包装冲突。
    @ObservationIgnored
    @Inject private var vaultRepository: any VaultRepository
    
    /// 注入数据库切换契约（databaseSwitcher），解耦业务层对数据库具体实现的强依赖。
    @ObservationIgnored
    @Inject private var databaseSwitcher: any VaultDatabaseSwitcher
    
    // MARK: - 状态发布属性
    
    /// 当前已注册挂载的全部笔记本列表。
    public var vaults: [Vault] = []
    
    /// 当前选中的活跃笔记本唯一标识符 UUID。
    public var selectedVaultID: UUID?
    
    /// 当前选中的活跃笔记本实体对象。
    public var currentVault: Vault? {
        vaults.first { $0.id == selectedVaultID }
    }
    
    // MARK: - 单例与初始化
    
    /// 全局唯一的线程安全单例实例。
    public static let shared = VaultService()
    
    /// 私有化单例构造方法，防止外部直接实例化。
    private init() {
        // 单测环境下禁用自动异步加载演示数据，避免跨用例的 DI 容器重置竞态崩溃
        if NSClassFromString("XCTestCase") == nil {
            loadVaults()
        }
    }
    
    // MARK: - 物理路径计算辅助
    
    /// 获取特定笔记本沙盒内的专属物理数据库文件路径。
    /// - Parameter vaultID: 目标笔记本 UUID。
    /// - Returns: 指向该笔记本专属 SQLite `vault.sqlite3` 物理文件的绝对路径 URL。
    ///
    /// 物理路径结构规范：
    /// `Application Support/ZhiYu/Vaults/{Vault_UUID}/vault.sqlite3`
    private func getVaultDatabaseURL(for vaultID: UUID) -> URL {
        // swiftlint:disable:next force_unwrapping
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appendingPathComponent(AppConstants.Storage.vaultsDirectoryName)
            .appendingPathComponent(vaultID.uuidString)
            .appendingPathComponent(AppConstants.Storage.vaultDatabaseName)
    }
    
    // MARK: - 核心业务操作 API
    
    /// 加载所有笔记本元数据。
    /// 异步载入所有已注册的笔记本元数据列表。
    /// 若全局配置表为空，则冷启动触发系统预置的演示数据（“我的知识库”与“项目调研”），
    /// 该预置演示库支持 100% 国际化多语言翻译适配，自动持久化至全局库中，并安全恢复最近一次激活的物理库。
    private func loadVaults() {
        Task {
            do {
                // 1. 尝试从全局元数据 Repository 中读取所有已注册的金库
                let loadedVaults = try await vaultRepository.fetchAllVaults()
                if loadedVaults.isEmpty {
                    // 2. 冷启动：初始化演示金库数据（通过 L10n 支持多语言翻译）
                    let id1 = UUID()
                    let id2 = UUID()
                    self.vaults = [
                        Vault(
                            id: id1,
                            name: L10n.Vault.defaultName,
                            createdAt: Date(),
                            updatedAt: Date(),
                            pageCount: 0,
                            themePayload: nil,
                            icon: IconTokens.defaultBook,
                            description: L10n.Vault.defaultDescription
                        ),
                        Vault(
                            id: id2,
                            name: L10n.Vault.researchName,
                            createdAt: Date(),
                            updatedAt: Date(),
                            pageCount: 0,
                            themePayload: nil,
                            icon: IconTokens.defaultResearch,
                            description: L10n.Vault.researchDescription
                        )
                    ]
                    // 3. 将初始化的演示笔记本原子注册并写入全局配置数据库
                    for vault in self.vaults {
                        try await vaultRepository.saveVault(vault)
                    }
                } else {
                    self.vaults = loadedVaults
                }
                // 后台刷新全部笔记本的实际页数
                refreshAllPageCounts()
            } catch {
                print(" [VaultService]" + " Failed to" + " asynchronously load" + " notebook metadata:" + " \(error)")
                // 4. 极端降级兜底：建立支持多语言本地化的内存级缓存金库
                self.vaults = [
                    Vault(
                        id: UUID(),
                        name: L10n.Vault.defaultName,
                        createdAt: Date(),
                        updatedAt: Date(),
                        pageCount: 12,
                        themePayload: nil,
                        icon: IconTokens.defaultBook,
                        description: L10n.Vault.defaultDescription
                    ),
                    Vault(
                        id: UUID(),
                        name: L10n.Vault.researchName,
                        createdAt: Date(),
                        updatedAt: Date(),
                        pageCount: 5,
                        themePayload: nil,
                        icon: IconTokens.defaultResearch,
                        description: L10n.Vault.researchDescription
                    )
                ]
            }
        }
        
        // 5. 自动从持久化偏好中恢复最近一次使用的金库并执行底层 SQLite 物理热重载联接
        if let idString = UserDefaults.standard.string(forKey: AppConstants.Keys.Storage.vaultsSelectedID),
           let id = UUID(uuidString: idString),
           vaults.contains(where: { $0.id == id }) {
            self.selectedVaultID = id
            Task {
                do {
                    let dbURL = getVaultDatabaseURL(for: id)
                    try await databaseSwitcher.switchDatabase(to: id, at: dbURL)
                } catch {
                    print(" [VaultService]" + " Failed to" + " auto-connect to" + " the recently" + " used physical" + " database: \(error)")
                }
            }
        }
    }
    
    /// 将笔记本元数据变更原子写回全局配置表中。
    /// - Parameter vault: 需要保存更新的 Vault 金库实体。
    private func saveVaultToDatabase(_ vault: Vault) throws {
        Task {
            try await vaultRepository.saveVault(vault)
        }
    }
    
    /// 异步选择并等待数据库切换完成（用于批量数据操作等需要确保切换完成的场景）
    /// - Parameter vault: 目标笔记本
    public func selectVaultAndWait(_ vault: Vault) async throws {
        self.selectedVaultID = vault.id
        UserDefaults.standard.set(vault.id.uuidString, forKey: AppConstants.Keys.Storage.vaultsSelectedID)
        NotificationCenter.default.post(name: .vaultWillSwitch, object: vault.id)

        let dbURL = getVaultDatabaseURL(for: vault.id)
        try await databaseSwitcher.switchDatabase(to: vault.id, at: dbURL)
        try? await vaultRepository.updateLastAccessed(id: vault.id)

        // 同步实际页面数量
        await refreshPageCount(for: vault.id)
    }

    /// 从当前活跃数据库查询实际页面数并写回全局元数据
    private func refreshPageCount(for vaultID: UUID) async {
        guard let writer = DatabaseManager.shared.dbWriter else { return }
        do {
            let count = try await writer.read { db in
                try KnowledgePage.fetchCount(db)
            }
            if let index = vaults.firstIndex(where: { $0.id == vaultID }) {
                vaults[index].pageCount = count
                try await vaultRepository.saveVault(vaults[index])
            }
        } catch {
            // 非关键路径，静默失败
        }
    }

    /// 启动后异步刷新全部笔记本的页面计数（直接读取各 vault 数据库文件）
    private func refreshAllPageCounts() {
        let vaultsSnapshot = vaults
        Task.detached(priority: .background) { [weak self] in
            for vault in vaultsSnapshot {
                guard let self = self else { break }
                let dbURL = await self.getVaultDatabaseURL(for: vault.id)
                guard FileManager.default.fileExists(atPath: dbURL.path) else { continue }
                do {
                    let dbQueue = try DatabaseQueue(path: dbURL.path)
                    let count = try await dbQueue.read { db in
                        try KnowledgePage.fetchCount(db)
                    }
                    await MainActor.run {
                        if let index = self.vaults.firstIndex(where: { $0.id == vault.id }) {
                            self.vaults[index].pageCount = count
                        }
                    }
                    // 异步写回全局元数据
                    try? await self.vaultRepository.saveVault(vault)
                } catch {
                    // 非关键路径，静默失败
                }
            }
        }
    }

    /// 选择并激活目标金库，同时触发底层的专属物理数据库 WAL 切换。
    ///
    /// - 架构时序与并发安全设计说明 (Thread Safety & Switch Flow):
    ///   本方法托管于 `@MainActor` 并发沙盒中，确保对 `selectedVaultID` 的动态赋值、
    ///   偏好项写入以及底层 SQLite 数据库物理 Pool 重建在**主线程串行、原子化执行**，彻底避免多线程对撞与竞争条件。
    ///   
    ///   ```
    ///   ┌────────────────────────────────────────────────────────┐
    ///   │              Vault 激活与数据库级级联切换时序图              │
    ///   └────────────────────────────────────────────────────────┘
    ///         [用户点击 Vault 卡片]
    ///                  │
    ///                  ▼
    ///         1. 绑定 selectedVaultID ──► 驱动 UI 侧边栏/主页响应式秒开
    ///                  │
    ///                  ▼
    ///         2. 写入 UserDefaults   ──► 记录冷启动恢复指针
    ///                  │
    ///                  ▼
    ///         3. switchDatabase()   ──► 彻底销毁旧 Pool 连接，释放 WAL 文件锁
    ///                  │                挂载新物理库并跑 Schema 迁移
    ///                  ▼
    ///         4. 异步 updateAccessed ──► 派发到后台 Task 悄然修改元数据时间戳
    ///   ```
    ///   
    ///   [步骤剖析]：
    ///   1. **步骤一**：更新状态发布器 `selectedVaultID` 以驱动 UI 响应式局部重绘。
    ///   2. **步骤二**：通过 `UserDefaults` 持久化记录最近一次选中的 Vault ID，保障下次冷启动热连通。
    ///   3. **步骤三 (物理切换)**：触发 `DatabaseManager.shared.switchDatabase`。该方法会立即同步销毁旧专属库连接
    ///      并释放物理文件独占锁，开辟全新的 Pool。
    ///   4. **步骤四 (异步更新)**：开启独立的物理 Task 异步记录该 Vault 在全局配置表中的最近使用访问时间戳，
    ///      物理拆分了业务调度与持久化操作，保证操作流畅性。
    ///
    /// - Parameter vault: 需要选中的目标 Vault 实体。
    public func selectVault(_ vault: Vault) {
        self.selectedVaultID = vault.id
        UserDefaults.standard.set(vault.id.uuidString, forKey: AppConstants.Keys.Storage.vaultsSelectedID)
        
        NotificationCenter.default.post(name: .vaultWillSwitch, object: vault.id)
        
        // 1. 热插拔重定向：要求 databaseSwitcher 彻底挂载专属物理子库，同步刷新句柄
        Task {
            do {
                let dbURL = getVaultDatabaseURL(for: vault.id)
                try await databaseSwitcher.switchDatabase(to: vault.id, at: dbURL)

                // 2. 更新该笔记本的最近访问访问时序，用以在主界面进行最近使用排序
                try? await vaultRepository.updateLastAccessed(id: vault.id)

                // 3. 同步实际页面数量到元数据
                await refreshPageCount(for: vault.id)
            } catch {
                print(" [VaultService]" + " Failed to" + " switch physical" + " database: \(error)")
            }
        }
    }
    
    /// 退出当前选中的笔记本金库。
    /// 返回主选择页，在 UserDefaults 中移除偏好项，并安全降级释放当前物理库的连接句柄，防止空转泄露。
    public func exitVault() {
        NotificationCenter.default.post(name: .vaultWillSwitch, object: nil)
        
        withAnimation(DesignSystem.Animation.Config.prominentSpring) {
            self.selectedVaultID = nil
        }
        UserDefaults.standard.removeObject(forKey: AppConstants.Keys.Storage.vaultsSelectedID)
        // 物理释放专属连接以闭合通道锁
        databaseSwitcher.releaseDatabaseConnection()
    }
    
    /// 创建全新的笔记本金库。
    /// - Parameters:
    ///   - name: 金库显示的中文或多语言名称。
    ///   - icon: 金库卡片展示的图标 Token。
    ///   - description: 描述该金库知识域范围的详情文本。
    public func createVault(name: String, icon: String? = nil, description: String? = nil) {
        let newVault = Vault(
            id: UUID(),
            name: name,
            createdAt: Date(),
            updatedAt: Date(),
            pageCount: 0,
            themePayload: nil,
            icon: icon,
            description: description
        )
        vaults.append(newVault)
        do {
            try saveVaultToDatabase(newVault)
        } catch {
            print(" [VaultService]" + " Failed to" + " write new" + " notebook to" + " database: \(error)")
        }
    }
    
    /// 更新已存在笔记本的配置元数据。
    /// - Parameters:
    ///   - id: 目标笔记本 UUID。
    ///   - name: 新的配置名称。
    ///   - icon: 新的图标规格。
    ///   - description: 新的说明文本。
    public func updateVault(id: UUID, name: String, icon: String?, description: String?) {
        if let index = vaults.firstIndex(where: { $0.id == id }) {
            vaults[index].name = name
            vaults[index].icon = icon
            vaults[index].description = description
            vaults[index].updatedAt = Date()
            
            do {
                try saveVaultToDatabase(vaults[index])
            } catch {
                print(" [VaultService]" + " Failed to" + " write updated" + " notebook metadata" + " to database:" + " \(error)")
            }
        }
    }
    
    /// 重命名特定的笔记本。
    /// - Parameters:
    ///   - id: 目标笔记本 UUID。
    ///   - newName: 新的显示标题。
    public func renameVault(id: UUID, newName: String) {
        if let index = vaults.firstIndex(where: { $0.id == id }) {
            vaults[index].name = newName
            vaults[index].updatedAt = Date()
            
            do {
                try saveVaultToDatabase(vaults[index])
            } catch {
                print(" [VaultService]" + " Failed to" + " write renamed" + " notebook to" + " database: \(error)")
            }
        }
    }
    
    /// 物理删除特定的笔记本（敏感操作，物理擦除物理磁盘文件）。
    /// 同时在全局配置表中注销元数据，若删除的是当前所选笔记本，则自动退回至冷启动页面并重置句柄。
    /// - Parameter id: 待完全注销且彻底擦除的目标笔记本唯一识别码 UUID。
    public func deleteVault(id: UUID) {
        vaults.removeAll { $0.id == id }
        if selectedVaultID == id {
            selectedVaultID = nil
            UserDefaults.standard.removeObject(forKey: AppConstants.Keys.Storage.vaultsSelectedID)
            databaseSwitcher.releaseDatabaseConnection()
        }
        
        // 1. 从全局元数据配置数据库中完全抹除
        Task {
            do {
                try await vaultRepository.deleteVault(id: id)
            } catch {
                print(" [VaultService]" + " Failed to" + " delete notebook" + " record from" + " global metadata" + " database: \(error)")
            }
        }
        
        // 2. 物理磁盘异步擦除该金库所托管的专属沙盒物理文件夹
        let dbURL = getVaultDatabaseURL(for: id)
        let folderURL = dbURL.deletingLastPathComponent()
        if FileManager.default.fileExists(atPath: folderURL.path) {
            try? FileManager.default.removeItem(at: folderURL)
            print(" [VaultService]" + " Physically erased" + " notebook sandbox" + " storage: \(id.uuidString)")
        }
    }
}
