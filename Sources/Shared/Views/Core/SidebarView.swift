// SidebarView.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了知识管理系统的核心导航分发中心（SidebarView）。
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

// MARK: - Sidebar Selection
enum SidebarSelection: Hashable {
    case page(UUID)
    case tool(AppStore.ToolItem)
    case filteredIndex(PageType)
    
    func asRoute() -> AppRoute {
        switch self {
        case .page(let id): return .pageDetail(id: id)
        case .tool(let tool):
            switch tool {
            case .dashboard: return .dashboard
            case .index: return .index()
            case .lint: return .lint
            case .taskCenter: return .taskCenter
            case .tagCloud: return .tagCloud
            case .chat: return .chat
            case .synthesis: return .synthesis
            case .weeklyReport: return .weeklyReport
            case .log: return .log
            case .collab: return .collab
            case .pluginMarket: return .pluginMarket
            }
        case .filteredIndex(let type): return .index(filterType: type)
        }
    }
}

// MARK: - Sidebar View
struct SidebarView: View {
    @Environment(AppStore.self) var store
    @Environment(IngestStore.self) var ingestStore
    @Environment(AppRouter.self) var router
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var heroNamespace: Namespace.ID
    var selection: Binding<SidebarSelection?>? = nil
    
    @State private var showDeleteConfirmation = false
    @State private var pageToDelete: KnowledgePage?

    var body: some View {
        @Bindable var router = router
        
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
        .background(
            AppUI.Background.pageBackground(accentColor: themeManager.accentColor)
                .ignoresSafeArea()
        )
        .scrollContentBackground(.hidden)
        .modifier(SidebarListStyleModifier(horizontalSizeClass: horizontalSizeClass))
        .navigationTitle(Localized.tr("sidebar.title"))
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { store.securityService.lock() }) {
                    Image(systemName: "lock.fill").foregroundStyle(.red.opacity(0.9))
                }
            }
        }
    }
}

// MARK: - Sections

struct CapabilitiesSection: View {
    var body: some View {
        Section {
            NavigationLink(value: SidebarSelection.tool(.dashboard)) {
                Label {
                    Text(Localized.tr("sidebar.dashboard"))
                } icon: {
                    Image(systemName: "gauge.with.needle.fill")
                        .foregroundStyle(.blue)
                }
            }
            NavigationLink(value: SidebarSelection.tool(.chat)) {
                Label {
                    Text(Localized.tr("tab.chat"))
                } icon: {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.cyan)
                }
            }
            NavigationLink(value: SidebarSelection.tool(.synthesis)) {
                Label {
                    Text(Localized.tr("sidebar.synthesis"))
                } icon: {
                    Image(systemName: "wand.and.stars")
                        .foregroundStyle(.indigo)
                }
            }
            NavigationLink(value: SidebarSelection.tool(.weeklyReport)) {
                Label {
                    Text(Localized.tr("sidebar.weeklyInsight"))
                } icon: {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundStyle(.blue.opacity(0.8))
                }
            }
        } header: {
            Text(Localized.tr("sidebar.capabilities"))
        }
        .listRowBackground(SidebarRowBackground())
    }
}

struct UniverseSection: View {
    @Environment(AppStore.self) var store
    
    var body: some View {
        Section {
            NavigationLink(value: SidebarSelection.tool(.index)) {
                Label {
                    Text(Localized.tr("sidebar.allPages"))
                } icon: {
                    Image(systemName: "tray.full.fill")
                        .foregroundStyle(.blue)
                }
            }
            
            ForEach(PageType.allCases) { type in
                let count = store.pages.filter { $0.type == type }.count
                if count > 0 {
                    NavigationLink(value: SidebarSelection.filteredIndex(type)) {
                        SidebarTypeRow(type: type, count: count)
                    }
                }
            }
        } header: {
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
                            store.updatePage(p, forceDeepScan: false)
                        },
                        onDelete: {
                            pageToDelete = page
                            showDeleteConfirmation = true
                        }
                    )
                }
            } header: {
                Label(Localized.tr("pinned"), systemImage: "pin.fill")
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
            NavigationLink(value: SidebarSelection.tool(.lint)) {
                HStack {
                    Label {
                        Text(Localized.tr("sidebar.healthCheck"))
                    } icon: {
                        Image(systemName: "stethoscope")
                            .foregroundStyle(.cyan)
                    }
                    Spacer()
                    if !store.lintIssues.isEmpty {
                        Text("\(store.lintIssues.count)")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .background(Color.appAccent.opacity(0.1))
                            .clipShape(Capsule())
                            .foregroundStyle(.appAccent)
                    }
                }
            }
            NavigationLink(value: SidebarSelection.tool(.tagCloud)) {
                Label {
                    Text(Localized.tr("sidebar.tagManager"))
                } icon: {
                    Image(systemName: "tag.fill")
                        .foregroundStyle(.blue.opacity(0.7))
                }
            }
            NavigationLink(value: SidebarSelection.tool(.taskCenter)) {
                HStack {
                    Label {
                        Text(L10n.AI.Task.centerTitle)
                    } icon: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    if taskCenter.unreadCount > 0 {
                        Text("\(taskCenter.unreadCount)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.red))
                    }
                }
            }
            NavigationLink(value: SidebarSelection.tool(.pluginMarket)) {
                Label {
                    Text(Localized.tr("sidebar.plugins"))
                } icon: {
                    Image(systemName: "puzzlepiece.fill")
                        .foregroundStyle(.indigo)
                }
            }
            NavigationLink(value: SidebarSelection.tool(.collab)) {
                Label {
                    Text(Localized.tr("sidebar.collaboration"))
                } icon: {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(.blue)
                }
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
        #else
        content.listStyle(.sidebar)
        #endif
    }
}

// MARK: - Row Components

struct SidebarRowBackground: View {
    var body: some View {
        Color.appCard.opacity(0.7)
            .background(.ultraThinMaterial)
    }
}

struct SidebarTypeRow: View {
    let type: PageType
    let count: Int
    var body: some View {
        Label {
            HStack {
                Text(type.displayName)
                Spacer()
                Text("\(count)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.appSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.appAccent.opacity(0.1))
                    .clipShape(Capsule())
            }
        } icon: {
            Image(systemName: type.icon)
                .foregroundStyle(Color.fromModelColorName(type.colorName))
                .frame(width: 20)
        }
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
        HStack(spacing: AppUI.small) {
            Image(systemName: page.type.icon)
                .font(.system(size: AppUI.iconSmall))
                .foregroundStyle(Color.fromModelColorName(page.type.colorName))
                .frame(width: 24)
            
            Text(page.title)
                .font(.system(size: AppUI.subheadlineFontSize, weight: .medium))
                .foregroundStyle(.appText)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
    }
}
