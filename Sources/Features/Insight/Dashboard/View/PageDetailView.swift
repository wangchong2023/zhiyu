//
//  PageDetailView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：构建 PageDetail 界面的 UI 视图层组件。
//
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
            Image(systemName: coordinator.page.isPinned ? DesignSystem.Icons.pinFill : DesignSystem.Icons.pin)
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
            Image(systemName: coordinator.isEditing ? DesignSystem.Icons.checkCircle : DesignSystem.Icons.edit + ".circle.fill")
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
                Label(L10n.Knowledge.Page.AI.summary, systemImage: DesignSystem.Icons.aiSummary)
            }
            Button(action: { coordinator.extractActions() }) {
                Label(L10n.Knowledge.Page.AI.extractActions, systemImage: DesignSystem.Icons.aiExtract)
            }

            Menu {
                Button(action: { coordinator.performSynthesis(type: .mindmap) }) {
                    Label(L10n.Knowledge.Page.AI.mindmap, systemImage: DesignSystem.Icons.mindmap)
                }
                Button(action: { coordinator.performSynthesis(type: .quiz) }) {
                    Label(L10n.Knowledge.Page.AI.quiz, systemImage: DesignSystem.Icons.quiz)
                }
                Button(action: { coordinator.performSynthesis(type: .slides) }) {
                    Label(L10n.Knowledge.Page.AI.slides, systemImage: DesignSystem.Icons.slides)
                }
                Button(action: { coordinator.performSynthesis(type: .report) }) {
                    Label(L10n.Knowledge.Page.AI.report, systemImage: DesignSystem.Icons.report)
                }
                Button(action: { coordinator.performSynthesis(type: .infographic) }) {
                    Label(L10n.Knowledge.Page.AI.infographic, systemImage: DesignSystem.Icons.infographic)
                }
            } label: {
                Label(L10n.Knowledge.Page.AI.lab, systemImage: DesignSystem.Icons.lab)
            }
            
            Divider()
            Button(action: { coordinator.showSnapshotHistory = true }) {
                Label(L10n.Knowledge.Page.History.title, systemImage: DesignSystem.Icons.history)
            }
            Button(action: { coordinator.expandContent() }) {
                Label(L10n.Knowledge.Page.expandStub, systemImage: DesignSystem.Icons.expandStub)
            }
            Button(action: { coordinator.findRelatedLinks() }) {
                Label(L10n.Knowledge.Page.findLinks, systemImage: DesignSystem.Icons.findLinks)
            }
        } label: {
            Image(systemName: DesignSystem.Icons.sparkles)
                .foregroundStyle(.appAccent)
        }
        .disabled(coordinator.isEditing)
        #endif
    }
    private var welcomeAhaPromptCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            HStack(spacing: DesignSystem.small) {
                Image(systemName: DesignSystem.Icons.sparkles)
                    .font(.title2)
                    .foregroundStyle(LinearGradient(
                        colors: [.appAccent, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                Text(L10n.Common.Demo.Welcome.cardTitle)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.appText)
            }
            
            Text(L10n.Common.Demo.Welcome.cardDesc)
                .font(.subheadline)
                .foregroundStyle(.appSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Button(action: {
                HapticFeedback.shared.trigger(.selection)
                router.pendingInitialChatPrompt = L10n.Common.Demo.Welcome.prompt
                router.navigateToTool(.chat)
            }) {
                HStack(spacing: DesignSystem.small) {
                    Text("\(L10n.Common.Demo.Welcome.cardRecommend)\"\(L10n.Common.Demo.Welcome.prompt)\"")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Image(systemName: DesignSystem.Icons.arrowRight)
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, DesignSystem.medium)
                .padding(.vertical, DesignSystem.small)
                .background(
                    LinearGradient(
                        colors: [.appAccent, .appAccent.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .appAccent.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(DesignSystem.standardPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .fill(Color.appCard.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(
                    LinearGradient(
                        colors: [.appAccent.opacity(0.4), .orange.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.vertical, DesignSystem.medium)
    }
    
    var body: some View {
        @Bindable var coordinator = coordinator
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 10)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        PageDetailAISection(pageTitle: coordinator.page.title, onLinkTap: navigateToPage)
                            .id("aiResultSection")
                            .padding(.bottom, DesignSystem.standardPadding)
                        
                        Group {
                            PageDetailContentSection(page: $coordinator.page, isEditing: $coordinator.isEditing, onLinkTap: navigateToPage)
                            
                            if coordinator.page.title == L10n.Common.Demo.Welcome.title {
                                welcomeAhaPromptCard
                            }
                            
                            Divider().background(Color.appBorder)
                            
                            PageDetailMetadataSection(page: coordinator.page, backlinks: coordinator.backlinks, recommendations: recommendations)
                        }
                        .padding(.horizontal)
                    }
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
        .confirmationDialog(L10n.Knowledge.Page.confirmDelete, isPresented: $coordinator.showDeleteConfirmation) {
            let deleteTitle = L10n.Vault.Page.deletePageTitle(coordinator.page.title)
            Button(deleteTitle, role: .destructive) {
                Task { await coordinator.deletePage() }
            }
            Button(L10n.Common.cancel, role: .cancel) {}
        } message: {
            Text(L10n.Knowledge.Page.deleteMessage)
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

    private func navigateToPage(_ title: String) {
        if let target = store.pages.first(where: { $0.title == title }) {
            router.navigate(to: .pageDetail(id: target.id))
        }
    }
}

// MARK: - Text Extension for aiInsightsVal
extension Text {
    init(_ aiInsights: L10n.Knowledge.Page.AIInsightsVal) {
        self.init(aiInsights.title)
    }
}
