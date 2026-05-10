// IndexView.swift
//
// 作者: Wang Chong
// 功能说明: 知识库索引视图，支持按类型过滤、全量列表展示及核心统计。
// 核心原则：
// 1. 模式化布局：遵循 AppUI.List, AppUI.Sidebar 及 AppUI.Chip 规范。
// 2. 治理标准化：使用 AppUI.Icons 统一图标，Color.app* 统一配色。
// 修改记录:
//   - 2026-05-07: 工业级 UI 治理重构，消除魔鬼数字与硬编码图标。

import SwiftUI

// MARK: - Index View (entry point with NavigationStack)
struct IndexView: View {
    var filterType: PageType? = nil
    var body: some View {
        IndexViewContent(filterType: filterType)
    }
}

// MARK: - Index View Content (for use inside parent NavigationStack)
struct IndexViewContent: View {
    @Environment(AppStore.self) var store
    @EnvironmentObject var themeManager: ThemeManager
    var filterType: PageType? = nil
    
    @State private var showDeleteConfirmation = false
    @State private var pageToDelete: KnowledgePage?

    var body: some View {
        ZStack {
            themeManager.pageBackground()
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: AppUI.standardPadding, pinnedViews: [.sectionHeaders]) {
                    if filterType == nil {
                        summarySection
                    }

                    if filterType == nil || filterType == .entity {
                        entitySection
                    }

                    if filterType == nil || filterType == .concept {
                        conceptSection
                    }

                    if filterType == nil || filterType == .source {
                        sourceSection
                    }

                    if filterType == nil || filterType == .comparison {
                        comparisonSection
                    }
                }
                .padding(.horizontal, AppUI.huge)
                .padding(.vertical, AppUI.loosePadding)
                .padding(.bottom, AppUI.standardPadding * 2)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle(filterType?.displayName ?? Localized.tr("sidebar.allPages"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            HapticFeedback.shared.trigger(.selection)
                            store.refresh()
                        } label: {
                            Label(L10n.Common.tr("refresh"), systemImage: AppUI.Icons.refresh)
                        }
                    }
                }
                .confirmationDialog(
                    pageToDelete.map { Localized.trf("page.deletePageTitle", $0.title) } ?? Localized.tr("page.deletePage"),
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(Localized.tr("page.deletePage"), role: .destructive) {
                        if let page = pageToDelete {
                            store.deletePage(page)
                            HapticFeedback.shared.trigger(.success)
                        }
                    }
                    Button(L10n.Common.tr("cancel"), role: .cancel) {
                        pageToDelete = nil
                    }
                } message: {
                    Text(Localized.tr("settings.clearAll.message"))
                }
        }
    
    @ViewBuilder
    private var summarySection: some View {
        Section {
            HStack(spacing: AppUI.Sidebar.rowSpacing) {
                IndexStatView(label: L10n.Dashboard.tr("index.pages"), value: "\(store.totalPages)", color: .appAccent)
                IndexStatView(label: L10n.Dashboard.tr("index.entities"), value: "\(store.entityCount)", color: .appEntity)
                IndexStatView(label: L10n.Dashboard.tr("index.concepts"), value: "\(store.conceptCount)", color: .appConcept)
                IndexStatView(label: L10n.Dashboard.tr("index.sources"), value: "\(store.sourceCount)", color: .appSource)
            }
            .padding(.vertical, AppUI.tiny)
        } header: {
            HStack {
                Text(L10n.Dashboard.tr("index.overview"))
                    .font(.subheadline.bold())
                    .foregroundStyle(.appSecondary)
                Spacer()
            }
            .padding(.vertical, AppUI.tiny)
            .background(Color.appBackground.opacity(0.01)) // 使 Header 背景透明
        }
    }
    
    @ViewBuilder
    private var entitySection: some View {
        let entities = store.pages.filter { $0.type == .entity }.sorted { $0.title < $1.title }
        if !entities.isEmpty {
            Section {
                VStack(spacing: 0) {
                    ForEach(entities) { page in
                        NavigationLink(value: AppRoute.pageDetail(id: page.id)) {
                            IndexRowView(page: page)
                        }
                        .buttonStyle(.plain)
                        
                        if page.id != entities.last?.id {
                            Divider()
                                .padding(.leading, AppUI.Sidebar.iconBoxSize + AppUI.Sidebar.rowSpacing)
                        }
                    }
                }
                .appContainer(background: Color.appCard.opacity(0.8), padding: true)
            } header: {
                HStack {
                    Label(Localized.trf("index.entityCount", entities.count), systemImage: AppUI.Icons.entity)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appEntity)
                    Spacer()
                }
                .padding(.vertical, AppUI.tiny)
                .background(Color.appBackground.opacity(0.01))
            }
        }
    }
    
    @ViewBuilder
    private var conceptSection: some View {
        let concepts = store.pages.filter { $0.type == .concept }.sorted { $0.title < $1.title }
        if !concepts.isEmpty {
            Section {
                VStack(spacing: 0) {
                    ForEach(concepts) { page in
                        NavigationLink(value: AppRoute.pageDetail(id: page.id)) {
                            IndexRowView(page: page)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                pageToDelete = page
                                showDeleteConfirmation = true
                            } label: {
                                Label(Localized.tr("page.deletePage"), systemImage: AppUI.Icons.delete)
                            }
                        }
                        
                        if page.id != concepts.last?.id {
                            Divider()
                                .padding(.leading, AppUI.Sidebar.iconBoxSize + AppUI.Sidebar.rowSpacing)
                        }
                    }
                }
                .appContainer(background: Color.appCard.opacity(0.8), padding: true)
            } header: {
                HStack {
                    Label(Localized.trf("index.conceptCount", concepts.count), systemImage: AppUI.Icons.concept)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appConcept)
                    Spacer()
                }
                .padding(.vertical, AppUI.tiny)
                .background(Color.appBackground.opacity(0.01))
            }
        }
    }
    
    @ViewBuilder
    private var sourceSection: some View {
        let sources = store.pages.filter { $0.type == .source }.sorted { $0.title < $1.title }
        if !sources.isEmpty {
            Section {
                VStack(spacing: 0) {
                    ForEach(sources) { page in
                        NavigationLink(value: AppRoute.pageDetail(id: page.id)) {
                            IndexRowView(page: page)
                        }
                        .buttonStyle(.plain)
                        
                        if page.id != sources.last?.id {
                            Divider()
                                .padding(.leading, AppUI.Sidebar.iconBoxSize + AppUI.Sidebar.rowSpacing)
                        }
                    }
                }
                .appContainer(background: Color.appCard.opacity(0.8), padding: true)
            } header: {
                HStack {
                    Label(Localized.trf("index.sourceCount", sources.count), systemImage: AppUI.Icons.source)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appSource)
                    Spacer()
                }
                .padding(.vertical, AppUI.tiny)
                .background(Color.appBackground.opacity(0.01))
            }
        }
    }
    
    @ViewBuilder
    private var comparisonSection: some View {
        let comparisons = store.pages.filter { $0.type == .comparison }.sorted { $0.title < $1.title }
        if !comparisons.isEmpty {
            Section {
                VStack(spacing: 0) {
                    ForEach(comparisons) { page in
                        NavigationLink(value: AppRoute.pageDetail(id: page.id)) {
                            IndexRowView(page: page)
                        }
                        .buttonStyle(.plain)
                        
                        if page.id != comparisons.last?.id {
                            Divider()
                                .padding(.leading, AppUI.Sidebar.iconBoxSize + AppUI.Sidebar.rowSpacing)
                        }
                    }
                }
                .appContainer(background: Color.appCard.opacity(0.8), padding: true)
            } header: {
                HStack {
                    Label(Localized.trf("index.comparisonCount", comparisons.count), systemImage: AppUI.Icons.comparison)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appComparison)
                    Spacer()
                }
                .padding(.vertical, AppUI.tiny)
                .background(Color.appBackground.opacity(0.01))
            }
        }
    }
}

// MARK: - Index Stat View
struct IndexStatView: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: AppUI.tiny) {
            Text(label)
                .font(.system(size: AppUI.microFontSize, weight: .semibold))
                .foregroundStyle(.appSecondary)
                .textCase(.uppercase)
            
            Text(value)
                .font(.system(size: AppUI.titleFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppUI.List.rowVerticalPadding)
        .background(Color.appCard.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: AppUI.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppUI.cardRadius)
                .stroke(color.opacity(0.1), lineWidth: AppUI.borderWidth)
        )
    }
}

// MARK: - Index Row View
struct IndexRowView: View {
    let page: KnowledgePage
    @Environment(AppStore.self) var store

    var body: some View {
        HStack(spacing: AppUI.Sidebar.rowSpacing) {
            Image(systemName: page.displayIcon)
                .foregroundStyle(Color.fromModelColorName(page.type.colorName))
                .frame(width: AppUI.Sidebar.iconBoxSize, height: AppUI.Sidebar.iconBoxSize)
                .background(Color.fromModelColorName(page.type.colorName).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: AppUI.microRadius))

            VStack(alignment: .leading, spacing: AppUI.Sidebar.rowVerticalPadding) {
                Text(page.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.appText)
                    .lineLimit(1)
                    .blur(radius: (page.isPrivate && store.isPrivacyModeEnabled) ? AppUI.microRadius : 0)

                HStack(spacing: AppUI.Chip.iconSpacing + 2) {
                    Text(Localized.trf("index.wordCount", page.wordCount))
                        .font(.caption2)
                        .foregroundStyle(.appSecondary)

                    if !page.tags.isEmpty {
                        Text("·")
                            .font(.caption2)
                            .foregroundStyle(.appSecondary)
                        Text(page.tags.prefix(2).joined(separator: ", "))
                            .font(.caption2)
                            .foregroundStyle(.appSecondary)
                    }
                }
                .blur(radius: (page.isPrivate && store.isPrivacyModeEnabled) ? AppUI.microRadius - 1 : 0)
            }

            Spacer()

            if page.isPrivate {
                Image(systemName: store.isPrivacyModeEnabled ? AppUI.Icons.lock : AppUI.Icons.lockOpen)
                    .font(.system(size: AppUI.microFontSize))
                    .foregroundStyle(store.isPrivacyModeEnabled ? .appAccent : .appSecondary)
                    .padding(AppUI.tiny)
                    .background(Color.appAccent.opacity(store.isPrivacyModeEnabled ? 0.1 : 0.05))
                    .clipShape(Circle())
            }

            // Confidence indicator
            Circle()
                .fill(Color.fromModelColorName(page.confidence.colorName))
                .frame(width: AppUI.small, height: AppUI.small)
        }
        .padding(.vertical, AppUI.tiny)
        .overlay {
            if page.isPrivate && store.isPrivacyModeEnabled {
                Color.appBackground.opacity(0.01)
            }
        }
    }
}
