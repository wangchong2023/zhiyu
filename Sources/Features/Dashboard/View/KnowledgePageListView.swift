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
struct KnowledgePageListView: View {
    var filterType: PageType? = nil
    var body: some View {
        KnowledgePageListContent(filterType: filterType)
    }
}

// MARK: - Knowledge Page List Content (for use inside parent NavigationStack)
struct KnowledgePageListContent: View {
    @Environment(AppStore.self) var store
    @EnvironmentObject var themeManager: ThemeManager
    var filterType: PageType? = nil
    
    // 视图模式定义
    enum ViewMode: String, CaseIterable {
        case list, grid
        var icon: String { self == .list ? "square.grid.2x2" : "list.bullet" }
    }
    
    @AppStorage("app.pageList.viewMode") private var viewMode: ViewMode = .list
    @State private var showDeleteConfirmation = false
    @State private var pageToDelete: KnowledgePage?
    @State private var showInsights = false
    
    private var totalLinks: Int {
        store.pages.reduce(0) { $0 + $1.outgoingLinks.count }
    }

    var body: some View {
        ZStack(alignment: .top) {
            // 1. 方案 D 沉浸式高级背景 (同步 Hub 设计语言)
            ZStack {
                // 1. 底层：通透感深色背景
                themeManager.pageBackground().opacity(0.85)
                
                MeshGradientView()
                    .blur(radius: 80)
            }
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    if viewMode == .list {
                        listView
                    } else {
                        gridView
                    }
                }
            }
            .scrollIndicators(.hidden)
            
        }
        .navigationTitle(filterType?.displayName ?? Localized.tr("sidebar.pageList"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    HapticFeedback.shared.trigger(.selection)
                    Router.shared.pop()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.appText)
                        .frame(width: 32, height: 44)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { 
                    HapticFeedback.shared.trigger(.selection)
                    Router.shared.navigate(to: .search) 
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundStyle(.appSecondary)
                }
            }
        }
        .onAppear {
            NotificationCenter.default.addObserver(forName: NSNotification.Name("toggleDisplayMode"), object: nil, queue: .main) { @MainActor _ in
                HapticFeedback.shared.trigger(.selection)
                withAnimation(.spring()) {
                    viewMode = (viewMode == .list) ? .grid : .list
                }
            }
        }
        .sheet(isPresented: $showInsights) {
            VaultInsightsPanel()
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
    private var listView: some View {
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

    @ViewBuilder
    private var gridView: some View {
        let columns = [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: DesignSystem.Grid.standardSpacing)]
        let pages = filterType == nil ? store.pages : store.pages.filter { $0.type == filterType }
        
        LazyVGrid(columns: columns, spacing: DesignSystem.Grid.standardSpacing) {
            ForEach(pages) { page in
                NavigationLink(value: AppRoute.pageDetail(id: page.id)) {
                    VStack(alignment: .leading, spacing: DesignSystem.small) {
                        HStack {
                            Image(systemName: page.type.icon)
                                .foregroundStyle(Color.fromModelColorName(page.type.colorName))
                            Spacer()
                            Circle()
                                .fill(Color.fromModelColorName(page.confidence.colorName))
                                .frame(width: 8, height: 8)
                        }
                        
                        Text(page.title)
                            .font(.subheadline.bold())
                            .lineLimit(2)
                            .foregroundStyle(.appText)
                        
                        Text(page.content)
                            .font(.caption2)
                            .lineLimit(3)
                            .foregroundStyle(.appSecondary)
                    }
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.cardRadius)
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                    .padding(DesignSystem.small)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignSystem.huge)
    }
    
    @ViewBuilder
    private var summarySection: some View {
        Section {
            HStack(spacing: DesignSystem.Sidebar.rowSpacing) {
                KnowledgeStatItem(label: L10n.Dashboard.tr("totalPages"), value: "\(store.pages.count)", color: .appAccent)
                KnowledgeStatItem(label: L10n.Dashboard.tr("totalLinks"), value: "\(totalLinks)", color: .appSource)
                KnowledgeStatItem(label: L10n.Dashboard.tr("pageList.tags"), value: "\(store.tags.count)", color: .appConcept)
                KnowledgeStatItem(label: L10n.Dashboard.tr("pageList.sources"), value: "\(store.sourceCount)", color: .appSource)
            }
            .padding(.vertical, DesignSystem.tiny)
        } header: {
            HStack {
                Text(L10n.Dashboard.tr("pageList.overview"))
                    .font(.subheadline.bold())
                    .foregroundStyle(.appSecondary)
                Spacer()
            }
            .padding(.vertical, DesignSystem.tiny)
            .background(Color.appBackground.opacity(DesignSystem.ghostOpacity))
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
                            KnowledgePageRow(page: page)
                        }
                        .buttonStyle(.plain)
                        
                        if page.id != entities.last?.id {
                            Divider()
                                .padding(.leading, DesignSystem.Sidebar.iconBoxSize + DesignSystem.Sidebar.rowSpacing)
                        }
                    }
                }
                .appContainer(background: Color.appCard.opacity(DesignSystem.surfaceOpacity), padding: true)
            } header: {
                HStack {
                    Label(Localized.trf("pageList.entityCount", entities.count), systemImage: DesignSystem.Icons.entity)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appEntity)
                    Spacer()
                }
                .padding(.vertical, DesignSystem.tiny)
                .background(Color.appBackground.opacity(DesignSystem.ghostOpacity))
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
                            KnowledgePageRow(page: page)
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
                .appContainer(background: Color.appCard.opacity(DesignSystem.surfaceOpacity), padding: true)
            } header: {
                HStack {
                    Label(Localized.trf("pageList.conceptCount", concepts.count), systemImage: DesignSystem.Icons.concept)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appConcept)
                    Spacer()
                }
                .padding(.vertical, DesignSystem.tiny)
                .background(Color.appBackground.opacity(DesignSystem.ghostOpacity))
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
                            KnowledgePageRow(page: page)
                        }
                        .buttonStyle(.plain)
                        
                        if page.id != sources.last?.id {
                            Divider()
                                .padding(.leading, DesignSystem.Sidebar.iconBoxSize + DesignSystem.Sidebar.rowSpacing)
                        }
                    }
                }
                .appContainer(background: Color.appCard.opacity(DesignSystem.surfaceOpacity), padding: true)
            } header: {
                HStack {
                    Label(Localized.trf("pageList.sourceCount", sources.count), systemImage: DesignSystem.Icons.source)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appSource)
                    Spacer()
                }
                .padding(.vertical, DesignSystem.tiny)
                .background(Color.appBackground.opacity(DesignSystem.ghostOpacity))
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
                            KnowledgePageRow(page: page)
                        }
                        .buttonStyle(.plain)
                        
                        if page.id != comparisons.last?.id {
                            Divider()
                                .padding(.leading, DesignSystem.Sidebar.iconBoxSize + DesignSystem.Sidebar.rowSpacing)
                        }
                    }
                }
                .appContainer(background: Color.appCard.opacity(DesignSystem.surfaceOpacity), padding: true)
            } header: {
                HStack {
                    Label(Localized.trf("pageList.comparisonCount", comparisons.count), systemImage: DesignSystem.Icons.comparison)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appComparison)
                    Spacer()
                }
                .padding(.vertical, DesignSystem.tiny)
                .background(Color.appBackground.opacity(DesignSystem.ghostOpacity))
            }
        }
    }
}

// MARK: - Knowledge Stat Item
struct KnowledgeStatItem: View {
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
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cardRadius)
                .stroke(.white.opacity(0.15), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cardRadius)
                .stroke(color.opacity(DesignSystem.dimmedOpacity), lineWidth: DesignSystem.borderWidth)
        )
        .shadow(color: Color.black.opacity(DesignSystem.shadowOpacity * 0.25), radius: DesignSystem.medium, x: 0, y: DesignSystem.tiny)
    }
}

// MARK: - Knowledge Page Row
struct KnowledgePageRow: View {
    let page: KnowledgePage
    @Environment(AppStore.self) var store

    var body: some View {
        HStack(spacing: DesignSystem.Sidebar.rowSpacing) {
            Image(systemName: page.displayIcon)
                .foregroundStyle(Color.fromModelColorName(page.type.colorName))
                .frame(width: DesignSystem.Sidebar.iconBoxSize, height: DesignSystem.Sidebar.iconBoxSize)
                .background(Color.fromModelColorName(page.type.colorName).opacity(DesignSystem.glassOpacity))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.microRadius))

            VStack(alignment: .leading, spacing: DesignSystem.Sidebar.rowVerticalPadding) {
                Text(page.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.appText)
                    .lineLimit(1)
                    .blur(radius: (page.isPrivate && store.isPrivacyModeEnabled) ? DesignSystem.microRadius : 0)

                HStack(spacing: DesignSystem.Chip.iconSpacing + 2) {
                    Text(Localized.trf("pageList.wordCount", page.wordCount))
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

// MARK: - Knowledge List Toolbar
struct KnowledgeListToolbar: ViewModifier {
    let filterType: PageType?
    let store: AppStore
    @Binding var viewMode: KnowledgePageListContent.ViewMode
    
    func body(content: Content) -> some View {
        let title = filterType?.displayName ?? Localized.tr("sidebar.pageList")
        
        if filterType == nil {
            content.appTabToolbar(title: title) {
                HStack(spacing: DesignSystem.Action.buttonSpacing) {
                    viewModeButton
                    refreshButton
                }
            }
        } else {
            content.appSubPageToolbar(title: title) {
                HStack(spacing: DesignSystem.Action.buttonSpacing) {
                    viewModeButton
                    refreshButton
                }
            }
        }
    }
    
    private var viewModeButton: some View {
        Button {
            HapticFeedback.shared.trigger(.selection)
            withAnimation(.spring()) {
                viewMode = viewMode == .list ? .grid : .list
            }
        } label: {
            Image(systemName: viewMode.icon)
        }
    }
    
    private var refreshButton: some View {
        Button {
            HapticFeedback.shared.trigger(.selection)
            store.refresh()
        } label: {
            Label(L10n.Common.tr("refresh"), systemImage: DesignSystem.Icons.refresh)
        }
    }
}
