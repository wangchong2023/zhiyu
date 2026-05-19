// NotebookHubView.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：笔记本工作台 (Notebook Hub) 的主视图。
// 采用 2 列卡片式布局展现所有笔记本，提供沉浸式的笔记本管理体验。
// 版本: 1.1
// 修改记录:
//   - 2026-05-16: 视图拆分：将 NotebookCard, NotebookListRow, NotebookFormSheet 拆分至独立组件。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

@MainActor
/// 笔记本工作台视图
public struct NotebookHubView: View {
    // MARK: - 状态与环境
    
    @State private var viewModel = NotebookHubViewModel()
    @State private var showLintSheet = false   // 控制知识巡检面板弹出
    @Environment(Router.self) var router
    @EnvironmentObject var themeManager: ThemeManager
    @Inject var appEnv: any AppEnvironmentProtocol // 注入环境能力
    
    // MARK: - 初始化
    
    public init() {}
    
    // MARK: - 视图主体
    
    public var body: some View {
        @Bindable var viewModel = viewModel
        
        ZStack(alignment: .top) {
            // 统一背景系统：自动适配深浅模式与强调色
            themeManager.pageBackground()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.standardPadding) {
                    // 1. 现代风格搜索区域
                    searchBar(bindableViewModel: Bindable(viewModel))
                    
                    AIProcessingStatusBanner()
                        .padding(.horizontal, DesignSystem.Vault.homePadding)

                    notebookGridSection
                }
                .padding(.bottom, DesignSystem.huge)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(L10n.Vault.homeTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                sparklesButton
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: DesignSystem.medium) {
                    #if !os(watchOS)
                    sortMenu
                    #endif
                    displayModeButton
                    UserProfileMenu()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("toggleDisplayMode"))) { _ in
            viewModel.toggleDisplayMode()
        }
        .sheet(isPresented: $viewModel.isShowingCreateSheet) {
            CreateNotebookSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isShowingEditSheet) {
            EditNotebookSheet(viewModel: viewModel)
        }
        .alert(L10n.Vault.rename, isPresented: $viewModel.isShowingRenameAlert) {
            TextField(L10n.Vault.namePlaceholder, text: $viewModel.editingName)
            Button(L10n.Common.cancel, role: .cancel) { }
            Button(L10n.Common.ok) {
                viewModel.confirmRename()
            }
        } message: {
            Text(L10n.Vault.renameMessage)
        }
        .environment(viewModel)
        // 以 sheet 弹出知识巡检视图（因 NotebookHub 的 NavigationStack 无 navigationDestination）
        .sheet(isPresented: $showLintSheet) {
            NavigationStack {
                LintWrapper()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(L10n.Common.close) {
                                showLintSheet = false
                            }
                        }
                    }
            }
        }
    }
    
    // MARK: - 子视图组件
    
    private func searchBar(bindableViewModel: Bindable<NotebookHubViewModel>) -> some View {
        HStack {
            Image(systemName: DesignSystem.Icons.search)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.appAccent)
            
            TextField(L10n.Search.base, text: bindableViewModel.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
            
            if !bindableViewModel.searchText.wrappedValue.isEmpty {
                Button { bindableViewModel.searchText.wrappedValue = "" } label: {
                    Image(systemName: DesignSystem.Icons.errorCircle)
                        .foregroundStyle(.appSecondary.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, DesignSystem.standardPadding)
        .padding(.vertical, DesignSystem.tightPadding + DesignSystem.atomic)
        .background(Color.appCard.opacity(DesignSystem.glassOpacity * 2))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.appAccent.opacity(DesignSystem.Opacity.glass), lineWidth: 1)
        )
        .padding(.horizontal, DesignSystem.Vault.homePadding)
        .padding(.top, DesignSystem.medium)
    }

    private var notebookGridSection: some View {
        Group {
            if viewModel.displayMode == .grid {
                let columns = appEnv.screenClass == .expansive 
                    ? [GridItem(.adaptive(minimum: 250), spacing: DesignSystem.standardPadding)]
                    : [GridItem(.flexible(), spacing: DesignSystem.standardPadding), GridItem(.flexible(), spacing: DesignSystem.standardPadding)]
                
                LazyVGrid(columns: columns, spacing: DesignSystem.standardPadding) {
                    CreateNotebookButton(viewModel: viewModel, displayMode: .grid)
                    
                    ForEach(viewModel.notebooks) { notebook in
                        NotebookCard(notebook: notebook) {
                            viewModel.selectNotebook(notebook)
                        }
                    }
                }
            } else {
                VStack(spacing: DesignSystem.medium) {
                    CreateNotebookButton(viewModel: viewModel, displayMode: .list)
                    
                    ForEach(viewModel.notebooks) { notebook in
                        NotebookListRow(notebook: notebook) {
                            viewModel.selectNotebook(notebook)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, DesignSystem.Vault.homePadding)
    }
    
    private var sparklesButton: some View {
        Button {
            HapticFeedback.shared.trigger(.selection)
            // NotebookHub 处于独立 NavigationStack（无 navigationDestination），
            // 以 sheet 方式弹出 LintView 避免路由无法响应的问题
            showLintSheet = true
        } label: {
            Image(systemName: DesignSystem.Icons.sparkles)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.appAccent)
        }
        .buttonStyle(.plain)
    }
    
    private var displayModeButton: some View {
        Button(action: { viewModel.toggleDisplayMode() }) {
            Image(systemName: viewModel.displayMode.icon)
                .font(.system(size: DesignSystem.bodyFontSize))
                .foregroundStyle(.appSecondary)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var sortMenu: some View {
        #if os(watchOS)
        EmptyView()
        #else
        Menu {
            Button {
                viewModel.sortOption = .date
            } label: {
                Label(L10n.Vault.sort.date, systemImage: DesignSystem.Icons.sortDate)
            }
            
            Button {
                viewModel.sortOption = .name
            } label: {
                Label(L10n.Vault.sort.name, systemImage: DesignSystem.Icons.sortName)
            }
        } label: {
            Image(systemName: DesignSystem.Icons.sortUpDown)
                .font(.system(size: DesignSystem.bodyFontSize))
                .foregroundStyle(.appSecondary)
        }
        .buttonStyle(.plain)
        #endif
    }
}
