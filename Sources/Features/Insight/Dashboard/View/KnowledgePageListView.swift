// KnowledgePageListView.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：知识库索引视图，支持按类型过滤、全量列表展示及核心统计。
// 核心原则：
// 1. 模式化布局：遵循 DesignSystem.List, DesignSystem.Sidebar 及 DesignSystem.Chip 规范。
// 2. 治理标准化：使用 DesignSystem.Icons 统一图标，Color.app* 统一配色。
// 修改记录:
//   - 2026-05-07: 工业级 UI 治理重构，消除魔鬼数字与硬编码图标。

import SwiftUI

// MARK: - Index View (entry point with NavigationStack)
@MainActor
struct KnowledgePageListView: View {
    var filterType: PageType? = nil
    var body: some View {
        KnowledgePageListContent(filterType: filterType)
    }
}

// MARK: - Knowledge Page List Content (for use inside parent NavigationStack)
@MainActor
struct KnowledgePageListContent: View {
    @Environment(AppStore.self) var store
    @EnvironmentObject var themeManager: ThemeManager
    var filterType: PageType? = nil
    
    @State private var showDeleteConfirmation = false
    @State private var pageToDelete: KnowledgePage?
    @State private var showInsights = false
    @State private var searchText = ""
    
    // 全局混合搜索与语义检索核心状态
    @State private var searchResults: [KnowledgePage] = []
    @State private var isSearchingAdvanced = false
    @State private var searchTask: Task<Void, Never>? = nil
    
    private var totalLinks: Int {
        store.pages.reduce(0) { $0 + $1.outgoingLinks.count }
    }
    
    private func filteredPages(for type: PageType) -> [KnowledgePage] {
        if isSearchingAdvanced {
            // 如果处于高级全文搜索模式下，直接按 SearchStore 算出的 RRF 混合排名的权重顺序输出过滤列表，不进行强制字典序重排
            return searchResults.filter { $0.pageType == type }
        }
        
        // 否则回退为原本的笔记本页面全量字典序排序
        return store.pages.filter { $0.pageType == type }.sorted { $0.title < $1.title }
    }
    
    private var hasSearchResults: Bool {
        if searchText.isEmpty { return true }
        if let filterType {
            return !filteredPages(for: filterType).isEmpty
        }
        return PageType.allCases.contains { type in
            !filteredPages(for: type).isEmpty
        }
    }

    private func triggerSearch(query: String) {
        searchTask?.cancel()
        
        let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedQuery.isEmpty else {
            withAnimation(.easeInOut) {
                searchResults = []
                isSearchingAdvanced = false
            }
            return
        }
        
        searchTask = Task {
            // 防抖 150ms 确连贯输入体验与节省 SQLite 核心物理 FTS5 开销
            try? await Task.sleep(for: .milliseconds(150))
            if Task.isCancelled { return }
            
            let results = await store.searchStore.performAdvancedSearch(query: cleanedQuery)
            if Task.isCancelled { return }
            
            await MainActor.run {
                withAnimation(.easeInOut) {
                    self.searchResults = results
                    self.isSearchingAdvanced = true
                }
            }
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            // 1. 方案 D 沉浸式高级背景 (同步 Hub 设计语言)
            ZStack {
                // 1. 底层：通透感深色背景
                themeManager.pageBackground().opacity(DesignSystem.translucentOpacity)
                
                MeshGradientView()
                    .blur(radius: DesignSystem.Gallery.blurRadius)
            }
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: DesignSystem.loosePadding) {
                    listView
                }
            }
            .scrollIndicators(.hidden)
            
        }
        .navigationTitle(filterType?.displayName ?? L10n.Common.Sidebar.pageList)
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
                    Image(systemName: DesignSystem.Icons.back)
                        .font(.system(size: DesignSystem.bodyFontSize, weight: .bold))
                        .foregroundStyle(.appText)
                        .frame(width: DesignSystem.CompositeRow.iconBoxSize, height: DesignSystem.Action.buttonHeight)
                }
                .buttonStyle(.plain)
            }
        }
        .onChange(of: searchText) { _, newValue in
            triggerSearch(query: newValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("toggleDisplayMode"))) { _ in
            // 响应全局模式切换（如果需要）
            HapticFeedback.shared.trigger(.selection)
        }
        .sheet(isPresented: $showInsights) {
            VaultInsightsPanel()
        }
        .confirmationDialog(
            pageToDelete.map { L10n.Vault.Page.deletePageTitle( $0.title) } ?? L10n.Knowledge.Page.deletePage,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.Knowledge.Page.deletePage, role: .destructive) {
                if let page = pageToDelete {
                    Task { await store.deletePage(page) }
                    HapticFeedback.shared.trigger(.success)
                }
            }
            Button(L10n.Common.cancel, role: .cancel) {
                pageToDelete = nil
            }
        } message: {
            Text(L10n.Settings.clearAll.message)
        }
    }
    
    @ViewBuilder
    private var listView: some View {
        LazyVStack(spacing: DesignSystem.standardPadding, pinnedViews: [.sectionHeaders]) {
            // 全局统一的高级毛玻璃搜索输入卡片，完美融合于顶端！
            searchBarSection
            
            if filterType == nil && searchText.isEmpty {
                summarySection
            }

            if store.searchStore.isSearching {
                // 如果正在执行混合检索，展示高精度骨架屏呼吸卡片
                VStack(spacing: DesignSystem.standardPadding) {
                    ForEach(0..<4) { _ in
                        HStack(spacing: DesignSystem.medium) {
                            AppSkeleton(width: DesignSystem.Sidebar.iconBoxSize, height: DesignSystem.Sidebar.iconBoxSize)
                            VStack(alignment: .leading, spacing: 4) {
                                AppSkeleton(width: 140, height: DesignSystem.standardFontSize)
                                AppSkeleton(width: 240, height: DesignSystem.microFontSize)
                            }
                            Spacer()
                        }
                    }
                    .padding(.top, 20)
                }
            } else if hasSearchResults {
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
            } else {
                VStack(spacing: DesignSystem.standardPadding) {
                    Spacer(minLength: 60)
                    Image(systemName: DesignSystem.Icons.weeklyInsight)
                        .font(.system(size: DesignSystem.Metrics.heroValueSize * 1.5))
                        .foregroundStyle(.appSecondary.opacity(DesignSystem.secondaryOpacity * 0.625))
                    
                    Text(L10n.Search.noResults)
                        .font(.headline)
                        .foregroundStyle(.appSecondary)
                    
                    Text(L10n.Search.noResultsHint)
                        .font(.caption)
                        .foregroundStyle(.appSecondary.opacity(DesignSystem.secondaryOpacity * 0.875))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.huge)
                    Spacer()
                }
                .padding(.top, 40)
            }
        }
        .padding(.horizontal, DesignSystem.standardPadding)
        .padding(.vertical, DesignSystem.loosePadding)
        .padding(.bottom, DesignSystem.standardPadding * 2)
    }
    
    @ViewBuilder
    private var summarySection: some View {
        Section {
            HStack(spacing: DesignSystem.standardPadding) {
                KnowledgeStatItem(label: L10n.Dashboard.totalPages, value: "\(store.pages.count)", color: .appAccent)
                KnowledgeStatItem(label: L10n.Dashboard.totalLinks, value: "\(totalLinks)", color: .appSource)
                KnowledgeStatItem(label: L10n.Dashboard.pageList.tags, value: "\(store.tags.count)", color: .appConcept)
                KnowledgeStatItem(label: L10n.Dashboard.pageList.sources, value: "\(store.sourceCount)", color: .appSource)
            }
            .padding(.horizontal, DesignSystem.tiny)
            .padding(.vertical, DesignSystem.tiny)
        } header: {
            HStack {
                Text(L10n.Dashboard.pageList.overview)
                    .font(.subheadline.bold())
                    .foregroundStyle(.appSecondary)
                Spacer()
            }
            .padding(.vertical, DesignSystem.tiny)
        }
    }
    
    @ViewBuilder
    private var entitySection: some View {
        let entities = filteredPages(for: .entity)
        if !entities.isEmpty {
            Section {
                VStack(spacing: 12) {
                    ForEach(entities) { page in
                        NavigationLink(value: AppRoute.pageDetail(id: page.id)) {
                            PageRowView(page: page)
                        }
                        .buttonStyle(AppPressButtonStyle())
                    }
                }
            } header: {
                HStack {
                    Label(L10n.Dashboard.pageList.entityCount(entities.count), systemImage: DesignSystem.Icons.entity)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appEntity)
                    Spacer()
                }
                .padding(.vertical, DesignSystem.tiny)
            }
        }
    }
    
    @ViewBuilder
    private var conceptSection: some View {
        let concepts = filteredPages(for: .concept)
        if !concepts.isEmpty {
            Section {
                VStack(spacing: 12) {
                    ForEach(concepts) { page in
                        NavigationLink(value: AppRoute.pageDetail(id: page.id)) {
                            PageRowView(page: page)
                        }
                        .buttonStyle(AppPressButtonStyle())
                    }
                }
            } header: {
                HStack {
                    Label(L10n.Dashboard.pageList.conceptCount(concepts.count), systemImage: DesignSystem.Icons.concept)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appConcept)
                    Spacer()
                }
                .padding(.vertical, DesignSystem.tiny)
            }
        }
    }
    
    @ViewBuilder
    private var sourceSection: some View {
        let sources = filteredPages(for: .source)
        if !sources.isEmpty {
            Section {
                VStack(spacing: 12) {
                    ForEach(sources) { page in
                        NavigationLink(value: AppRoute.pageDetail(id: page.id)) {
                            PageRowView(page: page)
                        }
                        .buttonStyle(AppPressButtonStyle())
                    }
                }
            } header: {
                HStack {
                    Label(L10n.Dashboard.pageList.sourceCount(sources.count), systemImage: DesignSystem.Icons.source)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appSource)
                    Spacer()
                }
                .padding(.vertical, DesignSystem.tiny)
            }
        }
    }
    
    @ViewBuilder
    private var comparisonSection: some View {
        let comparisons = filteredPages(for: .comparison)
        if !comparisons.isEmpty {
            Section {
                VStack(spacing: 12) {
                    ForEach(comparisons) { page in
                        NavigationLink(value: AppRoute.pageDetail(id: page.id)) {
                            PageRowView(page: page)
                        }
                        .buttonStyle(AppPressButtonStyle())
                    }
                }
            } header: {
                HStack {
                    Label(L10n.Dashboard.pageList.comparisonCount(comparisons.count), systemImage: DesignSystem.Icons.comparison)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appComparison)
                    Spacer()
                }
                .padding(.vertical, DesignSystem.tiny)
            }
        }
    }
    
    @ViewBuilder
    private var searchBarSection: some View {
        HStack(spacing: DesignSystem.medium) {
            Image(systemName: DesignSystem.Icons.search)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.appAccent)
            
            TextField(L10n.SearchPlaceholder, text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .foregroundStyle(.appText)
                .accessibilityIdentifier("searchPlaceholder")
                .submitLabel(.search)
                .onSubmit {
                    if !searchText.isEmpty {
                        triggerSearch(query: searchText)
                    }
                }

            if !searchText.isEmpty {
                Button(action: { 
                    searchText = ""
                    triggerSearch(query: "")
                }) {
                    Image(systemName: DesignSystem.Icons.errorCircle)
                        .foregroundStyle(.appSecondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DesignSystem.standardPadding)
        .padding(.vertical, DesignSystem.tightPadding + DesignSystem.atomic)
        .background(Color.appCard.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.appAccent.opacity(0.25), lineWidth: DesignSystem.borderWidth)
        )
        .padding(.horizontal, DesignSystem.tiny)
        .padding(.bottom, DesignSystem.tiny)
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
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.appSecondary)
                .textCase(.uppercase)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.appCard.opacity(0.8))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cardRadius)
                .stroke(.white.opacity(DesignSystem.accentStrokeOpacity), lineWidth: DesignSystem.borderWidth / 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
        .shadow(color: .black.opacity(DesignSystem.shadowOpacity), radius: DesignSystem.small, x: 0, y: DesignSystem.tiny)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cardRadius)
                .stroke(color.opacity(DesignSystem.dimmedOpacity), lineWidth: DesignSystem.borderWidth)
        )
        .shadow(color: Color.black.opacity(DesignSystem.shadowOpacity * DesignSystem.subtleOpacity), radius: DesignSystem.medium, x: 0, y: DesignSystem.tiny)
    }
}

// MARK: - App Press Button Style
struct AppPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? DesignSystem.Action.pressScale : 1.0)
            .opacity(configuration.isPressed ? DesignSystem.pressedOpacity : 1.0)
            .animation(.spring(response: DesignSystem.Animation.springResponse, dampingFraction: DesignSystem.Animation.springDamping), value: configuration.isPressed)
    }
}
