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
    
    private var totalLinks: Int {
        store.pages.reduce(0) { $0 + $1.outgoingLinks.count }
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
                        .font(.system(size: DesignSystem.bodyFontSize, weight: .bold))
                        .foregroundStyle(.appText)
                        .frame(width: DesignSystem.CompositeRow.iconBoxSize, height: DesignSystem.Action.buttonHeight)
                }
                .buttonStyle(.plain)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { 
                    HapticFeedback.shared.trigger(.selection)
                    Router.shared.navigate(to: .search()) 
                }) {
                    Image(systemName: DesignSystem.Icons.hashtag)
                        .font(.system(size: DesignSystem.headlineFontSize))
                        .foregroundStyle(.appSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("toggleDisplayMode"))) { _ in
            // 响应全局模式切换（如果需要）
            HapticFeedback.shared.trigger(.selection)
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
                    Task { await store.deletePage(page) }
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
        .padding(.horizontal, DesignSystem.standardPadding)
        .padding(.vertical, DesignSystem.loosePadding)
        .padding(.bottom, DesignSystem.standardPadding * 2)
    }

    // GridView 已被用户要求移除以支持更充实的内容列表
    
    @ViewBuilder
    private var summarySection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.standardPadding) {
                    KnowledgeStatItem(label: L10n.Dashboard.tr("totalPages"), value: "\(store.pages.count)", color: .appAccent)
                    KnowledgeStatItem(label: L10n.Dashboard.tr("totalLinks"), value: "\(totalLinks)", color: .appSource)
                    KnowledgeStatItem(label: L10n.Dashboard.tr("pageList.tags"), value: "\(store.tags.count)", color: .appConcept)
                    KnowledgeStatItem(label: L10n.Dashboard.tr("pageList.sources"), value: "\(store.sourceCount)", color: .appSource)
                }
                .padding(.horizontal, DesignSystem.tiny)
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
        }
    }
    
    @ViewBuilder
    private var entitySection: some View {
        let entities = store.pages.filter { $0.pageType == .entity }.sorted { $0.title < $1.title }
        if !entities.isEmpty {
            Section {
                ForEach(entities) { page in
                    NavigationLink(value: AppRoute.pageDetail(id: page.id)) {
                        KnowledgePageModernRow(page: page)
                    }
                    .buttonStyle(AppPressButtonStyle())
                    
                    if page.id != entities.last?.id {
                        Divider()
                            .padding(.vertical, DesignSystem.tiny)
                    }
                }
            } header: {
                HStack {
                    Label(Localized.trf("pageList.entityCount", entities.count), systemImage: DesignSystem.Icons.entity)
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
        let concepts = store.pages.filter { $0.pageType == .concept }.sorted { $0.title < $1.title }
        if !concepts.isEmpty {
            Section {
                ForEach(concepts) { page in
                    NavigationLink(value: AppRoute.pageDetail(id: page.id)) {
                        KnowledgePageModernRow(page: page)
                    }
                    .buttonStyle(AppPressButtonStyle())
                    
                    if page.id != concepts.last?.id {
                        Divider()
                            .padding(.vertical, DesignSystem.tiny)
                    }
                }
            } header: {
                HStack {
                    Label(Localized.trf("pageList.conceptCount", concepts.count), systemImage: DesignSystem.Icons.concept)
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
        let sources = store.pages.filter { $0.pageType == .source }.sorted { $0.title < $1.title }
        if !sources.isEmpty {
            Section {
                ForEach(sources) { page in
                    NavigationLink(value: AppRoute.pageDetail(id: page.id)) {
                        KnowledgePageModernRow(page: page)
                    }
                    .buttonStyle(AppPressButtonStyle())
                    
                    if page.id != sources.last?.id {
                        Divider()
                            .padding(.vertical, DesignSystem.tiny)
                    }
                }
            } header: {
                HStack {
                    Label(Localized.trf("pageList.sourceCount", sources.count), systemImage: DesignSystem.Icons.source)
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
        let comparisons = store.pages.filter { $0.pageType == .comparison }.sorted { $0.title < $1.title }
        if !comparisons.isEmpty {
            Section {
                ForEach(comparisons) { page in
                    NavigationLink(value: AppRoute.pageDetail(id: page.id)) {
                        KnowledgePageModernRow(page: page)
                    }
                    .buttonStyle(AppPressButtonStyle())
                    
                    if page.id != comparisons.last?.id {
                        Divider()
                            .padding(.vertical, DesignSystem.tiny)
                    }
                }
            } header: {
                HStack {
                    Label(Localized.trf("pageList.comparisonCount", comparisons.count), systemImage: DesignSystem.Icons.comparison)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appComparison)
                    Spacer()
                }
                .padding(.vertical, DesignSystem.tiny)
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

// MARK: - Knowledge Page Modern Row (高密度内容流)
struct KnowledgePageModernRow: View {
    let page: KnowledgePage
    @Environment(AppStore.self) var store

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            HStack(alignment: .top, spacing: DesignSystem.medium) {
                // 1. 紧凑型图标
                Image(systemName: page.displayIcon)
                    .font(.system(size: DesignSystem.subheadlineFontSize, weight: .bold))
                    .foregroundStyle(Color.fromModelColorName(page.pageType.colorName))
                    .frame(width: DesignSystem.CompositeRow.iconBoxSize, height: DesignSystem.CompositeRow.iconBoxSize)
                    .background(Color.fromModelColorName(page.pageType.colorName).opacity(DesignSystem.surfaceOpacity))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.small, style: .continuous))
                
                VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                    // 2. 标题与状态
                    HStack(spacing: DesignSystem.tiny) {
                        Text(page.title)
                            .font(.system(size: DesignSystem.headlineFontSize - 1, weight: .bold)) // 17px
                            .foregroundStyle(.appText)
                            .lineLimit(1)
                        
                        if page.isPinned {
                            Image(systemName: DesignSystem.Icons.pin)
                                .font(.system(size: DesignSystem.microFontSize))
                                .foregroundStyle(.appAccent)
                                .rotationEffect(.degrees(45))
                        }
                        
                        Spacer()
                        
                        // 信心度小点
                        Circle()
                            .fill(Color.fromModelColorName(page.confidence.colorName))
                            .frame(width: DesignSystem.small / 2, height: DesignSystem.small / 2)
                    }
                    
                    // 3. 内容摘要 (充实感核心)
                    Text(page.content)
                        .font(.system(size: DesignSystem.subheadlineFontSize))
                        .foregroundStyle(.appSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .padding(.top, DesignSystem.atomic)
                }
            }
            
            // 4. 元数据底部栏 (可读性增强)
            HStack(spacing: DesignSystem.medium) {
                metadataItem(icon: DesignSystem.Icons.history, text: page.updatedAt.timeAgoDisplay())
                metadataItem(icon: "text.alignleft", text: Localized.trf("pageList.wordCount", page.wordCount))
                
                if !page.outgoingLinks.isEmpty {
                    metadataItem(icon: DesignSystem.Icons.link, text: "\(page.outgoingLinks.count)")
                }
                
                Spacer()
                
                // 标签序列 (截断处理)
                if !page.tags.isEmpty {
                    HStack(spacing: DesignSystem.tiny) {
                        ForEach(page.tags.prefix(2), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: DesignSystem.microFontSize, weight: .medium))
                                .padding(.horizontal, DesignSystem.small)
                                .padding(.vertical, DesignSystem.tiny / 2)
                                .background(Color.appAccent.opacity(DesignSystem.ghostOpacity))
                                .foregroundStyle(.appAccent)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.top, DesignSystem.tiny)
        }
        .padding(.vertical, DesignSystem.medium)
        .contentShape(Rectangle())
    }
    
    private func metadataItem(icon: String, text: String) -> some View {
        HStack(spacing: DesignSystem.tiny) {
            Image(systemName: icon)
                .font(.system(size: DesignSystem.microFontSize))
            Text(text)
                .font(.system(size: DesignSystem.caption2FontSize, weight: .medium))
        }
        .foregroundStyle(.appSecondary.opacity(DesignSystem.secondaryOpacity))
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
