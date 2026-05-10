// PageDetailView.swift
//
// 作者: Wang Chong
// 功能说明: 知识详情页视图，支持 Markdown 编辑、AI 洞察及关联分析。
// 核心原则：
// 1. 单一布局源：完全遵循 AppUI 的 Layout 和 Metrics 系统。
// 2. 图标标准化：使用 AppUI.Icons 统一管理所有 SF Symbols。
// 版本: 1.1 (工业级布局重构版)
// 修改记录:
//   - 2026-05-07: 移除硬编码颜色与间距，对接全局 AppUI 治理体系。

import SwiftUI

/// 页面详情视图
///
/// 显示知识库中单个页面的完整内容，支持查看和编辑两种模式。
struct PageDetailView: View {
    @State private var viewModel: PageDetailViewModel
    var heroNamespace: Namespace.ID? = nil
    @Environment(AppStore.self) var store  ///< 全局知识库存储
    @Environment(AIWorkflowStore.self) var aiStore ///< AI 工作流存储
    @Environment(AppRouter.self) var router     ///< 路由管理器
    @State private var recommendations: [KnowledgePage] = [] ///< 语义推荐页面

    init(page: KnowledgePage, heroNamespace: Namespace.ID? = nil) {
        self.heroNamespace = heroNamespace
        self._viewModel = State(initialValue: PageDetailViewModel(page: page))
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            HStack(spacing: AppUI.small) {
                pinButton
                backlinksButton
                editButton
                aiMenuButton
            }
            .padding(.horizontal, AppUI.small)
            .padding(.vertical, AppUI.tiny)
            .background(Color.appCard.opacity(0.5))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.appBorder.opacity(0.3), lineWidth: 1))
        }
    }
    
    private var pinButton: some View {
        Button(action: { viewModel.togglePin() }) {
            Image(systemName: viewModel.page.isPinned ? AppUI.Icons.pin + ".fill" : AppUI.Icons.pin)
                .foregroundStyle(viewModel.page.isPinned ? .orange : .appSecondary)
        }
        .accessibilityLabel(viewModel.page.isPinned ? Localized.tr("page.unpin") : Localized.tr("page.pin"))
    }
    
    private var backlinksButton: some View {
        Button(action: { viewModel.showBacklinks.toggle() }) {
            HStack(spacing: AppUI.tiny) {
                Image(systemName: AppUI.Icons.link)
                Text("\(viewModel.backlinks.count)")
            }
            .foregroundStyle(.appText)
        }
        .accessibilityLabel(Localized.tr("page.backlinks"))
        .accessibilityValue(Localized.trf("page.backlinksCount", viewModel.backlinks.count))
    }
    
    private var editButton: some View {
        Button(action: {
            HapticFeedback.shared.trigger(.selection)
            if viewModel.isEditing {
                store.updatePage(viewModel.page, forceDeepScan: false)
            }
            viewModel.isEditing.toggle()
        }) {
            Image(systemName: viewModel.isEditing ? "checkmark.circle.fill" : AppUI.Icons.edit + ".circle.fill")
                .foregroundStyle(viewModel.isEditing ? .green : .appText)
        }
        .accessibilityLabel(viewModel.isEditing ? Localized.tr("page.doneEditing") : Localized.tr("page.edit"))
    }
    
    private var aiMenuButton: some View {
        Menu {
            Button(action: { aiStore.runPageAISummary(content: viewModel.page.content) }) {
                Label(Localized.tr("page.ai.summary"), systemImage: "wand.and.stars")
            }
            Button(action: { aiStore.runPageAIExtractActions(content: viewModel.page.content) }) {
                Label(Localized.tr("page.ai.extractActions"), systemImage: "checkmark.seal")
            }

            Menu {
                Button(action: { aiStore.performPageSynthesis(type: .mindmap, title: viewModel.page.title, content: viewModel.page.content) }) {
                    Label(Localized.tr("page.ai.mindmap"), systemImage: "rectangle.stack.badge.person.crop")
                }
                Button(action: { aiStore.performPageSynthesis(type: .quiz, title: viewModel.page.title, content: viewModel.page.content) }) {
                    Label(Localized.tr("page.ai.quiz"), systemImage: "questionmark.circle")
                }
                Button(action: { aiStore.performPageSynthesis(type: .slides, title: viewModel.page.title, content: viewModel.page.content) }) {
                    Label(Localized.tr("page.ai.slides"), systemImage: "play.rectangle")
                }
                Button(action: { aiStore.performPageSynthesis(type: .report, title: viewModel.page.title, content: viewModel.page.content) }) {
                    Label(Localized.tr("page.ai.report"), systemImage: "doc.text.magnifyingglass")
                }
                Button(action: { aiStore.performPageSynthesis(type: .infographic, title: viewModel.page.title, content: viewModel.page.content) }) {
                    Label(Localized.tr("page.ai.infographic"), systemImage: "chart.bar.doc.horizontal")
                }
            } label: {
                Label(Localized.tr("page.ai.lab"), systemImage: "flask")
            }
            
            Divider()
            Button(action: { viewModel.showSnapshotHistory = true }) {
                Label(Localized.tr("page.history"), systemImage: AppUI.Icons.history)
            }
            Button(action: { expandStub() }) {
                Label(Localized.tr("page.expandStub"), systemImage: "text.badge.plus")
            }
            Button(action: { findRelatedLinks() }) {
                Label(Localized.tr("page.findLinks"), systemImage: "link.badge.plus")
            }
        } label: {
            Image(systemName: AppUI.Icons.sparkles)
                .foregroundStyle(.appAccent)
        }
        .disabled(viewModel.isEditing)
    }
    
    var body: some View {
        @Bindable var viewModel = viewModel
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // Optimized spacing to reduce the gap between header and content
                    Color.clear.frame(height: 10)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        if aiStore.isProcessingPageAI || aiStore.activePageAIResult != nil {
                            aiResultDisplaySection
                                .id("aiResultSection")
                                .padding(.bottom, AppUI.standardPadding)
                        }
                    // Content
                    Group {
                        if viewModel.isEditing {
                            MarkdownEditorView(page: $viewModel.page, isEditing: $viewModel.isEditing)
                                .padding(.top, AppUI.wide)
                        } else if viewModel.page.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            emptyStateView
                        } else {
                            MarkdownRendererView(content: viewModel.page.content, isPrivate: viewModel.page.isPrivate, onLinkTap: { title in
                                navigateToPage(title)
                            })
                            .padding(.vertical)
                        }

                        Divider()
                            .background(Color.appBorder)

                        provenanceSection

                        semanticRecommendationsSection
                        
                        backlinksSection
                    }
                    .padding(.horizontal)
                }
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: AppUI.Layout.maxReadWidth)
        .frame(maxWidth: .infinity)
        .background(AppUI.Background.pageBackground(accentColor: Color.fromModelColorName(viewModel.page.type.colorName)))
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle("")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar { toolbarContent }
        .confirmationDialog(Localized.tr("page.confirmDelete"), isPresented: $viewModel.showDeleteConfirmation) {
            Button(Localized.trf("page.deletePageTitle", viewModel.page.title), role: .destructive) {
                viewModel.deletePage()
            }
            Button(L10n.Common.tr("cancel"), role: .cancel) {}
        } message: {
            Text(Localized.tr("page.deleteMessage"))
        }
        .sheet(isPresented: $viewModel.showBacklinks) {
            BacklinksView(page: viewModel.page)
        }
        .sheet(isPresented: $viewModel.showIconPicker) {
            NavigationStack {
                IconPickerView(selectedIcon: Binding(
                    get: { viewModel.page.customIcon },
                    set: { newIcon in
                        var updated = viewModel.page
                        updated.customIcon = newIcon
                        store.updatePage(updated, forceDeepScan: false)
                        viewModel.page = updated
                    }
                ))
            }
        }
        .onChange(of: viewModel.page) { _, newValue in
            if !viewModel.isEditing {
                store.updatePage(newValue, forceDeepScan: false)
            }
        }
        .safeAreaInset(edge: .top) {
            VStack(spacing: 0) {
                if !router.navigationHistory.isEmpty {
                    BreadcrumbView(history: router.navigationHistory) { id in
                        let targetPage = store.pages.first { $0.id == id }
                        if let target = targetPage {
                            navigateToPage(target.title)
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                PageDetailHeader(page: viewModel.page, heroNamespace: heroNamespace)
                    .padding(.top, router.navigationHistory.isEmpty ? AppUI.Layout.tightPadding : 0)
                    .background(.ultraThinMaterial)
            }
            .frame(maxWidth: AppUI.Layout.maxReadWidth)
            .overlay(
                Divider().background(Color.appBorder),
                alignment: .bottom
            )
        }
        .sheet(isPresented: $viewModel.showSnapshotHistory) {
            PageHistoryView(page: viewModel.page)
        }
        .onAppear {
            router.addToHistory(viewModel.page)
            Task {
                recommendations = await aiStore.findSimilarPages(for: viewModel.page)
            }
        }
        .onChange(of: viewModel.page) { _, newValue in
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
            VStack(alignment: .leading, spacing: AppUI.medium) {
                HStack {
                    Image(systemName: AppUI.Icons.sparkles)
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
                                    try? await workflowService.syncToReminders(text: result, title: viewModel.page.title)
                                }
                            }) {
                                Label(L10n.Common.tr("syncToReminders"), systemImage: "checklist")
                                    .font(.caption)
                                    .foregroundStyle(.appAccent)
                            }
                            .padding(.trailing, AppUI.small)
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
                    VStack(alignment: .leading, spacing: AppUI.medium) {
                        AppSkeleton(height: 20)
                            .frame(width: 200)
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
        VStack(spacing: AppUI.medium) {
            Image(systemName: "pencil.line")
                .font(.system(size: AppUI.huge))
                .foregroundStyle(.appSecondary)
            Text(Localized.tr("page.empty"))
                .font(.subheadline)
                .foregroundStyle(.appSecondary)
            Text(Localized.tr("page.emptyHint"))
                .font(.caption)
                .foregroundStyle(.appAccent.opacity(0.7))
                .padding(.horizontal, AppUI.wide)
                .padding(.vertical, AppUI.small)
                .background(Color.appAccent.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: AppUI.smallRadius))
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
    
    private var provenanceSection: some View {
        Group {
            if let sourceURL = viewModel.page.sourceURL, let url = URL(string: sourceURL) {
                VStack(alignment: .leading, spacing: AppUI.tightPadding) {
                    HStack {
                        Image(systemName: "safari")
                            .foregroundStyle(.appAccent)
                        Text(Localized.tr("page.source.title"))
                            .font(.headline)
                            .foregroundStyle(.appText)
                        Spacer()
                        Link(destination: url) {
                            HStack(spacing: AppUI.tiny) {
                                Text(Localized.tr("page.source.open"))
                                Image(systemName: "arrow.up.right.circle")
                            }
                            .font(.caption)
                            .foregroundStyle(.appAccent)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(sourceURL)
                            .font(.caption2)
                            .foregroundStyle(.appSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        if let snippet = viewModel.page.rawTextSnippet, !snippet.isEmpty {
                            Text(snippet)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.appSecondary)
                                .padding(AppUI.small)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppUI.Background.cardBackground())
                                .clipShape(RoundedRectangle(cornerRadius: AppUI.microRadius))
                                .lineLimit(3)
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
                VStack(alignment: .leading, spacing: AppUI.medium) {
                    HStack(spacing: AppUI.small) {
                        ZStack {
                            Circle()
                                .fill(Color.appAccent.opacity(0.1))
                                .frame(width: 24, height: 24)
                            Image(systemName: AppUI.Icons.sparkles)
                                .font(.system(size: AppUI.iconTiny))
                                .foregroundStyle(.appAccent)
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(Localized.tr("page.aiInsights"))
                                .font(.headline)
                                .foregroundStyle(.appText)
                            Text(Localized.tr("page.aiInsights.desc"))
                                .font(.system(size: 9))
                                .foregroundStyle(.appSecondary)
                        }
                    }
                    .padding(.bottom, AppUI.tiny)
                    
                    VStack(spacing: AppUI.tightPadding) {
                        ForEach(recommendations) { recPage in
                            recommendationRow(for: recPage)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppUI.largeRadius)
                        .fill(Color.appAccent.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppUI.largeRadius)
                        .stroke(
                            LinearGradient(colors: [.appAccent.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )
                .padding(.vertical)
            }
        }
    }
    
    private func recommendationRow(for recPage: KnowledgePage) -> some View {
        NavigationLink(value: AppRoute.pageDetail(id: recPage.id)) {
            HStack {
                Image(systemName: recPage.displayIcon)
                    .foregroundStyle(Color.fromModelColorName(recPage.type.colorName))
                VStack(alignment: .leading, spacing: 2) {
                    Text(recPage.title)
                        .font(.subheadline.weight(.medium))
                    let summaryText = String(recPage.content.prefix(60)) + "..."
                    Text(summaryText)
                        .font(.caption2)
                        .foregroundStyle(.appSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.appSecondary)
            }
            .padding(AppUI.medium)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: AppUI.tightPadding))
            .overlay(
                RoundedRectangle(cornerRadius: AppUI.tightPadding)
                    .stroke(LinearGradient(colors: [.appAccent.opacity(0.3), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var backlinksSection: some View {
        VStack(alignment: .leading, spacing: AppUI.medium) {
            HStack {
                Image(systemName: AppUI.Icons.link)
                    .foregroundStyle(.appAccent)
                Text(Localized.tr("page.backlinks"))
                    .font(.headline)
                    .foregroundStyle(.appText)
                Text("(\(viewModel.backlinks.count))")
                    .font(.subheadline)
                    .foregroundStyle(.appSecondary)
            }
            
            if viewModel.backlinks.isEmpty {
                Text(Localized.tr("page.noBackLinks"))
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
                    .padding(.vertical, AppUI.small)
            } else {
                ForEach(viewModel.backlinks) { linkedPage in
                    NavigationLink(value: AppRoute.pageDetail(id: linkedPage.id)) {
                        HStack(spacing: AppUI.medium) {
                            Image(systemName: linkedPage.displayIcon)
                                .foregroundStyle(Color.fromModelColorName(linkedPage.type.colorName))
                                .frame(width: 28, height: 28)
                                .background(Color.fromModelColorName(linkedPage.type.colorName).opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: AppUI.microRadius))

                            Text(linkedPage.title)
                                .font(.subheadline)
                                .foregroundStyle(.appText)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.appSecondary)
                        }
                        .padding(.horizontal, AppUI.tightPadding)
                        .padding(.vertical, AppUI.small)
                        .background(Color.appCard)
                        .clipShape(RoundedRectangle(cornerRadius: AppUI.smallRadius))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Localized.trf("page.backlinkAccessibility", linkedPage.title, linkedPage.type.displayName))
                    .accessibilityHint(Localized.tr("page.doubleTapToNavigate"))
                }
            }
        }
        .padding()
    }
    
    private func expandStub() {
        aiStore.runPageAIExpansion(content: viewModel.page.content)
    }
    private func findRelatedLinks() { Task { await aiStore.runAIScan() } }
    private func navigateToPage(_ title: String) {
        if let target = store.pages.first(where: { $0.title == title }) {
            router.navigate(to: .pageDetail(id: target.id))
        }
    }
}

// MARK: - Internal Sections
struct AILabSection: View {
    let page: KnowledgePage
    @Environment(AIWorkflowStore.self) var aiStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppUI.medium) {
            Label(Localized.tr("page.ai.lab"), systemImage: "flask.fill")
                .font(.headline)
                .foregroundStyle(.appAccent)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppUI.small) {
                    AIActionButton(title: Localized.tr("page.ai.summary"), icon: "wand.and.stars") {
                        aiStore.runPageAISummary(content: page.content)
                    }
                    AIActionButton(title: Localized.tr("page.ai.quiz"), icon: "questionmark.circle") {
                        aiStore.performPageSynthesis(type: .quiz, title: page.title, content: page.content)
                    }
                    AIActionButton(title: Localized.tr("page.ai.mindmap"), icon: "rectangle.stack.badge.person.crop") {
                        aiStore.performPageSynthesis(type: .mindmap, title: page.title, content: page.content)
                    }
                }
            }
        }
        .padding()
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: AppUI.cardRadius))
    }
}

private struct AIActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppUI.tiny) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption2.weight(.medium))
            }
            .padding(.horizontal, AppUI.medium)
            .padding(.vertical, AppUI.small)
            .background(Color.appAccent.opacity(0.1))
            .foregroundStyle(.appAccent)
            .clipShape(RoundedRectangle(cornerRadius: AppUI.smallRadius))
        }
    }
}
