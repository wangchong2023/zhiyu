// IndexView.swift
//
// 作者: Wang Chong
// 功能说明: 知识库索引视图，支持按类型过滤、全量列表展示及核心统计。
// 核心原则：
// 1. 模式化布局：遵循 DesignSystem.List, DesignSystem.Sidebar 及 DesignSystem.Chip 规范。
// 2. 治理标准化：使用 DesignSystem.Icons 统一图标，Color.app* 统一配色。
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
                LazyVStack(spacing: DesignSystem.standardPadding, pinnedViews: [.sectionHeaders]) {
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
                .padding(.horizontal, DesignSystem.huge)
                .padding(.vertical, DesignSystem.loosePadding)
                .padding(.bottom, DesignSystem.standardPadding * 2)
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
                            Label(L10n.Common.tr("refresh"), systemImage: DesignSystem.Icons.refresh)
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
            HStack(spacing: DesignSystem.Sidebar.rowSpacing) {
                IndexStatView(label: L10n.Dashboard.tr("index.pages"), value: "\(store.totalPages)", color: .appAccent)
                IndexStatView(label: L10n.Dashboard.tr("index.entities"), value: "\(store.entityCount)", color: .appEntity)
                IndexStatView(label: L10n.Dashboard.tr("index.concepts"), value: "\(store.conceptCount)", color: .appConcept)
                IndexStatView(label: L10n.Dashboard.tr("index.sources"), value: "\(store.sourceCount)", color: .appSource)
            }
            .padding(.vertical, DesignSystem.tiny)
        } header: {
            HStack {
                Text(L10n.Dashboard.tr("index.overview"))
                    .font(.subheadline.bold())
                    .foregroundStyle(.appSecondary)
                Spacer()
            }
            .padding(.vertical, DesignSystem.tiny)
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
                                .padding(.leading, DesignSystem.Sidebar.iconBoxSize + DesignSystem.Sidebar.rowSpacing)
                        }
                    }
                }
                .appContainer(background: Color.appCard.opacity(0.8), padding: true)
            } header: {
                HStack {
                    Label(Localized.trf("index.entityCount", entities.count), systemImage: DesignSystem.Icons.entity)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appEntity)
                    Spacer()
                }
                .padding(.vertical, DesignSystem.tiny)
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
                                Label(Localized.tr("page.deletePage"), systemImage: DesignSystem.Icons.delete)
                            }
                        }
                        
                        if page.id != concepts.last?.id {
                            Divider()
                                .padding(.leading, DesignSystem.Sidebar.iconBoxSize + DesignSystem.Sidebar.rowSpacing)
                        }
                    }
                }
                .appContainer(background: Color.appCard.opacity(0.8), padding: true)
            } header: {
                HStack {
                    Label(Localized.trf("index.conceptCount", concepts.count), systemImage: DesignSystem.Icons.concept)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appConcept)
                    Spacer()
                }
                .padding(.vertical, DesignSystem.tiny)
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
                                .padding(.leading, DesignSystem.Sidebar.iconBoxSize + DesignSystem.Sidebar.rowSpacing)
                        }
                    }
                }
                .appContainer(background: Color.appCard.opacity(0.8), padding: true)
            } header: {
                HStack {
                    Label(Localized.trf("index.sourceCount", sources.count), systemImage: DesignSystem.Icons.source)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appSource)
                    Spacer()
                }
                .padding(.vertical, DesignSystem.tiny)
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
                                .padding(.leading, DesignSystem.Sidebar.iconBoxSize + DesignSystem.Sidebar.rowSpacing)
                        }
                    }
                }
                .appContainer(background: Color.appCard.opacity(0.8), padding: true)
            } header: {
                HStack {
                    Label(Localized.trf("index.comparisonCount", comparisons.count), systemImage: DesignSystem.Icons.comparison)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appComparison)
                    Spacer()
                }
                .padding(.vertical, DesignSystem.tiny)
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
        VStack(spacing: DesignSystem.tiny) {
            Text(label)
                .font(.system(size: DesignSystem.microFontSize, weight: .semibold))
                .foregroundStyle(.appSecondary)
                .textCase(.uppercase)
            
            Text(value)
                .font(.system(size: DesignSystem.titleFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.List.rowVerticalPadding)
        .background(.ultraThinMaterial.opacity(0.8))
        .background(Color.appCard.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cardRadius)
                .stroke(color.opacity(0.2), lineWidth: DesignSystem.borderWidth)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Index Row View
struct IndexRowView: View {
    let page: KnowledgePage
    @Environment(AppStore.self) var store

    var body: some View {
        HStack(spacing: DesignSystem.Sidebar.rowSpacing) {
            Image(systemName: page.displayIcon)
                .foregroundStyle(Color.fromModelColorName(page.type.colorName))
                .frame(width: DesignSystem.Sidebar.iconBoxSize, height: DesignSystem.Sidebar.iconBoxSize)
                .background(Color.fromModelColorName(page.type.colorName).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.microRadius))

            VStack(alignment: .leading, spacing: DesignSystem.Sidebar.rowVerticalPadding) {
                Text(page.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.appText)
                    .lineLimit(1)
                    .blur(radius: (page.isPrivate && store.isPrivacyModeEnabled) ? DesignSystem.microRadius : 0)

                HStack(spacing: DesignSystem.Chip.iconSpacing + 2) {
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
                .blur(radius: (page.isPrivate && store.isPrivacyModeEnabled) ? DesignSystem.microRadius - 1 : 0)
            }

            Spacer()

            if page.isPrivate {
                Image(systemName: store.isPrivacyModeEnabled ? DesignSystem.Icons.lock : DesignSystem.Icons.lockOpen)
                    .font(.system(size: DesignSystem.microFontSize))
                    .foregroundStyle(store.isPrivacyModeEnabled ? .appAccent : .appSecondary)
                    .padding(DesignSystem.tiny)
                    .background(Color.appAccent.opacity(store.isPrivacyModeEnabled ? 0.1 : 0.05))
                    .clipShape(Circle())
            }

            // Confidence indicator
            Circle()
                .fill(Color.fromModelColorName(page.confidence.colorName))
                .frame(width: DesignSystem.small, height: DesignSystem.small)
        }
        .padding(.vertical, DesignSystem.tiny)
        .overlay {
            if page.isPrivate && store.isPrivacyModeEnabled {
                Color.appBackground.opacity(0.01)
            }
        }
    }
}
