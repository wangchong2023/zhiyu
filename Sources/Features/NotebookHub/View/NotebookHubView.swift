// NotebookHubView.swift
//
// 作者: Wang Chong
// 功能说明: 笔记本工作台 (Notebook Hub) 的主视图。
// 采用 2 列卡片式布局展现所有笔记本，提供沉浸式的笔记本管理体验。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 笔记本工作台视图
public struct NotebookHubView: View {
    // MARK: - 状态与环境
    
    @State private var viewModel = NotebookHubViewModel()
    @Environment(Router.self) var router
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: - 初始化
    
    public init() {}
    
    // MARK: - 视图主体
    
    public var body: some View {
        @Bindable var viewModel = viewModel
        
        NavigationStack {
            ZStack {
                themeManager.pageBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Vault.homeVerticalPadding) {
                        headerSection
                        
                        notebookGridSection
                    }
                    .padding(.vertical, DesignSystem.Vault.homeVerticalPadding)
                }
            }
            .navigationTitle(L10n.Vault.tr("homeTitle"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    brandLogo
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: DesignSystem.medium) {
                        displayModeButton
                        UserProfileMenu()
                    }
                }
            }
            .alert(L10n.Vault.tr("create"), isPresented: $viewModel.isShowingCreateSheet) {
                TextField(L10n.Vault.tr("namePlaceholder"), text: $viewModel.newNotebookName)
                Button(L10n.Common.tr("cancel"), role: .cancel) { viewModel.newNotebookName = "" }
                Button(L10n.Vault.tr("create")) {
                    viewModel.createNotebook()
                }
            }
        }
    }
    
    // MARK: - 子视图组件
    
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
    
    private var notebookGridSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.medium) {
            createNotebookCard
            
            ForEach(viewModel.notebooks) { notebook in
                NotebookCard(notebook: notebook) {
                    viewModel.selectNotebook(notebook)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Vault.homePadding)
    }
    
    private var createNotebookCard: some View {
        Button(action: { viewModel.isShowingCreateSheet = true }) {
            VStack(spacing: DesignSystem.medium) {
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
    
    private var brandLogo: some View {
        HStack(spacing: DesignSystem.tiny) {
            Image(systemName: "square.stack.3d.up.fill")
                .foregroundStyle(LinearGradient(colors: [.appAccent, .appSource], startPoint: .top, endPoint: .bottom))
            Text("知予")
                .font(.headline.bold())
                .foregroundStyle(.appText)
        }
    }
    
    private var displayModeButton: some View {
        Button(action: { viewModel.toggleDisplayMode() }) {
            Image(systemName: viewModel.displayMode.icon)
                .font(.system(size: DesignSystem.Metrics.dashboardLabelSize))
                .foregroundStyle(.appSecondary)
        }
    }
}

// MARK: - 辅助组件

struct NotebookCard: View {
    let notebook: VaultService.Vault
    let action: () -> Void
    
    private var themeConfig: NotebookThemeConfig {
        if let payload = notebook.themePayload,
           let data = payload.data(using: .utf8),
           let config = try? JSONDecoder().decode(NotebookThemeConfig.self, from: data) {
            return config
        }
        return NotebookThemeFactory.generate(from: notebook.name, id: notebook.id)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: DesignSystem.medium) {
                // 封面
                ZStack(alignment: .bottomLeading) {
                    NotebookThemeBackgroundView(config: themeConfig)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.small))
                        .frame(height: DesignSystem.Vault.coverHeight)
                    
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.3))
                        .padding(DesignSystem.medium)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(notebook.name)
                        .font(.headline.bold())
                        .foregroundStyle(.appText)
                        .lineLimit(1)
                    
                    Text("\(notebook.pageCount) " + L10n.Vault.tr("page.knowledge"))
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                }
                .padding(.horizontal, 4)
            }
            .padding(DesignSystem.medium)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}
