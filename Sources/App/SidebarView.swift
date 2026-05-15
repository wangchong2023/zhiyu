// SidebarView.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了知识管理系统的核心导航分发中心（SidebarView）。
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 侧边栏导航选中项定义
/// 用于追踪用户在 NavigationSplitView 侧边栏中的交互位置
enum SidebarSelection: Hashable {
    /// 跳转到特定的知识页面条目 (根据 UUID 唯一定位)
    case page(UUID)
    
    /// 跳转到系统预设的工具项 (如：仪表盘、页面列表、设置等)
    case tool(AppStore.ToolItem)
    
    /// 按特定 PageType 类型过滤后的知识列表 (如：仅查看实体或概念)
    case filteredIndex(PageType)
    
    /// 将当前的侧边栏选中项转换为具体的物理路由目标
    /// 这一映射过程解耦了侧边栏的 UI 交互状态与底层的视图分发逻辑。
    /// - Returns: 对应的 AppRoute 目标，可直接用于导航栈。
    func asRoute() -> AppRoute {
        switch self {
        case .page(let id): return .pageDetail(id: id)
        case .tool(let tool):
            switch tool {
            case .dashboard: return .dashboard
            case .pageList: return .pageList()
            case .lint: return .lint
            case .taskCenter: return .taskCenter
            case .tagCloud: return .tagCloud
            case .chat: return .chat
            case .synthesis: return .synthesis
            case .weeklyReport: return .weeklyReport
            case .log: return .log
            case .collab: return .collab
            case .pluginMarket: return .pluginMarket
            case .healthCheck: return .lint
            case .search: return .search
            case .ingest: return .ingest
            case .graph: return .graph
            }
        case .filteredIndex(let type): return .pageList(filterType: type)
        }
    }
}

// MARK: - Sidebar View
struct SidebarView: View {
    @Environment(AppStore.self) var store
    @Environment(VaultService.self) var vaultService
    @Environment(IngestStore.self) var ingestStore
    @Environment(Router.self) var router
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var heroNamespace: Namespace.ID
    var selection: Binding<SidebarSelection?>? = nil
    
    @State private var showDeleteConfirmation = false
    @State private var pageToDelete: KnowledgePage?

    var body: some View {
        @Bindable var router = router
        
        Group {
            if horizontalSizeClass == .compact {
                List {
                    CapabilitiesSection()
                    UniverseSection()
                    PinnedSection(
                        heroNamespace: heroNamespace,
                        pageToDelete: $pageToDelete,
                        showDeleteConfirmation: $showDeleteConfirmation
                    )
                    ToolsSection()
                }
            } else {
                List(selection: $router.sidebarSelection) {
                    CapabilitiesSection()
                    UniverseSection()
                    PinnedSection(
                        heroNamespace: heroNamespace,
                        pageToDelete: $pageToDelete,
                        showDeleteConfirmation: $showDeleteConfirmation
                    )
                    ToolsSection()
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
            pageToDelete.map { Localized.trf("page.deletePageTitle", $0.title) } ?? Localized.tr("page.deletePage"),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(Localized.tr("page.deletePage"), role: .destructive) {
                if let page = pageToDelete {
                    store.deletePage(page)
                }
            }
            Button(L10n.Common.tr("cancel"), role: .cancel) {
                pageToDelete = nil
            }
        }
        .appTabToolbar(title: Localized.tr("sidebar.title"))
    }
}

struct CapabilitiesSection: View {
    var body: some View {
        Section {
            NavigationLink(value: AppRoute.dashboard) {
                Label(Localized.tr("sidebar.dashboard"), systemImage: "gauge.with.needle.fill")
                    .foregroundStyle(.appText)
                    .contentShape(Rectangle())
            }
            NavigationLink(value: AppRoute.synthesis) {
                Label(Localized.tr("sidebar.synthesis"), systemImage: "wand.and.stars")
                    .foregroundStyle(.appText)
                    .contentShape(Rectangle())
            }
            NavigationLink(value: AppRoute.weeklyReport) {
                Label(Localized.tr("sidebar.weeklyInsight"), systemImage: "doc.text.magnifyingglass")
                    .foregroundStyle(.appText)
                    .contentShape(Rectangle())
            }
        }
 header: {
            Text(Localized.tr("sidebar.capabilities"))
        }
        .listRowBackground(SidebarRowBackground())
    }
}

struct UniverseSection: View {
    @Environment(AppStore.self) var store
    
    var body: some View {
        Section {
            NavigationLink(value: AppRoute.pageList(filterType: nil)) {
                UniverseNavRow(
                    icon: "tray.full.fill",
                    colorName: "accent",
                    title: Localized.tr("sidebar.pageList"),
                    count: store.pages.count
                )
                .contentShape(Rectangle())
            }
            
            ForEach(PageType.allCases) { type in
                let count = store.pages.filter { $0.type == type }.count
                if count > 0 {
                    NavigationLink(value: AppRoute.pageList(filterType: type)) {
                        SidebarTypeRow(type: type, count: count)
                            .contentShape(Rectangle())
                    }
                }
            }
        }
 header: {
            Text(Localized.tr("sidebar.universe"))
        }
        .listRowBackground(SidebarRowBackground())
    }
}

struct PinnedSection: View {
    @Environment(AppStore.self) var store
    var heroNamespace: Namespace.ID
    @Binding var pageToDelete: KnowledgePage?
    @Binding var showDeleteConfirmation: Bool
    
    var body: some View {
        let pinnedPages = store.pages.filter { $0.isPinned }
        if !pinnedPages.isEmpty {
            Section {
                ForEach(pinnedPages) { page in
                    SidebarPinnedRow(
                        page: page,
                        heroNamespace: heroNamespace,
                        onTogglePin: {
                            var p = page
                            p.isPinned.toggle()
                            Task { await store.updatePage(p, forceDeepScan: false) }
                        },
                        onDelete: {
                            pageToDelete = page
                            showDeleteConfirmation = true
                        }
                    )
                }
            } header: {
                Text(Localized.tr("pinned"))
            }
            .listRowBackground(SidebarRowBackground())
        }
    }
}

struct ToolsSection: View {
    @Environment(AppStore.self) var store
    @ObservedObject var taskCenter = TaskCenter.shared
    
    var body: some View {
        Section {
            NavigationLink(value: AppRoute.lint) {
                HStack {
                    Label(Localized.tr("sidebar.healthCheck"), systemImage: "stethoscope")
                        .foregroundStyle(.appText)
                    Spacer()
                    if !store.lintIssues.isEmpty {
                        Text("\(store.lintIssues.count)")
                            .font(DesignSystem.caption2Font)
                            .padding(.horizontal, DesignSystem.Chip.horizontalPadding)
                            .padding(.vertical, DesignSystem.Chip.verticalPadding)
                            .background(Color.appAccent.opacity(DesignSystem.subtleFillOpacity))
                            .clipShape(Capsule())
                            .foregroundStyle(.appAccent)
                    }
                }
                .contentShape(Rectangle())
            }
            NavigationLink(value: AppRoute.tagCloud) {
                Label(Localized.tr("sidebar.tagManager"), systemImage: "tag.fill")
                    .foregroundStyle(.appText)
                    .contentShape(Rectangle())
            }
            NavigationLink(value: AppRoute.taskCenter) {
                HStack {
                    Label(L10n.AI.Task.centerTitle, systemImage: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.appText)
                    Spacer()
                    if taskCenter.unreadCount > 0 {
                        Text("\(taskCenter.unreadCount)")
                            .font(.system(size: DesignSystem.caption2FontSize, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, DesignSystem.Chip.horizontalPadding)
                            .padding(.vertical, DesignSystem.Chip.verticalPadding)
                            .background(Capsule().fill(Color.orange))
                    }
                }
                .contentShape(Rectangle())
            }
            NavigationLink(value: AppRoute.pluginMarket) {
                Label(Localized.tr("sidebar.plugins"), systemImage: "puzzlepiece.fill")
                    .foregroundStyle(.appText)
                    .contentShape(Rectangle())
            }
            NavigationLink(value: AppRoute.collab) {
                Label(Localized.tr("sidebar.collaboration"), systemImage: "person.2.fill")
                    .foregroundStyle(.appText)
                    .contentShape(Rectangle())
            }
        } header: {
            Text(Localized.tr("sidebar.tools"))
        }
        .listRowBackground(SidebarRowBackground())
    }
}

// MARK: - Helpers

struct SidebarListStyleModifier: ViewModifier {
    let horizontalSizeClass: UserInterfaceSizeClass?
    
    func body(content: Content) -> some View {
        #if os(iOS)
        if horizontalSizeClass == .compact {
            content.listStyle(.insetGrouped)
        } else {
            content.listStyle(.sidebar)
        }
        #elseif os(macOS)
        content.listStyle(.sidebar)
        #else
        content.listStyle(.plain)
        #endif
    }
}

// MARK: - Row Components

struct SidebarRowBackground: View {
    var body: some View {
        Color.appCard.opacity(DesignSystem.subtleOpacity)
            .background(.ultraThinMaterial)
    }
}

/// 知识宇宙通用导航行（参考搜索页面卡片风格）
struct UniverseNavRow: View {
    let icon: String
    let colorName: String
    let title: String
    let count: Int
    
    var iconColor: Color {
        colorName == "accent" ? .appAccent : Color.fromModelColorName(colorName)
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.medium) {
            // 彩色图标区域
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: DesignSystem.largeIconSize, height: DesignSystem.largeIconSize)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius, style: .continuous))
            
            // 标题
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.appText)
            
            Spacer()
            
            // 数量角标
            if count > 0 {
                Text("\(count)")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, DesignSystem.Chip.horizontalPadding)
                    .padding(.vertical, DesignSystem.Chip.verticalPadding)
                    .background(Color.appAccent.opacity(DesignSystem.subtleFillOpacity))
                    .foregroundStyle(.appAccent)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, DesignSystem.atomic)
    }
}

/// 按类型过滤的导航行（参考搜索页面卡片风格）
struct SidebarTypeRow: View {
    let type: PageType
    let count: Int
    
    var body: some View {
        HStack(spacing: DesignSystem.medium) {
            // 彩色图标区域（匹配类型主色）
            Image(systemName: type.icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.fromModelColorName(type.colorName))
                .frame(width: DesignSystem.largeIconSize, height: DesignSystem.largeIconSize)
                .background(Color.fromModelColorName(type.colorName).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius, style: .continuous))
            
            // 分类名称
            Text(type.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.appText)
            
            Spacer()
            
            // 数量角标（使用类型主色）
            Text("\(count)")
                .font(.caption2.weight(.bold))
                .padding(.horizontal, count > 9 ? DesignSystem.Chip.horizontalPadding : DesignSystem.Chip.verticalPadding)
                .padding(.vertical, DesignSystem.Chip.verticalPadding)
                .background(Color.fromModelColorName(type.colorName).opacity(0.15))
                .foregroundStyle(Color.fromModelColorName(type.colorName))
                .clipShape(Capsule())
        }
        .padding(.vertical, DesignSystem.atomic)
    }
}

struct SidebarPinnedRow: View {
    let page: KnowledgePage
    var heroNamespace: Namespace.ID
    let onTogglePin: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        NavigationLink(value: SidebarSelection.page(page.id)) {
            PageSidebarRow(page: page, heroNamespace: heroNamespace)
        }
        .contextMenu {
            Button(action: onTogglePin) {
                Label(page.isPinned ? Localized.tr("page.unpin") : Localized.tr("page.pin"), systemImage: page.isPinned ? "pin.slash" : "pin")
            }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label(Localized.tr("page.deletePage"), systemImage: "trash")
            }
        }
    }
}

struct PageSidebarRow: View {
    let page: KnowledgePage
    var heroNamespace: Namespace.ID
    var body: some View {
        HStack(spacing: DesignSystem.small) {
            Image(systemName: page.type.icon)
                .font(.system(size: DesignSystem.Icons.small))
                .foregroundStyle(Color.fromModelColorName(page.type.colorName))
                .frame(width: DesignSystem.Sidebar.iconFrameWidth)
            
            Text(page.title)
                .font(.system(size: DesignSystem.subheadlineFontSize, weight: .medium))
                .foregroundStyle(.appText)
                .lineLimit(1)
        }
        .padding(.vertical, DesignSystem.atomic)
    }
}
