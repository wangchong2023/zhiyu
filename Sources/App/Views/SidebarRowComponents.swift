// SidebarRowComponents.swift
//
// 作者: Wang Chong
// 功能说明: [L3] 应用调度层：本文件包含侧边栏相关的辅助组件和行视图，用于支持 SidebarView。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

// MARK: - Navigation Definitions

/// 侧边栏导航选中项定义
/// 用于追踪用户在 NavigationSplitView 侧边栏中的交互位置
public enum SidebarSelection: Hashable {
    /// 跳转到特定的知识页面条目 (根据 UUID 唯一定位)
    case page(UUID)
    
    /// 跳转到系统预设的工具项 (如：仪表盘、页面列表、设置等)
    case tool(AppStore.ToolItem)
    
    /// 按特定 PageType 类型过滤后的知识列表 (如：仅查看实体或概念)
    case filteredIndex(PageType)
    
    /// 将当前的侧边栏选中项转换为具体的物理路由目标
    /// 这一映射过程解耦了侧边栏的 UI 交互状态与底层的视图分发逻辑。
    /// - Returns: 对应的 AppRoute 目标，可直接用于导航栈。
    public func asRoute() -> AppRoute {
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
            case .search: return .search()
            case .ingest: return .ingest
            case .graph: return .graph
            case .sources: return .sources
            }
        case .filteredIndex(let type): return .pageList(filterType: type)
        }
    }
}

// MARK: - Sections

struct SearchSection: View {
    @Environment(Router.self) var router
    var body: some View {
        Section {
            Button(action: {
                HapticFeedback.shared.trigger(.selection)
                router.navigate(to: .search())
            }) {
                HStack(spacing: DesignSystem.medium) {
                    Image(systemName: DesignSystem.Icons.search)
                        .font(.system(size: DesignSystem.subheadlineFontSize, weight: .semibold))
                        .foregroundStyle(.appAccent)
                    
                    Text(L10n.SearchPlaceholder)
                        .font(.subheadline)
                        .foregroundStyle(.appSecondary)
                    Spacer()
                    
                    HStack(spacing: DesignSystem.atomic) {
                        Image(systemName: DesignSystem.Icons.command)
                        Text("K")
                    }
                    .font(.system(size: DesignSystem.microFontSize, weight: .bold))
                    .foregroundStyle(.appSecondary.opacity(DesignSystem.softOpacity))
                    .padding(.horizontal, DesignSystem.Chip.horizontalPadding)
                    .padding(.vertical, DesignSystem.atomic)
                    .background(Color.appBorder.opacity(DesignSystem.accentStrokeOpacity))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.micro))
                }
                .padding(.vertical, DesignSystem.tiny)
            }
            .buttonStyle(.plain)
        }
        .listRowBackground(
            RoundedRectangle(cornerRadius: DesignSystem.standardRadius)
                .fill(Color.appCard.opacity(DesignSystem.subtleOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.standardRadius)
                        .stroke(Color.appBorder.opacity(DesignSystem.accentStrokeOpacity), lineWidth: 0.5)
                )
        )
    }
}

struct CapabilitiesSection: View {
    var body: some View {
        Section {
            NavigationLink(value: AppRoute.dashboard) {
                Label(L10n.Common.Sidebar.dashboard, systemImage: DesignSystem.Icons.dashboard)
                    .foregroundStyle(.appText)
                    .contentShape(Rectangle())
            }
            NavigationLink(value: AppRoute.weeklyReport) {
                Label(L10n.Common.Sidebar.weeklyInsight, systemImage: DesignSystem.Icons.weeklyInsight)
                    .foregroundStyle(.appText)
                    .contentShape(Rectangle())
            }
            
            // 插件自定义视图入口
            PluginCustomViewsSection()
        }
 header: {
            Text(L10n.Common.Sidebar.capabilities)
        }
        .listRowBackground(SidebarRowBackground())
    }
}

struct SourcesSection: View {
    var sourceStore = SourceStore.shared
    
    var body: some View {
        if !sourceStore.activeSources.isEmpty {
            Section {
                NavigationLink(value: SidebarSelection.tool(.sources)) {
                    Label {
                        HStack {
                            Text(L10n.Plugin.Sidebar.currentSources)
                            Spacer()
                            Text("\(sourceStore.activeSources.count)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .background(Color.appAccent)
                                .clipShape(Capsule())
                        }
                    } icon: {
                        Image(systemName: DesignSystem.Icons.quoteBubble)
                            .foregroundStyle(.appAccent)
                    }
                }
            } header: {
                Text(L10n.Plugin.Section.rag)
            }
            .listRowBackground(SidebarRowBackground())
        }
    }
}

struct UniverseSection: View {
    @Environment(AppStore.self) var store
    @Environment(Router.self) var router
    
    var body: some View {
        Section {
            NavigationLink(value: AppRoute.pageList(filterType: nil)) {
                UniverseNavRow(
                    icon: DesignSystem.Icons.pageList,
                    colorName: "accent",
                    title: L10n.Common.Sidebar.pageList,
                    count: store.pages.count,
                    onSearch: { router.navigate(to: .search()) }
                )
                .contentShape(Rectangle())
            }
            
            ForEach(PageType.allCases) { type in
                let count = store.pages.filter { $0.pageType == type }.count
                if count > 0 {
                    NavigationLink(value: AppRoute.pageList(filterType: type)) {
                        SidebarTypeRow(type: type, count: count, onSearch: {
                            router.navigate(to: .search(filterType: type))
                        })
                        .contentShape(Rectangle())
                    }
                }
            }
        }
 header: {
            Text(L10n.Common.Sidebar.universe)
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
                Text(L10n.Common.pinned)
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
                    Label(L10n.Common.Sidebar.healthCheck, systemImage: DesignSystem.Icons.healthCheck)
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
                Label(L10n.Common.Sidebar.tagManager, systemImage: DesignSystem.Icons.tag)
                    .foregroundStyle(.appText)
                    .contentShape(Rectangle())
            }
            NavigationLink(value: AppRoute.taskCenter) {
                HStack {
                    Label(L10n.AI.Task.centerTitle, systemImage: DesignSystem.Icons.refresh)
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
                Label(L10n.Common.Sidebar.plugins, systemImage: DesignSystem.Icons.plugins)
                    .foregroundStyle(.appText)
                    .contentShape(Rectangle())
            }
            NavigationLink(value: AppRoute.collab) {
                Label(L10n.Common.Sidebar.collaboration, systemImage: DesignSystem.Icons.collaborationPeers)
                    .foregroundStyle(.appText)
                    .contentShape(Rectangle())
            }
        } header: {
            Text(L10n.Common.Sidebar.tools)
        }
        .listRowBackground(SidebarRowBackground())
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
    var onSearch: (() -> Void)? = nil
    
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
            
            // 垂直搜索入口
            if let onSearch {
                Button(action: {
                    HapticFeedback.shared.trigger(.selection)
                    onSearch()
                }) {
                    Image(systemName: DesignSystem.Icons.search)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.appSecondary.opacity(DesignSystem.softOpacity))
                        .padding(DesignSystem.tiny)
                        .background(Color.appSecondary.opacity(DesignSystem.subtleFillOpacity))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, DesignSystem.atomic)
    }
}

/// 按类型过滤的导航行（参考搜索页面卡片风格）
struct SidebarTypeRow: View {
    let type: PageType
    let count: Int
    var onSearch: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: DesignSystem.medium) {
            // 彩色图标区域（匹配类型主色）
            Image(systemName: type.icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.fromModelColorName(type.colorName))
                .frame(width: DesignSystem.largeIconSize, height: DesignSystem.largeIconSize)
                .background(Color.fromModelColorName(type.colorName).opacity(DesignSystem.softOpacity * 0.3)) // 0.12
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
                .background(Color.fromModelColorName(type.colorName).opacity(DesignSystem.softOpacity * 0.375)) // 0.15
                .foregroundStyle(Color.fromModelColorName(type.colorName))
                .clipShape(Capsule())
            
            // 垂直搜索入口
            if let onSearch {
                Button(action: {
                    HapticFeedback.shared.trigger(.selection)
                    onSearch()
                }) {
                    Image(systemName: DesignSystem.Icons.search)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.fromModelColorName(type.colorName).opacity(DesignSystem.subtleOpacity))
                        .padding(DesignSystem.tiny)
                        .background(Color.fromModelColorName(type.colorName).opacity(DesignSystem.subtleFillOpacity))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
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
                Label(page.isPinned ? L10n.Knowledge.Page.unpin : L10n.Knowledge.Page.pin, systemImage: page.isPinned ? DesignSystem.Icons.unpin : DesignSystem.Icons.pin)
            }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label(L10n.Knowledge.Page.deletePage, systemImage: DesignSystem.Icons.delete)
            }
        }
    }
}

struct PageSidebarRow: View {
    let page: KnowledgePage
    var heroNamespace: Namespace.ID
    var body: some View {
        HStack(spacing: DesignSystem.small) {
            Image(systemName: page.pageType.icon)
                .font(.system(size: DesignSystem.Icons.small))
                .foregroundStyle(Color.fromModelColorName(page.pageType.colorName))
                .frame(width: DesignSystem.Sidebar.iconFrameWidth)
            
            Text(page.title)
                .font(.system(size: DesignSystem.subheadlineFontSize, weight: .medium))
                .foregroundStyle(.appText)
                .lineLimit(1)
        }
        .padding(.vertical, DesignSystem.atomic)
    }
}

// MARK: - Modifiers

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

// MARK: - 插件扩展入口

struct PluginRibbonSection: View {
    @ObservedObject var registry = PluginRegistry.shared
    
    var body: some View {
        if !registry.ribbonItems.isEmpty {
            Section {
                ForEach(registry.ribbonItems) { item in
                    Button(action: {
                        HapticFeedback.shared.trigger(.selection)
                        item.action()
                    }) {
                        Label(item.title, systemImage: item.icon)
                            .foregroundStyle(.appText)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text(L10n.Plugin.section.ribbon)
            }
            .listRowBackground(SidebarRowBackground())
        }
    }
}

struct PluginCustomViewsSection: View {
    @ObservedObject var registry = PluginRegistry.shared
    
    var body: some View {
        ForEach(registry.customViews) { view in
            Button(action: {
                HapticFeedback.shared.trigger(.selection)
                view.action()
            }) {
                Label(view.title, systemImage: view.icon)
                    .foregroundStyle(.appText)
            }
            .buttonStyle(.plain)
        }
    }
}
