// VaultHomeView.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了知识管理系统的笔记本主页视图 (VaultHomeView)。
// 提供笔记本列表展示、创建、重命名及删除功能，作为进入主系统的入口。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 笔记本/库主页视图
struct VaultHomeView: View {
    @Environment(VaultService.self) var vaultService
    @Environment(AuthService.self) var authService
    @Environment(AppRouter.self) var router
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var showCreateSheet = false
    @State private var newVaultName = ""
    @State private var vaultToRename: VaultService.Vault?
    @State private var renameText = ""
    @State private var showDeleteConfirm = false
    @State private var vaultToDelete: VaultService.Vault?
    
    @State private var displayMode: DisplayMode = .grid
    
    enum DisplayMode: String, CaseIterable {
        case grid, list
        var icon: String { self == .grid ? "square.grid.2x2" : "list.bullet" }
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 20)
    ]
    
    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            ZStack {
                themeManager.pageBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 40) {
                        headerSection
                        
                        if displayMode == .grid {
                            LazyVGrid(columns: columns, spacing: 25) {
                                createVaultCard
                                
                                ForEach(vaultService.vaults) { vault in
                                    VaultCard(vault: vault) {
                                        withAnimation(.spring()) {
                                            vaultService.selectVault(vault)
                                        }
                                    }
                                    .contextMenu {
                                        vaultContextMenu(for: vault)
                                    }
                                }
                            }
                            .padding(.horizontal, 25)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(vaultService.vaults) { vault in
                                    VaultListRow(vault: vault) {
                                        withAnimation(.spring()) {
                                            vaultService.selectVault(vault)
                                        }
                                    }
                                    .contextMenu {
                                        vaultContextMenu(for: vault)
                                    }
                                }
                                
                                Button(action: { showCreateSheet = true }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(.appAccent)
                                        Text(L10n.Vault.tr("new"))
                                            .foregroundStyle(.appAccent)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.appCard.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: Spacing.smallRadius))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Spacing.smallRadius)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                            .foregroundStyle(.appAccent.opacity(0.3))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 25)
                        }
                    }
                    .padding(.vertical, 40)
                }
            }
            .navigationTitle(L10n.Vault.tr("homeTitle"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    VaultBadge()
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        Button(action: {
                            withAnimation(.spring()) {
                                displayMode = displayMode == .grid ? .list : .grid
                            }
                        }) {
                            Image(systemName: displayMode == .grid ? "list.bullet" : "square.grid.2x2")
                                .font(.system(size: 13, weight: .bold))
                                .frame(width: 36, height: 36)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .foregroundStyle(.appSecondary)
                        
                        UserProfileMenu()
                    }
                }
            }
            .alert(L10n.Vault.tr("create"), isPresented: $showCreateSheet) {
                TextField(L10n.Vault.tr("namePlaceholder"), text: $newVaultName)
                Button(L10n.Common.tr("cancel"), role: .cancel) { newVaultName = "" }
                Button(L10n.Vault.tr("create")) {
                    if !newVaultName.isEmpty {
                        vaultService.createVault(name: newVaultName)
                        newVaultName = ""
                    }
                }
            }
            .alert(L10n.Vault.tr("rename"), isPresented: Binding(
                get: { vaultToRename != nil },
                set: { if !$0 { vaultToRename = nil } }
            )) {
                TextField(L10n.Vault.tr("namePlaceholder"), text: $renameText)
                Button(L10n.Common.tr("cancel"), role: .cancel) { }
                Button(L10n.Common.tr("save")) {
                    if let vault = vaultToRename, !renameText.isEmpty {
                        vaultService.renameVault(id: vault.id, newName: renameText)
                    }
                }
            }
            .confirmationDialog(
                L10n.Common.tr("deleteConfirm"),
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button(L10n.Common.tr("delete"), role: .destructive) {
                    if let vault = vaultToDelete {
                        vaultService.deleteVault(id: vault.id)
                    }
                }
                Button(L10n.Common.tr("cancel"), role: .cancel) { }
            }
            .navigationDestination(for: AppRoute.self) { route in
                ViewFactory.makeView(for: route)
            }
        }
    }
    
    // MARK: - 子视图
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.Vault.tr("welcome"))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.appText)
            
            Text(L10n.Vault.tr("subtitle"))
                .font(.body)
                .foregroundStyle(.appSecondary)
        }
        .padding(.horizontal, 25)
    }
    
    private var createVaultCard: some View {
        Button(action: { showCreateSheet = true }) {
            VStack(spacing: 15) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.appAccent)
                
                Text(L10n.Vault.tr("new"))
                    .font(.headline)
                    .foregroundStyle(.appAccent)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(
                RoundedRectangle(cornerRadius: Spacing.cardRadius)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .foregroundStyle(.appAccent.opacity(0.3))
            )
            .background(Color.appCard.opacity(0.5))
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func vaultContextMenu(for vault: VaultService.Vault) -> some View {
        Button {
            vaultToRename = vault
            renameText = vault.name
        } label: {
            Label(L10n.Common.tr("edit"), systemImage: "pencil")
        }
        
        Button(role: .destructive) {
            vaultToDelete = vault
            showDeleteConfirm = true
        } label: {
            Label(L10n.Common.tr("delete"), systemImage: "trash")
        }
    }
}

// MARK: - 笔记本卡片组件

struct VaultCard: View {
    let vault: VaultService.Vault
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // 封面装饰
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: Spacing.smallRadius)
                        .fill(LinearGradient(colors: [.appAccent.opacity(0.8), .appConcept.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(height: 100)
                    
                    Image(systemName: "book.closed.fill")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(12)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(vault.name)
                        .font(.headline)
                        .foregroundStyle(.appText)
                        .lineLimit(1)
                    
                    Text("\(vault.pageCount) " + L10n.Vault.tr("page.knowledge"))
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                }
                .padding(.horizontal, 4)
            }
            .padding(10)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cardRadius))
            .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 笔记本列表行组件

struct VaultListRow: View {
    let vault: VaultService.Vault
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 封面装饰
                ZStack {
                    RoundedRectangle(cornerRadius: Spacing.microRadius)
                        .fill(LinearGradient(colors: [.appAccent.opacity(0.8), .appConcept.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "book.closed.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(vault.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appText)
                    
                    Text("\(vault.pageCount) " + L10n.Vault.tr("page.knowledge"))
                        .font(.caption2)
                        .foregroundStyle(.appSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.appSecondary.opacity(0.5))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.smallRadius))
            .shadow(color: .black.opacity(0.02), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}
