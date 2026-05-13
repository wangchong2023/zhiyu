// NotebookHubViewModel.swift
//
// 作者: Wang Chong
// 功能说明: 笔记本工作台 (Notebook Hub) 的视图模型。
// 负责处理笔记本列表的加载、创建、删除及排序逻辑。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Observation
import SwiftUI

/// 笔记本工作台视图模型
@Observable
@MainActor
public final class NotebookHubViewModel {
    
    // MARK: - 状态属性
    
    /// 显示模式
    public enum DisplayMode {
        case grid, list
        
        var icon: String {
            self == .grid ? "square.grid.2x2" : "list.bullet"
        }
    }
    
    /// 当前显示模式
    public var displayMode: DisplayMode = .grid
    
    /// 是否正在显示创建笔记本的弹窗
    public var isShowingCreateSheet: Bool = false
    
    /// 新笔记本名称
    public var newNotebookName: String = ""
    
    /// 是否正在处理加载
    public var isLoading: Bool = false
    
    // MARK: - 依赖
    
    private let vaultService = VaultService.shared
    
    // MARK: - 初始化
    
    public init() {}
    
    // MARK: - 业务逻辑
    
    /// 所有笔记本列表
    public var notebooks: [VaultService.Vault] {
        vaultService.vaults
    }
    
    /// 切换显示模式
    public func toggleDisplayMode() {
        displayMode = (displayMode == .grid) ? .list : .grid
    }
    
    /// 选择笔记本并进入
    /// - Parameter notebook: 选中的笔记本
    public func selectNotebook(_ notebook: VaultService.Vault) {
        vaultService.selectVault(notebook)
    }
    
    /// 创建新笔记本
    public func createNotebook() {
        guard !newNotebookName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        vaultService.createVault(name: newNotebookName)
        newNotebookName = ""
        isShowingCreateSheet = false
    }
    
    /// 删除笔记本
    /// - Parameter id: 笔记本 ID
    public func deleteNotebook(id: UUID) {
        vaultService.deleteVault(id: id)
    }
    
    /// 重命名笔记本
    /// - Parameters:
    ///   - id: 笔记本 ID
    ///   - newName: 新名称
    public func renameNotebook(id: UUID, newName: String) {
        vaultService.renameVault(id: id, newName: newName)
    }
}
