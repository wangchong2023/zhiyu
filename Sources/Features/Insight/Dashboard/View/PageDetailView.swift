// PageDetailView.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：知识详情页视图，支持 Markdown 编辑、AI 洞察及关联分析。
// 核心原则：
// 1. 单一布局源：完全遵循 AppUI 的 Layout 和 Metrics 系统。
// 2. 图标标准化：使用 DesignSystem.Icons 统一管理所有 SF Symbols。
// 版本: 1.2
// 修改记录:
//   - 2026-05-15: 切换至 PageDetailCoordinator 驱动，并将业务状态编排（AI 任务、Toast）移出 L1 层。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 页面详情视图
struct PageDetailView: View {
    @State private var coordinator: PageDetailCoordinator
    var heroNamespace: Namespace.ID? = nil
    @Environment(AppStore.self) var store
    @Environment(AIWorkflowStore.self) var aiStore
    @Environment(Router.self) var router
    @State private var recommendations: [KnowledgePage] = []

    init(page: KnowledgePage, heroNamespace: Namespace.ID? = nil) {
        self.heroNamespace = heroNamespace
        self._coordinator = State(initialValue: PageDetailCoordinator(page: page))
    }
    
    private var pinButton: some View {
        Button(action: { Task { await coordinator.togglePin() } }) {
            Image(systemName: coordinator.page.isPinned ? DesignSystem.Icons.pin + ".fill" : DesignSystem.Icons.pin)
                .foregroundStyle(coordinator.page.isPinned ? .orange : .appSecondary)
        }
    }
    
    private var backlinksButton: some View {
        Button(action: { coordinator.showBacklinks.toggle() }) {
            HStack(spacing: DesignSystem.tiny) {
                Image(systemName: DesignSystem.Icons.link)
                Text("\(coordinator.backlinks.count)")
            }
            .foregroundStyle(.appText)
        }
    }
    
    private var editButton: some View {
        Button(action: {
            HapticFeedback.shared.trigger(.selection)
            if coordinator.isEditing {
                Task { await store.updatePage(coordinator.page, forceDeepScan: false) }
            }
            coordinator.isEditing.toggle()
        }) {
            Image(systemName: coordinator.isEditing ? "checkmark.circle.fill" : DesignSystem.Icons.edit + ".circle.fill")
                .foregroundStyle(coordinator.isEditing ? .green : .appText)
        }
    }
    
    private var aiMenuButton: some View {
        #if os(watchOS)
        Button(action: { coordinator.generateSummary() }) {
            Image(systemName: DesignSystem.Icons.sparkles)
                .foregroundStyle(.appAccent)
        }
        .disabled(coordinator.isEditing)
        #else
        Menu {
            Button(action: { coordinator.generateSummary() }) {
                Label(Localized.tr("page.ai.summary"), systemImage: "wand.and.stars")
            }
            Button(action: { coordinator.extractActions() }) {
                Label(Localized.tr("page.ai.extractActions"), systemImage: "checkmark.seal")
            }

            Menu {
                Button(action: { coordinator.performSynthesis(type: .mindmap) }) {
                    Label(Localized.tr("page.ai.mindmap"), systemImage: "rectangle.stack.badge.person.crop")
                }
                Button(action: { coordinator.performSynthesis(type: .quiz) }) {
                    Label(Localized.tr("page.ai.quiz"), systemImage: "questionmark.circle")
                }
                Button(action: { coordinator.performSynthesis(type: .slides) }) {
                    Label(Localized.tr("page.ai.slides"), systemImage: "play.rectangle")
                }
                Button(action: { coordinator.performSynthesis(type: .report) }) {
                    Label(Localized.tr("page.ai.report"), systemImage: "doc.text.magnifyingglass")
                }
                Button(action: { coordinator.performSynthesis(type: .infographic) }) {
                    Label(Localized.tr("page.ai.infographic"), systemImage: "chart.bar.doc.horizontal")
                }
            } label: {
                Label(Localized.tr("page.ai.lab"), systemImage: "flask")
            }
            
            Divider()
            Button(action: { coordinator.showSnapshotHistory = true }) {
                Label(Localized.tr("page.history"), systemImage: DesignSystem.Icons.history)
            }
            Button(action: { coordinator.expandContent() }) {
                Label(Localized.tr("page.expandStub"), systemImage: "text.badge.plus")
            }
            Button(action: { coordinator.findRelatedLinks() }) {
                Label(Localized.tr("page.findLinks"), systemImage: "link.badge.plus")
            }
        } label: {
            Image(systemName: DesignSystem.Icons.sparkles)
                .foregroundStyle(.appAccent)
        }
        .disabled(coordinator.isEditing)
        #endif
    }
    
    var body: some View {
        @Bindable var coordinator = coordinator
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 10)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        if aiStore.isProcessingPageAI || aiStore.activePageAIResult != nil {
                            aiResultDisplaySection
                                .id("aiResultSection")
                                .padding(.bottom, DesignSystem.standardPadding)
                        }
                    
                    Group {
                        if coordinator.isEditing {
                            MarkdownEditorView(page: $coordinator.page, isEditing: $coordinator.isEditing)
                                .padding(.top, DesignSystem.wide)
                        } else if coordinator.page.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            emptyStateView
                        } else {
                            MarkdownRendererView(content: coordinator.page.content, isPrivate: coordinator.page.isPrivate, onLinkTap: { title in
                                navigateToPage(title)
                            })
                            .padding(.vertical)
                        }

                        Divider().background(Color.appBorder)

                        provenanceSection
                        backlinksSection
                    }
                    .padding(.horizontal)
                }
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: DesignSystem.Layout.maxReadWidth)
        .frame(maxWidth: .infinity)
        .background(PageBackgroundView(accentColor: Color.fromModelColorName(coordinator.page.pageType.colorName)))
        .appSubPageToolbar(title: coordinator.page.title) {
            HStack(spacing: DesignSystem.small) {
                pinButton
                backlinksButton
                editButton
                aiMenuButton
            }
        }
        .confirmationDialog(Localized.tr("page.confirmDelete"), isPresented: $coordinator.showDeleteConfirmation) {
            Button(Localized.trf("page.deletePageTitle", coordinator.page.title), role: .destructive) {
                Task { await coordinator.deletePage() }
            }
            Button(L10n.Common.tr("cancel"), role: .cancel) {}
        } message: {
            Text(Localized.tr("page.deleteMessage"))
        }
        .sheet(isPresented: $coordinator.showBacklinks) {
            BacklinksView(page: coordinator.page)
        }
        .sheet(isPresented: $coordinator.showIconPicker) {
            NavigationStack {
                IconPickerView(selectedIcon: Binding(
                    get: { coordinator.page.customIcon },
                    set: { newIcon in
                        var updated = coordinator.page
                        updated.customIcon = newIcon
                        Task { await store.updatePage(updated, forceDeepScan: false) }
                        coordinator.page = updated
                    }
                ))
            }
        }
        .onChange(of: coordinator.page) { _, newValue in
            if !coordinator.isEditing {
                Task { await store.updatePage(newValue, forceDeepScan: false) }
            }
        }
        .safeAreaInset(edge: .top) {
            VStack(spacing: 0) {
                if router.navigationHistory.count > 1 {
                    BreadcrumbView(history: Array(router.navigationHistory.dropLast())) { id in
                        let targetPage = store.pages.first { $0.id == id }
                        if let target = targetPage {
                            navigateToPage(target.title)
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                PageDetailHeader(page: coordinator.page, heroNamespace: heroNamespace)
                    .padding(.top, router.navigationHistory.isEmpty ? DesignSystem.Layout.tightPadding : 0)
                    .background(.ultraThinMaterial)
            }
            .frame(maxWidth: DesignSystem.Layout.maxReadWidth)
            .overlay(
                Divider().background(Color.appBorder),
                alignment: .bottom
            )
        }
        .sheet(isPresented: $coordinator.showSnapshotHistory) {
            PageHistoryView(page: coordinator.page)
        }
        .onAppear {
            router.addToHistory(coordinator.page)
            Task {
                recommendations = await aiStore.findSimilarPages(for: coordinator.page)
            }
        }
        .onChange(of: coordinator.page) { _, newValue in
            router.addToHistory(newValue)
            Task {
                recommendations = await aiStore.findSimilarPages(for: newValue)
            }
        }
        .quizPresentation(activeQuiz: Binding(get: { aiStore.activeQuiz }, set: { aiStore.activeQuiz = $0 }))
        }
    }
    
    @ViewBuilder
    private var aiResultDisplaySection: some View {
        if aiStore.isProcessingPageAI || aiStore.activePageAIResult != nil {
            VStack(alignment: .leading, spacing: DesignSystem.medium) {
                HStack {
                    Image(systemName: DesignSystem.Icons.sparkles)
                        .foregroundStyle(.appAccent)
                    Text(Localized.tr("page.ai.labOutput"))
                        .font(.headline)
                        .foregroundStyle(.appText)
                    Spacer()
                    if !aiStore.isProcessingPageAI {
                        if let result = aiStore.activePageAIResult, result.contains("- ") {
                            Button(action: {
                                Task {
                                    @Inject var workflowService: WorkflowService
                                    try await workflowService.syncToReminders(text: result, title: coordinator.page.title)
                                }
                            }) {
                                Label(L10n.Common.tr("syncToReminders"), systemImage: "checklist")
                                    .font(.caption)
                                    .foregroundStyle(.appAccent)
                            }
                            .padding(.trailing, DesignSystem.small)
                        }
                        
                        Button(action: { 
                            AppPasteboard.string = aiStore.activePageAIResult
                            HapticFeedback.shared.trigger(.success)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.appSecondary)
                        }
                        
                        Button(action: { aiStore.activePageAIResult = nil }) {
                            Image(systemName: "xmark.circle")
                                .font(.caption)
                                .foregroundStyle(.appSecondary)
                        }
                    }
                }
                
                if aiStore.isProcessingPageAI {
                    VStack(alignment: .leading, spacing: DesignSystem.medium) {
                        AppSkeleton(height: 20).frame(width: 200)
                        AppSkeleton(height: 120)
                        AppSkeleton(height: 60)
                    }
                } else if let result = aiStore.activePageAIResult {
                    MarkdownRendererView(content: result, isPrivate: false, onLinkTap: { text in
                        navigateToPage(text)
                    })
                    .appContainer(padding: true)
                }
            }
            .padding()
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.medium) {
            Image(systemName: "pencil.line")
                .font(.system(size: DesignSystem.huge))
                .foregroundStyle(.appSecondary)
            Text(Localized.tr("page.empty"))
                .font(.subheadline)
                .foregroundStyle(.appSecondary)
            Text(Localized.tr("page.emptyHint"))
                .font(.caption)
                .foregroundStyle(.appAccent.opacity(0.7))
                .padding(.horizontal, DesignSystem.wide)
                .padding(.vertical, DesignSystem.small)
                .background(Color.appAccent.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
    
    private var provenanceSection: some View {
        Group {
            if let sourceURL = coordinator.page.sourceURL, let url = URL(string: sourceURL) {
                VStack(alignment: .leading, spacing: DesignSystem.tightPadding) {
                    HStack {
                        Image(systemName: "safari").foregroundStyle(.appAccent)
                        Text(Localized.tr("page.source.title")).font(.headline).foregroundStyle(.appText)
                        Spacer()
                        Link(destination: url) {
                            HStack(spacing: DesignSystem.tiny) {
                                Text(Localized.tr("page.source.open"))
                                Image(systemName: "arrow.up.right.circle")
                            }
                            .font(.caption)
                            .foregroundStyle(.appAccent)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(sourceURL).font(.caption2).foregroundStyle(.appSecondary).lineLimit(1).truncationMode(.middle)
                        
                        if let snippet = coordinator.page.rawTextSnippet, !snippet.isEmpty {
                            Text(snippet).font(.system(size: 11, design: .monospaced)).foregroundStyle(.appSecondary).padding(DesignSystem.small).frame(maxWidth: .infinity, alignment: .leading).background(Color.appCard).clipShape(RoundedRectangle(cornerRadius: DesignSystem.microRadius)).lineLimit(3)
                        }
                    }
                    .appContainer(padding: true)
                }
                .padding()
            } else {
                EmptyView()
            }
        }
    }
    
    private var semanticRecommendationsSection: some View {
        Group {
            if !recommendations.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.medium) {
                    HStack(spacing: DesignSystem.small) {
                        ZStack {
                            Circle().fill(Color.appAccent.opacity(0.1)).frame(width: 24, height: 24)
                            Image(systemName: DesignSystem.Icons.sparkles).font(.system(size: DesignSystem.iconTiny)).foregroundStyle(.appAccent)
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(Localized.tr("page.aiInsights")).font(.headline).foregroundStyle(.appText)
                            Text(Localized.tr("page.aiInsights.desc")).font(.system(size: 9)).foregroundStyle(.appSecondary)
                        }
                    }
                    .padding(.bottom, DesignSystem.tiny)
                    
                    VStack(spacing: DesignSystem.tightPadding) {
                        ForEach(recommendations) { recPage in
                            recommendationRow(for: recPage)
                        }
                    }
                }
                .padding().background(RoundedRectangle(cornerRadius: DesignSystem.largeRadius).fill(Color.appAccent.opacity(0.03))).overlay(RoundedRectangle(cornerRadius: DesignSystem.largeRadius).stroke(LinearGradient(colors: [.appAccent.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)).padding(.vertical)
            }
        }
    }
    
    private func recommendationRow(for recPage: KnowledgePage) -> some View {
        NavigationLink(value: AppRoute.pageDetail(id: recPage.id)) {
            HStack {
                Image(systemName: recPage.displayIcon).foregroundStyle(Color.fromModelColorName(recPage.pageType.colorName))
                VStack(alignment: .leading, spacing: 2) {
                    Text(recPage.title).font(.subheadline.weight(.medium))
                    let summaryText = String(recPage.content.prefix(60)) + "..."
                    Text(summaryText).font(.caption2).foregroundStyle(.appSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.appSecondary)
            }
            .padding(DesignSystem.medium).background(Color.appCard).clipShape(RoundedRectangle(cornerRadius: DesignSystem.tightPadding)).overlay(RoundedRectangle(cornerRadius: DesignSystem.tightPadding).stroke(LinearGradient(colors: [.appAccent.opacity(0.3), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
    
    private var backlinksSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            HStack {
                Image(systemName: DesignSystem.Icons.link).foregroundStyle(.appAccent)
                Text(Localized.tr("page.backlinks")).font(.headline).foregroundStyle(.appText)
                Text("(\(coordinator.backlinks.count))").font(.subheadline).foregroundStyle(.appSecondary)
            }
            
            if coordinator.backlinks.isEmpty {
                Text(Localized.tr("page.noBackLinks")).font(.caption).foregroundStyle(.appSecondary).padding(.vertical, DesignSystem.small)
            } else {
                ForEach(coordinator.backlinks) { linkedPage in
                    NavigationLink(value: AppRoute.pageDetail(id: linkedPage.id)) {
                        HStack(spacing: DesignSystem.medium) {
                            Image(systemName: linkedPage.displayIcon).foregroundStyle(Color.fromModelColorName(linkedPage.pageType.colorName)).frame(width: 28, height: 28).background(Color.fromModelColorName(linkedPage.pageType.colorName).opacity(DesignSystem.Opacity.glass)).clipShape(RoundedRectangle(cornerRadius: DesignSystem.microRadius))
                            Text(linkedPage.title).font(.subheadline).foregroundStyle(.appText)
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.appSecondary)
                        }
                        .padding(.horizontal, DesignSystem.tightPadding).padding(.vertical, DesignSystem.small).background(Color.appCard).clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Localized.trf("page.backlinkAccessibility", linkedPage.title, linkedPage.pageType.displayName))
                    .accessibilityHint(Localized.tr("page.doubleTapToNavigate"))
                }
            }
        }
        .padding()
    }
    
    private func navigateToPage(_ title: String) {
        if let target = store.pages.first(where: { $0.title == title }) {
            router.navigate(to: .pageDetail(id: target.id))
        }
    }
}
