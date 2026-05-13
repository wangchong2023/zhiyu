// VaultHomeViewModel.swift
//
// 作者: Wang Chong
// 功能说明: 笔记本主页的 ViewModel，处理创建、重命名、删除及视图显示模式状态。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class VaultHomeViewModel {
    
    enum DisplayMode: String, CaseIterable {
        case grid, list
        var icon: String { self == .grid ? "square.grid.2x2" : "list.bullet" }
    }
    
    // UI State
    var displayMode: DisplayMode = .grid
    
    // Action State
    var showCreateSheet = false
    var newVaultName = ""
    
    var showRenameSheet = false
    var renameText = ""
    var vaultToRename: VaultService.Vault? {
        didSet {
            showRenameSheet = vaultToRename != nil
            if let vault = vaultToRename {
                renameText = vault.name
            }
        }
    }
    
    var showDeleteConfirm = false
    var vaultToDelete: VaultService.Vault? {
        didSet {
            showDeleteConfirm = vaultToDelete != nil
        }
    }
    
    private var vaultService: VaultService { VaultService.shared } // TODO: Migrate to DI if needed
    
    init() {}
    
    func toggleDisplayMode() {
        displayMode = displayMode == .grid ? .list : .grid
    }
    
    func createVault() {
        guard !newVaultName.isEmpty else { return }
        vaultService.createVault(name: newVaultName)
        newVaultName = ""
        showCreateSheet = false
    }
    
    func initiateRename(for vault: VaultService.Vault) {
        vaultToRename = vault
    }
    
    func confirmRename() {
        if let vault = vaultToRename, !renameText.isEmpty {
            vaultService.renameVault(id: vault.id, newName: renameText)
        }
        vaultToRename = nil
    }
    
    func initiateDelete(for vault: VaultService.Vault) {
        vaultToDelete = vault
    }
    
    func confirmDelete() {
        if let vault = vaultToDelete {
            vaultService.deleteVault(id: vault.id)
        }
        vaultToDelete = nil
    }
    
    func selectVault(_ vault: VaultService.Vault) {
        vaultService.selectVault(vault)
    }
}
