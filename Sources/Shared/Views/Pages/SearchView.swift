// SearchView.swift
//
// 作者: Wang Chong
// 功能说明: struct SearchView
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
//   - 更新: 2026-05-03
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

struct SearchView: View {
    @Environment(AppStore.self) var store
    @Environment(SearchStore.self) var searchStore
    @Environment(AppRouter.self) var router
    @State private var searchText = ""
    @State private var filterType: PageType?
    @State private var filterStatus: PageStatus?
    @State private var sortBy: SortOption = .updated
    @EnvironmentObject var themeManager: ThemeManager
    @State private var previewPage: KnowledgePage?
    @State private var advancedResults: [KnowledgePage] = []
    @State private var useAdvancedSearch = false
    @State private var showDiagnostics = false
    
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
            result = result.filter { $0.type == type }
        }
        
        // Status filter
        if let status = filterStatus {
            result = result.filter { $0.status == status }
        }
        
        // Sort
        switch sortBy {
        case .updated:
            result.sort { $0.updated > $1.updated }
        case .created:
            result.sort { $0.created > $1.created }
        case .title:
            result.sort { $0.title < $1.title }
        case .type:
            result.sort { $0.type.rawValue < $1.type.rawValue }
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Header (Bar + Filters)
            VStack(spacing: 12) {
                // Unified Search Bar
                HStack(spacing: 0) {
                    HStack(spacing: AppUI.tightPadding + AppUI.atomic) { // 10
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.appSecondary)
                        TextField(Localized.tr("search.placeholder"), text: $searchText)
                            .foregroundStyle(.appText)
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
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.appSecondary)
                            }
                            .padding(.trailing, AppUI.tiny)
                        }
                    }
                    .padding(.leading, AppUI.standardPadding - AppUI.atomic) // 14
                    .padding(.vertical, AppUI.tightPadding + AppUI.atomic) // 10
                    .background(Color.appCard.opacity(0.8))
                }
                .frame(height: AppUI.inputBarHeight)
                .clipShape(RoundedRectangle(cornerRadius: AppUI.mediumRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppUI.mediumRadius)
                        .stroke(Color.appBorder.opacity(AppUI.secondaryOpacity * 0.625), lineWidth: AppUI.borderWidth / 2) // 0.5
                )
                .padding(.horizontal)
                .animation(.spring(response: AppUI.Animation.springResponse, dampingFraction: AppUI.Animation.springDamping), value: searchText.isEmpty)
                
                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterPill(title: Localized.tr("search.all"), accessibilityIdentifier: "filter-all", isSelected: filterType == nil) {
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
                            Button(L10n.Common.tr("all")) { filterStatus = nil }
                            ForEach(PageStatus.allCases, id: \.self) { status in
                                Button(status.displayName) { filterStatus = status }
                            }
                        } label: {
                            HStack(spacing: AppUI.tiny) {
                                Image(systemName: "flag")
                                    .font(.caption)
                                Text(filterStatus?.displayName ?? Localized.tr("page.status"))
                                    .font(.caption)
                            }
                            .padding(.horizontal, AppUI.tightPadding + AppUI.atomic) // 10
                            .padding(.vertical, AppUI.tiny + AppUI.atomic) // 5
                            .background(filterStatus == nil ? Color.appCard.opacity(0.8) : Color.appAccent.opacity(AppUI.glassOpacity / 1.5)) // 0.1
                            .clipShape(Capsule())
                            .foregroundStyle(filterStatus == nil ? .appSecondary : .appAccent)
                        }
                        #endif

                        Divider().frame(height: 24).background(Color.appBorder)

                        // Sort options
                        #if !os(watchOS)
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(action: { sortBy = option }) {
                                    Label(Localized.tr(option.rawValue), systemImage: sortBy == option ? "checkmark" : "")
                                }
                            }
                        } label: {
                            HStack(spacing: AppUI.tiny) {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.caption)
                                Text(Localized.tr(sortBy.rawValue))
                                    .font(.caption)
                            }
                            .padding(.horizontal, AppUI.tightPadding + AppUI.atomic) // 10
                            .padding(.vertical, AppUI.tiny + AppUI.atomic) // 5
                            .background(Color.appCard.opacity(0.8))
                            .clipShape(Capsule())
                            .foregroundStyle(.appSecondary)
                        }
                        #endif
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 12)
            .background(Color.appBackground.opacity(0.4))
            .background(.ultraThinMaterial)
            
            // Main Results Content
            ZStack {
                if searchStore.isSearching {
                    VStack(spacing: AppUI.standardPadding) {
                        ForEach(0..<6) { _ in
                            HStack(spacing: AppUI.medium) {
                                SkeletonBox(width: AppUI.Sidebar.iconBoxSize, height: AppUI.Sidebar.iconBoxSize) // 44
                                VStack(alignment: .leading, spacing: AppUI.tightPadding) {
                                    SkeletonBox(width: 140, height: AppUI.standardFontSize)
                                    SkeletonBox(width: 240, height: AppUI.microFontSize)
                                }
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        Spacer()
                    }
                    .padding(.top, AppUI.Action.iconSize) // 20
                } else if filteredPages.isEmpty {
                    VStack(spacing: AppUI.standardPadding) {
                        Spacer()
                        Image(systemName: searchText.isEmpty ? "magnifyingglass" : "doc.text.magnifyingglass")
                            .font(.system(size: AppUI.Metrics.heroValueSize * 1.5)) // 48
                            .foregroundStyle(.appSecondary.opacity(AppUI.secondaryOpacity * 0.625)) // 0.5
                        
                        Text(searchText.isEmpty ? Localized.tr("search.placeholder") : Localized.tr("search.noResults"))
                            .font(.headline)
                            .foregroundStyle(.appSecondary)
                        
                        if !searchText.isEmpty {
                            Text(Localized.tr("search.noResultsHint"))
                                .font(.caption)
                                .foregroundStyle(.appSecondary.opacity(AppUI.secondaryOpacity * 0.875)) // 0.7
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppUI.huge)
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
                                    Label(L10n.Common.tr("quickPreview"), systemImage: "eye")
                                }
                                
                                Button {
                                    AppPasteboard.string = "[[\(page.title)]]"
                                } label: {
                                    Label(L10n.Common.tr("copyPageLink"), systemImage: "link")
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
                Divider().background(Color.appBorder.opacity(AppUI.secondaryOpacity * 0.625)) // 0.5
                HStack {
                    Text(Localized.trf("search.pagesCount", filteredPages.count))
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                    
                    if useAdvancedSearch {
                        Spacer()
                        Button(action: { showDiagnostics = true }) {
                            Label(Localized.tr("search.diagnostics"), systemImage: "info.circle")
                                .font(.caption2)
                                .foregroundStyle(.appAccent)
                        }
                    } else {
                        Spacer()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, AppUI.tightPadding + AppUI.atomic) // 10
                .background(themeManager.pageBackground())
            }
        }
        .navigationTitle(Localized.tr("search.title"))
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .toolbarBackground(.hidden, for: .navigationBar)
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
}

// MARK: - Quick Preview Sheet
struct PagePreviewSheet: View {
    let page: KnowledgePage
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        AppIconChip(icon: page.type.icon, text: page.type.displayName, color: Color.fromModelColorName(page.type.colorName), isSelected: true)
                        Spacer()
                Text(page.updated.formatted(Date.FormatStyle(date: .numeric, time: .omitted, locale: Localized.currentLocale)))
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
            .navigationTitle(L10n.Common.tr("preview"))
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(L10n.Common.tr("close")) { dismiss() }
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
        HStack(spacing: AppUI.tiny + AppUI.atomic) { // 6
            if let icon = icon {
                Image(systemName: icon)
                    .font(horizontalSizeClass == .regular ? .subheadline : .caption)
            }
            Text(title)
                .font(pillFont.weight(isSelected ? .semibold : .regular))
        }
        .padding(.horizontal, AppUI.standardPadding)
        .padding(.vertical, AppUI.tightPadding + AppUI.atomic) // 10
        .background(isSelected ? color.opacity(AppUI.glassOpacity * 1.66) : Color.appCard.opacity(0.8)) // 0.25
        .clipShape(Capsule())
        .foregroundStyle(isSelected ? color : .appSecondary)
        .overlay(
            Capsule()
                .stroke(isSelected ? color.opacity(AppUI.disabledOpacity + 0.1) : Color.clear, lineWidth: AppUI.borderWidth) // 0.4, 1
        )
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
                Section(Localized.tr("search.diag.rewrite")) {
                    VStack(alignment: .leading, spacing: 8) {
                        LabeledContent(Localized.tr("search.diag.originalQuery"), value: info.query)
                        LabeledContent(Localized.tr("search.diag.rewrittenQuery"), value: info.rewrittenQuery)
                            .foregroundStyle(.purple)
                    }
                    .font(.subheadline)
                }
                
                Section(Localized.tr("search.diag.rrfDetail")) {
                    ForEach(info.rrfTopResults) { res in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(res.title)
                                .font(.headline)
                            
                            HStack {
                                SearchBadgeView(label: "\(Localized.tr("search.diag.ftsRank")): \(res.ftsRank > 0 ? "\(res.ftsRank)" : Localized.tr("search.diag.miss"))", color: res.ftsRank > 0 ? .blue : .gray)
                                SearchBadgeView(label: "\(Localized.tr("search.diag.vectorRank")): \(res.vectorRank > 0 ? "\(res.vectorRank)" : Localized.tr("search.diag.miss"))", color: res.vectorRank > 0 ? .green : .gray)
                                Spacer()
                                Text(String(format: Localized.tr("search.diag.scoreFormat"), res.finalScore))
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.appSecondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(Localized.tr("search.diag.title"))
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(L10n.Common.tr("close")) { dismiss() }
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
            .font(.system(size: AppUI.microFontSize - AppUI.atomic, weight: .bold)) // 9
            .padding(.horizontal, AppUI.tiny + AppUI.atomic) // 6
            .padding(.vertical, AppUI.atomic * 2) // 2
            .background(color.opacity(AppUI.glassOpacity / 1.5)) // 0.1
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
