// SidebarView.swift
//
// 作者: Wang Chong
// 功能说明: [L3] 应用调度层：本文件实现了知识管理系统的核心导航分发中心（SidebarView）。
// 版本: 1.2
// 修改记录:
//   - 2026-05-16: 表现层精益重构：将 400+ 行文件拆解为原子化组件，核心行数压降至 100 行以内。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

@MainActor
struct SidebarView: View {
    // MARK: - Environment & Store
    @Environment(AppStore.self) var store
    @Environment(VaultService.self) var vaultService
    @Environment(IngestStore.self) var ingestStore
    @Environment(Router.self) var router
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - Properties
    var heroNamespace: Namespace.ID
    var selection: Binding<SidebarSelection?>? = nil
    
    // MARK: - Local State
    @State private var showDeleteConfirmation = false
    @State private var pageToDelete: KnowledgePage?

    // MARK: - Body
    var body: some View {
        @Bindable var router = router
        
        Group {
            if horizontalSizeClass == .compact {
                List {
                    SearchSection()
                    CapabilitiesSection()
                    SourcesSection()
                    UniverseSection()
                    PinnedSection(
                        heroNamespace: heroNamespace,
                        pageToDelete: $pageToDelete,
                        showDeleteConfirmation: $showDeleteConfirmation
                    )
                    ToolsSection()
                    PluginRibbonSection()
                }
            } else {
                List(selection: $router.sidebarSelection) {
                    SearchSection()
                    CapabilitiesSection()
                    SourcesSection()
                    UniverseSection()
                    PinnedSection(
                        heroNamespace: heroNamespace,
                        pageToDelete: $pageToDelete,
                        showDeleteConfirmation: $showDeleteConfirmation
                    )
                    ToolsSection()
                    PluginRibbonSection()
                }
            }
        }
        .background(
            PageBackgroundView(accentColor: themeManager.accentColor)
                .ignoresSafeArea()
        )
        .scrollContentBackground(.hidden)
        .modifier(SidebarListStyleModifier(horizontalSizeClass: horizontalSizeClass))
        .confirmationDialog(
            pageToDelete.map { L10n.Vault.Page.deletePageTitle($0.title) } ?? L10n.Vault.Page.deletePage,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.Vault.Page.deletePage, role: .destructive) {
                if let page = pageToDelete {
                    Task { await store.deletePage(page) }
                }
            }
            Button(L10n.Common.cancel, role: .cancel) {
                pageToDelete = nil
            }
        }
        .appTabToolbar(title: L10n.Common.Sidebar.title)
        .id(router.languageForceUpdate)
    }
}
