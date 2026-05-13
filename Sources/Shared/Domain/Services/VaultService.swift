// VaultService.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了知识管理系统的笔记本/库 (Vault) 管理服务。
// 支持创建、删除、重命名笔记本，并管理当前选中的笔记本。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Observation

/// 笔记本/库服务
@Observable
@MainActor
public final class VaultService {
    
    // MARK: - 数据模型
    
    public struct Vault: Identifiable, Codable, Hashable {
        public let id: UUID
        public var name: String
        public var createdAt: Date
        public var pageCount: Int
    }
    
    // MARK: - 状态属性
    
    /// 所有笔记本列表
    public var vaults: [Vault] = []
    
    /// 当前选中的笔记本 ID
    public var selectedVaultID: UUID?
    
    /// 当前选中的笔记本对象
    public var currentVault: Vault? {
        vaults.first { $0.id == selectedVaultID }
    }
    
    // MARK: - 单例与初始化
    
    public static let shared = VaultService()
    
    private init() {
        loadVaults()
    }
    
    // MARK: - 核心操作
    
    /// 加载所有笔记本
    private func loadVaults() {
        if let data = UserDefaults.standard.data(forKey: "vaults.list"),
           let decoded = try? JSONDecoder().decode([Vault].self, from: data) {
            self.vaults = decoded
        } else {
            // 初始演示库
            self.vaults = [
                Vault(id: UUID(), name: "我的知识库", createdAt: Date(), pageCount: 12),
                Vault(id: UUID(), name: "项目调研", createdAt: Date(), pageCount: 5)
            ]
            saveVaults()
        }
        
        if let idString = UserDefaults.standard.string(forKey: "vaults.selectedID"),
           let id = UUID(uuidString: idString) {
            self.selectedVaultID = id
        }
    }
    
    /// 保存笔记本列表
    private func saveVaults() {
        if let data = try? JSONEncoder().encode(vaults) {
            UserDefaults.standard.set(data, forKey: "vaults.list")
        }
    }
    
    /// 选中一个笔记本
    public func selectVault(_ vault: Vault) {
        self.selectedVaultID = vault.id
        UserDefaults.standard.set(vault.id.uuidString, forKey: "vaults.selectedID")
    }
    
    /// 退出当前笔记本 (返回主页)
    public func exitVault() {
        self.selectedVaultID = nil
        UserDefaults.standard.removeObject(forKey: "vaults.selectedID")
    }
    
    /// 创建新笔记本
    public func createVault(name: String) {
        let newVault = Vault(id: UUID(), name: name, createdAt: Date(), pageCount: 0)
        vaults.append(newVault)
        saveVaults()
    }
    
    /// 重命名笔记本
    public func renameVault(id: UUID, newName: String) {
        if let index = vaults.firstIndex(where: { $0.id == id }) {
            vaults[index].name = newName
            saveVaults()
        }
    }
    
    /// 删除笔记本
    public func deleteVault(id: UUID) {
        vaults.removeAll { $0.id == id }
        if selectedVaultID == id {
            selectedVaultID = nil
            UserDefaults.standard.removeObject(forKey: "vaults.selectedID")
        }
        saveVaults()
    }
}
