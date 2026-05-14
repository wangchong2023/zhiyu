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
    @Environment(Router.self) var router
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var viewModel = VaultHomeViewModel()
    
    var body: some View {
        @Bindable var router = router
        @Bindable var viewModel = viewModel
        
        NavigationStack(path: $router.path) {
            ZStack {
                themeManager.pageBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Vault.homeVerticalPadding) {
                        headerSection
                        
                        if viewModel.displayMode == .grid {
                            VaultGridLayout {
                                createVaultCard
                                
                                ForEach(vaultService.vaults) { vault in
                                    VaultCard(vault: vault) {
                                        withAnimation(DesignSystem.Animation.standard) {
                                            viewModel.selectVault(vault)
                                        }
                                    }
                                    .contextMenu {
                                        vaultContextMenu(for: vault)
                                    }
                                }
                            }
                        } else {
                            VaultListLayout {
                                ForEach(vaultService.vaults) { vault in
                                    VaultListRow(vault: vault) {
                                        withAnimation(DesignSystem.Animation.standard) {
                                            viewModel.selectVault(vault)
                                        }
                                    }
                                    .contextMenu {
                                        vaultContextMenu(for: vault)
                                    }
                                }
                                
                                Button(action: { viewModel.showCreateSheet = true }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(.appAccent)
                                        Text(L10n.Vault.tr("new"))
                                            .foregroundStyle(.appAccent)
                                        Spacer()
                                    }
                                    .padding(DesignSystem.standardPadding)
                                    .background(Color.appCard.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.small))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                                            .strokeBorder(style: StrokeStyle(lineWidth: DesignSystem.borderWidth, dash: [4]))
                                            .foregroundStyle(.appAccent.opacity(0.3))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, DesignSystem.Vault.homeVerticalPadding)
                }
            }
            .appTabToolbar(title: L10n.Vault.tr("homeTitle")) {
                Button(action: {
                    withAnimation(DesignSystem.Animation.standard) {
                        viewModel.toggleDisplayMode()
                    }
                }) {
                    Image(systemName: viewModel.displayMode.icon)
                        .font(.system(size: DesignSystem.Metrics.dashboardLabelSize, weight: .bold))
                        .frame(width: DesignSystem.Timeline.indicatorSize, height: DesignSystem.Timeline.indicatorSize)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .foregroundStyle(.appSecondary)
            }
            .alert(L10n.Vault.tr("create"), isPresented: $viewModel.showCreateSheet) {
                TextField(L10n.Vault.tr("namePlaceholder"), text: $viewModel.newVaultName)
                Button(L10n.Common.tr("cancel"), role: .cancel) { viewModel.newVaultName = "" }
                Button(L10n.Vault.tr("create")) {
                    viewModel.createVault()
                }
            }
            .alert(L10n.Vault.tr("rename"), isPresented: $viewModel.showRenameSheet) {
                TextField(L10n.Vault.tr("namePlaceholder"), text: $viewModel.renameText)
                Button(L10n.Common.tr("cancel"), role: .cancel) { }
                Button(L10n.Common.tr("save")) {
                    viewModel.confirmRename()
                }
            }
            .confirmationDialog(
                L10n.Common.tr("deleteConfirm"),
                isPresented: $viewModel.showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button(L10n.Common.tr("delete"), role: .destructive) {
                    viewModel.confirmDelete()
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
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            Text(L10n.Vault.tr("welcome"))
                .font(.system(size: DesignSystem.displayFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.appText)
            
            Text(L10n.Vault.tr("subtitle"))
                .font(.system(size: DesignSystem.bodyFontSize))
                .foregroundStyle(.appSecondary)
        }
        .padding(.horizontal, DesignSystem.Vault.homePadding)
    }
    
    private var createVaultCard: some View {
        Button(action: { viewModel.showCreateSheet = true }) {
            VStack(spacing: DesignSystem.standardPadding) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: DesignSystem.Gallery.iconSize))
                    .foregroundStyle(.appAccent)
                
                Text(L10n.Vault.tr("new"))
                    .font(.system(size: DesignSystem.headlineFontSize, weight: .bold))
                    .foregroundStyle(.appAccent)
            }
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Vault.cardHeight)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                    .strokeBorder(style: StrokeStyle(lineWidth: DesignSystem.atomic, dash: [6]))
                    .foregroundStyle(.appAccent.opacity(0.3))
            )
            .background(Color.appCard.opacity(0.5))
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func vaultContextMenu(for vault: VaultService.Vault) -> some View {
        Button {
            viewModel.initiateRename(for: vault)
        } label: {
            Label(L10n.Common.tr("edit"), systemImage: "pencil")
        }
        
        Button(role: .destructive) {
            viewModel.initiateDelete(for: vault)
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
            VStack(alignment: .leading, spacing: DesignSystem.medium) {
                // 封面装饰
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                        .fill(LinearGradient(colors: [.appAccent.opacity(0.8), .appConcept.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(height: DesignSystem.Vault.coverHeight)
                    
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: DesignSystem.titleFontSize))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(DesignSystem.medium)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                    Text(vault.name)
                        .font(.system(size: DesignSystem.headlineFontSize, weight: .bold))
                        .foregroundStyle(.appText)
                        .lineLimit(1)
                    
                    Text("\(vault.pageCount) " + L10n.Vault.tr("page.knowledge"))
                        .font(.system(size: DesignSystem.captionFontSize))
                        .foregroundStyle(.appSecondary)
                }
                .padding(.horizontal, DesignSystem.tiny)
            }
            .padding(DesignSystem.mediumRadius)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .shadow(color: DesignSystem.shadowColor, radius: DesignSystem.shadowRadius, y: DesignSystem.shadowY)
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
            HStack(spacing: DesignSystem.standardPadding) {
                // 封面装饰
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.micro)
                        .fill(LinearGradient(colors: [.appAccent.opacity(0.8), .appConcept.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: DesignSystem.Vault.listCoverSize, height: DesignSystem.Vault.listCoverSize)
                    
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: DesignSystem.captionFontSize))
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                    Text(vault.name)
                        .font(.system(size: DesignSystem.subheadlineFontSize, weight: .bold))
                        .foregroundStyle(.appText)
                    
                    Text("\(vault.pageCount) " + L10n.Vault.tr("page.knowledge"))
                        .font(.system(size: DesignSystem.caption2FontSize))
                        .foregroundStyle(.appSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: DesignSystem.caption2FontSize))
                    .foregroundStyle(.appSecondary.opacity(0.5))
            }
            .padding(.vertical, DesignSystem.small)
            .padding(.horizontal, DesignSystem.medium)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.small))
            .shadow(color: .black.opacity(0.02), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

