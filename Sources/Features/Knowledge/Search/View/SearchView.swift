//
//  SearchView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：构建 Search 界面的 UI 视图层组件。
//
import SwiftUI

struct SearchView: View {
    @Environment(KnowledgeStore.self) var store
    @Environment(SearchStore.self) var searchStore
    @Environment(Router.self) var router
    // 初始值 (由外部传入)
    let initialQuery: String?
    let initialFilterType: PageType?
    
    @State private var searchText = ""
    @State private var filterType: PageType?
    @State private var filterStatus: PageStatus?
    @State private var sortBy: SortOption = .updated
    @EnvironmentObject var themeManager: ThemeManager
    @State private var previewPage: KnowledgePage?
    @State private var advancedResults: [KnowledgePage] = []
    @State private var useAdvancedSearch = false
    @State private var showDiagnostics = false
    
    init(initialQuery: String? = nil, initialFilterType: PageType? = nil) {
        self.initialQuery = initialQuery
        self.initialFilterType = initialFilterType
        // 注意：SwiftUI @State 在 init 中只能通过 _ 赋值，但通常我们在 onAppear 中应用初始值更稳妥，
        // 或者在此处直接初始化 _searchText。
        self._searchText = State(initialValue: initialQuery ?? "")
        self._filterType = State(initialValue: initialFilterType)
    }
    
    enum SortOption: String, CaseIterable {
        case updated = "search.sort.recentlyUpdated"
        case created = "search.sort.recentlyCreated"
        case title = "search.sort.title"
        case type = "search.sort.type"
    }
    
    var filteredPages: [KnowledgePage] {
        if useAdvancedSearch && !advancedResults.isEmpty {
            return advancedResults
        }
        
        var result = store.pages
        
        // Text search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { page in
                page.title.lowercased().contains(query) ||
                page.content.lowercased().contains(query) ||
                page.tags.contains(where: { $0.lowercased().contains(query) }) ||
                page.aliases.contains(where: { $0.lowercased().contains(query) })
            }
        }
        
        // Type filter
        if let type = filterType {
            result = result.filter { $0.pageType == type }
        }
        
        // Status filter
        if let status = filterStatus {
            result = result.filter { $0.status == status }
        }
        
        // Sort
        switch sortBy {
        case .updated:
            result.sort { $0.updatedAt > $1.updatedAt }
        case .created:
            result.sort { $0.createdAt > $1.createdAt }
        case .title:
            result.sort { $0.title < $1.title }
        case .type:
            result.sort { $0.pageType.rawValue < $1.pageType.rawValue }
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Header (Bar + Filters)
            VStack(spacing: DesignSystem.medium) {
                // Unified Search Bar
            // 1. 现代风格搜索区域 (对齐图 3)
            HStack {
                Image(systemName: DesignSystem.Icons.search)
                    .font(.callout.weight(.bold))
                    .foregroundStyle(.appAccent)
                
                TextField(L10n.SearchPlaceholder, text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .accessibilityIdentifier("searchPlaceholder")
                    .submitLabel(.search)
                    .onSubmit {
                        if !searchText.isEmpty {
                            runAdvancedSearch()
                        }
                    }

                if !searchText.isEmpty {
                    Button(action: { 
                        searchText = ""
                        useAdvancedSearch = false
                        advancedResults = []
                    }) {
                        Image(systemName: DesignSystem.Icons.errorCircle)
                            .foregroundStyle(.appSecondary.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, DesignSystem.standardPadding)
            .padding(.vertical, DesignSystem.tightPadding + DesignSystem.atomic)
            .background(Color.appCard.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(.appAccent.opacity(0.25), lineWidth: 1)
            )
            .padding(.horizontal, DesignSystem.standardPadding)
            .padding(.vertical, DesignSystem.medium)
                
                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.small) {
                        FilterPill(title: L10n.Search.all, accessibilityIdentifier: "filter-all", isSelected: filterType == nil) {
                            HapticFeedback.shared.trigger(.selection)
                            filterType = nil
                        }

                        ForEach(PageType.allCases) { type in
                            FilterPill(
                                title: type.displayName,
                                icon: type.icon,
                                color: Color.fromModelColorName(type.colorName),
                                accessibilityIdentifier: "filter-\(type.rawValue)",
                                isSelected: filterType == type
                            ) {
                                HapticFeedback.shared.trigger(.selection)
                                filterType = type
                            }
                        }

                        Divider().frame(height: 24).background(Color.appBorder)

                        // Status Filters
                        #if !os(watchOS)
                        Menu {
                            Button(L10n.Common.all) { filterStatus = nil }
                            ForEach(PageStatus.allCases, id: \.self) { status in
                                Button(status.displayName) { filterStatus = status }
                            }
                        } label: {
                            HStack(spacing: DesignSystem.tiny) {
                                Image(systemName: DesignSystem.Icons.flag)
                                    .font(.caption)
                                Text(filterStatus?.displayName ?? L10n.Knowledge.Page.status)
                                    .font(.caption)
                            }
                            .padding(.horizontal, DesignSystem.tightPadding + DesignSystem.atomic) // 10
                            .padding(.vertical, DesignSystem.tiny + DesignSystem.atomic) // 5
                            .background(filterStatusBackgroundColor)
                            .clipShape(Capsule())
                            .foregroundStyle(filterStatusLabelColor)
                        }
                        .buttonStyle(.plain)
                        #endif

                        Divider().frame(height: 24).background(Color.appBorder)

                        // Sort options
                        #if !os(watchOS)
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(action: { sortBy = option }) {
                                    Label(L10n.Common.tr(option.rawValue), systemImage: sortBy == option ? DesignSystem.Icons.check : "")
                                }
                            }
                        } label: {
                            HStack(spacing: DesignSystem.tiny) {
                                Image(systemName: DesignSystem.Icons.sortUpDown)
                                    .font(.caption)
                                Text(L10n.Common.tr(sortBy.rawValue))
                                    .font(.caption)
                            }
                            .padding(.horizontal, DesignSystem.tightPadding + DesignSystem.atomic) // 10
                            .padding(.vertical, DesignSystem.tiny + DesignSystem.atomic) // 5
                            .background(Color.appCard.opacity(0.8))
                            .clipShape(Capsule())
                            .foregroundStyle(.appSecondary)
                        }
                        .buttonStyle(.plain)
                        #endif
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, DesignSystem.medium)
            .background(Color.appBackground.opacity(0.4))
            .background(.ultraThinMaterial)
            
            // Main Results Content
            ZStack {
                if searchStore.isSearching {
                    VStack(spacing: DesignSystem.standardPadding) {
                        ForEach(0..<6) { _ in
                            HStack(spacing: DesignSystem.medium) {
                                AppSkeleton(width: DesignSystem.Sidebar.iconBoxSize, height: DesignSystem.Sidebar.iconBoxSize) // 44
                                VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                                    AppSkeleton(width: 140, height: DesignSystem.standardFontSize)
                                    AppSkeleton(width: 240, height: DesignSystem.microFontSize)
                                }

                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        Spacer()
                    }
                    .padding(.top, DesignSystem.Action.iconSize) // 20
                } else if filteredPages.isEmpty {
                    VStack(spacing: DesignSystem.standardPadding) {
                        Spacer()
                        Image(systemName: searchText.isEmpty ? DesignSystem.Icons.search : DesignSystem.Icons.weeklyInsight)
                            .font(.system(size: DesignSystem.Metrics.heroValueSize * 1.5)) // 48
                            .foregroundStyle(.appSecondary.opacity(DesignSystem.secondaryOpacity * 0.625)) // 0.5
                        
                        Text(searchText.isEmpty ? L10n.SearchPlaceholder : L10n.Search.noResults)
                            .font(.headline)
                            .foregroundStyle(.appSecondary)
                        
                        if !searchText.isEmpty {
                            Text(L10n.Search.noResultsHint)
                                .font(.caption)
                                .foregroundStyle(.appSecondary.opacity(DesignSystem.secondaryOpacity * 0.875)) // 0.7
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, DesignSystem.huge)
                        }
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredPages) { page in
                            Button(action: {
                                HapticFeedback.shared.trigger(.selection)
                                router.navigate(to: .pageDetail(id: page.id))
                            }) {
                                PageRowView(page: page)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            #if !os(watchOS)
                            .listRowSeparator(.hidden)
                            #endif
                            .contextMenu {
                                Button {
                                    HapticFeedback.shared.trigger(.selection)
                                    previewPage = page
                                } label: {
                                    Label(L10n.Common.quickPreview, systemImage: DesignSystem.Icons.eye)
                                }
                                
                                Button {
                                    AppPasteboard.string = "[[\(page.title)]]"
                                } label: {
                                    Label(L10n.Common.copyPageLink, systemImage: "link")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .animation(.default, value: searchStore.isSearching)
            .animation(.default, value: filteredPages.isEmpty)
            
            // Footer
            if !filteredPages.isEmpty {
                Divider().background(Color.appBorder.opacity(DesignSystem.secondaryOpacity * 0.625)) // 0.5
                HStack {
                    Text(L10n.Search.pagesCount(filteredPages.count))
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                    
                    if useAdvancedSearch {
                        Spacer()
                        Button(action: { showDiagnostics = true }) {
                            Label(L10n.Search.Diagnostics, systemImage: DesignSystem.Icons.info)
                                .font(.caption2)
                                .foregroundStyle(.appAccent)
                        }
                    } else {
                        Spacer()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, DesignSystem.tightPadding + DesignSystem.atomic) // 10
                .background(themeManager.pageBackground())
            }
        }
        .appTabToolbar(title: L10n.Search.title)
        .background(themeManager.pageBackground())
        .sheet(item: $previewPage) { page in
            PagePreviewSheet(page: page)
        }
        .sheet(isPresented: $showDiagnostics) {
            if let diag = searchStore.lastSearchDiagnostic {
                SearchDiagnosticSheet(info: diag)
            }
        }
    }
    
    private func runAdvancedSearch() {
        if useAdvancedSearch {
            withAnimation {
                useAdvancedSearch = false
                advancedResults = []
                searchStore.clearAll()
            }
            return
        }
        
        HapticFeedback.shared.trigger(.selection)
        Task {
            // 注意：SearchStore 内部已经处理了 isSearching 状态
            let results = await searchStore.performAdvancedSearch(query: searchText)
            await MainActor.run {
                withAnimation {
                    self.advancedResults = results
                    self.useAdvancedSearch = true
                }
            }
        }
    }
    
    private var filterStatusLabelColor: Color {
        filterStatus == nil ? .appSecondary : .appAccent
    }
    
    private var filterStatusBackgroundColor: Color {
        filterStatus == nil ? Color.appCard.opacity(0.8) : Color.appAccent.opacity(DesignSystem.glassOpacity / 1.5)
    }
}

// MARK: - Quick Preview Sheet
struct PagePreviewSheet: View {
    let page: KnowledgePage
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.standardPadding) {
                    HStack {
                        AppIconChip(icon: page.pageType.icon, text: page.pageType.displayName, color: Color.fromModelColorName(page.pageType.colorName), isSelected: true)
                        Spacer()
                Text(page.updatedAt.formatted(Date.FormatStyle(date: .numeric, time: .omitted, locale: Localized.currentLocale)))
                            .font(.caption)
                            .foregroundStyle(.appSecondary)
                    }
                    
                    Text(page.title)
                        .font(.title2.bold())
                        .foregroundStyle(.appText)
                    
                    Divider()
                    
                    Text(page.content)
                        .font(.subheadline)
                        .foregroundStyle(.appText)
                        .lineLimit(20)
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(themeManager.pageBackground())
            .navigationTitle(L10n.Common.preview)
.appNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(L10n.Common.close) { dismiss() }
                        .buttonStyle(.plain)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    var icon: String? = nil
    var color: Color = .appAccent
    var accessibilityIdentifier: String? = nil
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// 大屏幕下使用 body 字体（约 17pt），小屏幕用 subheadline（约 15pt）
    private var pillFont: Font {
        horizontalSizeClass == .regular ? .body : .subheadline
    }

    var body: some View {
        HStack(spacing: DesignSystem.tiny + DesignSystem.atomic) { // 6
            if let icon = icon {
                Image(systemName: icon)
                    .font(horizontalSizeClass == .regular ? .subheadline : .caption)
            }
            Text(title)
                .font(pillFont.weight(isSelected ? .semibold : .regular))
        }
        .padding(.horizontal, DesignSystem.Chip.horizontalPadding)
        .padding(.vertical, DesignSystem.Chip.verticalPadding + DesignSystem.atomic) // 6
        .background(isSelected ? color.opacity(0.12) : Color.appCard.opacity(0.6))
        .clipShape(Capsule())
        .foregroundStyle(isSelected ? color : .appSecondary)
        .contentShape(Capsule())
        .onTapGesture(perform: action)
        .accessibilityIdentifier(accessibilityIdentifier ?? title)
    }
}

// MARK: - Search Diagnostic Sheet
struct SearchDiagnosticSheet: View {
    let info: SearchDiagnosticInfo
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(L10n.Search.Diag.rewrite) {
                    VStack(alignment: .leading, spacing: DesignSystem.small) {
                        LabeledContent(L10n.Search.Diag.originalQuery, value: info.query)
                        LabeledContent(L10n.Search.Diag.rewrittenQuery, value: info.rewrittenQuery)
                            .foregroundStyle(.purple)
                    }
                    .font(.subheadline)
                }
                
                Section(L10n.Search.Diag.rrfDetail) {
                    ForEach(info.rrfTopResults) { res in
                        VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                            Text(res.title)
                                .font(.headline)
                            
                            HStack {
                                SearchBadgeView(label: "\(L10n.Search.Diag.ftsRank): \(res.ftsRank > 0 ? "\(res.ftsRank)" : L10n.Search.Diag.miss)", color: res.ftsRank > 0 ? .blue : .gray)
                                SearchBadgeView(label: "\(L10n.Search.Diag.vectorRank): \(res.vectorRank > 0 ? "\(res.vectorRank)" : L10n.Search.Diag.miss)", color: res.vectorRank > 0 ? .green : .gray)
                                Spacer()
                                Text(String(format: L10n.Search.Diag.scoreFormat, res.finalScore))
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.appSecondary)
                            }
                        }
                        .padding(.vertical, DesignSystem.tiny)
                    }
                }
            }
            .navigationTitle(L10n.Search.Diag.title)
.appNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(L10n.Common.close) { dismiss() }
                        .buttonStyle(.plain)
                }
            }
        }
    }
}

struct SearchBadgeView: View {
    let label: String
    let color: Color
    var body: some View {
        Text(label)
            .font(.system(size: DesignSystem.microFontSize - DesignSystem.atomic, weight: .bold)) // 9
            .padding(.horizontal, DesignSystem.tiny + DesignSystem.atomic) // 6
            .padding(.vertical, DesignSystem.atomic * 2) // 2
            .background(color.opacity(DesignSystem.glassOpacity / 1.5)) // 0.1
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
