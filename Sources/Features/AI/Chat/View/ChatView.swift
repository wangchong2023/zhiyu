//
//  ChatView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：构建 Chat 界面的 UI 视图层组件。
//
import SwiftUI
#if canImport(WebKit)
import WebKit
#endif

// MARK: - 导航入口
struct ChatView: View {
    @Binding var selectedTab: AppTab
    var body: some View {
        ChatViewContent(selectedTab: $selectedTab)
    }
}

// MARK: - 视图核心
struct ChatViewContent: View {
    @Environment(AppStore.self) var store
    @Environment(Router.self) var router
    @EnvironmentObject var llmService: LLMService
    @StateObject private var promptService = PromptService.shared
    @Binding var selectedTab: AppTab
    
    // 使用协调器管理状态与交互
    @State private var coordinator = ChatCoordinator()
    
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            PageBackgroundView(accentColor: .appAccent)
                .ignoresSafeArea(edges: .top)
            
            VStack(spacing: 0) {
                if !llmService.isEnabled || llmService.apiKey.isEmpty {
                    notConfiguredBanner
                }

                chatMessageList

                chatInputBar
            }
        }
        .appTabToolbar(title: "") {
            chatMenu
        }
        #if !os(watchOS)
        .sheet(item: $coordinator.exportURL) { identifiable in
            ActivityView(activityItems: [identifiable.url])
        }
        #endif
        .alert(L10n.Common.error, isPresented: $coordinator.showError) {
            Button(L10n.Common.ok) { coordinator.errorMessage = nil }
        } message: {
            Text(coordinator.errorMessage ?? "")
        }
        .confirmationDialog(
            L10n.Chat.clearHistoryConfirmTitle,
            isPresented: $coordinator.showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.Common.delete, role: .destructive) {
                coordinator.clearChatHistory()
            }
            Button(L10n.Common.cancel, role: .cancel) { }
        } message: {
            Text(L10n.Chat.clearHistoryConfirmMessage)
        }
        .task {
            await coordinator.loadInsightfulQuestions(pages: store.pages)
            
            // MARK: - [Cold Start Aha Moment] 自动识别并投递向导提问 Prompt
            if let prompt = router.pendingInitialChatPrompt, !prompt.isEmpty {
                // 立即清空，确保该 Prompt 在整个生命周期中仅被单次且安全消费
                router.pendingInitialChatPrompt = nil
                
                // 自动装填至对话框
                coordinator.inputText = prompt
                
                // 阻尼等待，保证过渡过渡的弹性动效平滑呈现
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                // 即刻触发 RAG 检索回答流
                await coordinator.sendMessage(pages: store.pages)
            }
        }
    }
    
    @ViewBuilder
    private var chatMenu: some View {
        #if !os(watchOS)
        Menu {
            Section {
                Button(action: { }) {
                    Label("\(coordinator.chatHistory.count) \(L10n.AI.LLM.messages)", systemImage: DesignSystem.Icons.chatBubble)
                }
                .disabled(true)
                
                Button(role: .destructive, action: { 
                    coordinator.showClearConfirmation = true
                }) {
                    Label(L10n.AI.LLM.clearHistory, systemImage: DesignSystem.Icons.delete)
                }
            }
            
            if !coordinator.chatHistory.isEmpty {
                Section(L10n.Chat.exportConversation) {
                    Button(action: {
                        coordinator.toggleSelectionMode()
                    }) {
                        Label(coordinator.isSelectionMode ? L10n.Common.done : L10n.Chat.selectToExport, systemImage: coordinator.isSelectionMode ? DesignSystem.Icons.checkCircle : DesignSystem.Icons.checklist)
                    }

                    Button(action: {
                        Task { await coordinator.exportChat() }
                    }) {
                        Label(coordinator.isSelectionMode && !coordinator.selectedMessageIDs.isEmpty ? L10n.Chat.exportSelectedPDF : L10n.Chat.exportPDF, systemImage: DesignSystem.Icons.docRichtext)
                    }
                }
            }
            
            Section {
                NavigationLink(destination: LLMSettingsView()) {
                    Label(L10n.Chat.llmSettings, systemImage: DesignSystem.Icons.settings)
                }
            }
        } label: {
            Image(systemName: DesignSystem.Icons.more)
                .font(.callout.weight(.bold))
                .foregroundStyle(.appSecondary)
        }
        .buttonStyle(.plain)  // 消除 Toolbar 中 Menu 的 bordered 白色背景
        #endif
    }
    
    private var notConfiguredBanner: some View {
        NavigationLink(destination: LLMSettingsView()) {
            HStack(spacing: DesignSystem.small + DesignSystem.atomic) {
                Image(systemName: DesignSystem.Icons.warning).foregroundStyle(.orange)
                Text(L10n.Chat.configureFirst).font(.subheadline).foregroundStyle(.appText)
                Spacer()
                Image(systemName: DesignSystem.Icons.forward).font(.caption).foregroundStyle(.appSecondary)
            }
            .padding().background(Color.orange.opacity(DesignSystem.Opacity.glass))
        }
        .buttonStyle(.plain)
    }
    
    private var chatMessageList: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.medium) {
                if coordinator.chatHistory.isEmpty && !coordinator.isProcessing {
                    ChatWelcomeView()
                        .environment(coordinator)
                } else {
                    if coordinator.isProcessing {
                        streamingBubble.id("processing")
                    }
                    ForEach(coordinator.chatHistory.reversed()) { message in
                        messageRow(for: message)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.tiny)
            .padding(.bottom, DesignSystem.standardPadding)
        }
        .scrollIndicators(.hidden)
    }
    
    @ViewBuilder
    private func messageRow(for message: ChatMessage) -> some View {
        ChatBubbleView(
            message: message, 
            pages: store.pages, 
            selectedTab: $selectedTab,
            isSelectionMode: coordinator.isSelectionMode,
            isSelected: coordinator.selectedMessageIDs.contains(message.id)
        )
        .id(message.id)
        .overlay {
            if coordinator.isSelectionMode {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        coordinator.toggleMessageSelection(message.id)
                    }
            }
        }
    }
    
    private var streamingBubble: some View {
        HStack(alignment: .top, spacing: DesignSystem.tightPadding) {
            Image(systemName: DesignSystem.Icons.thinking)
                .font(DesignSystem.secondaryFont)
                .foregroundStyle(.appAccent)
                .frame(width: DesignSystem.titleIconSize * DesignSystem.Domain.AI.Chat.bubbleIconScale, height: DesignSystem.titleIconSize * DesignSystem.Domain.AI.Chat.bubbleIconScale)
                .background(Color.appAccent.opacity(DesignSystem.Opacity.glass * 1.5))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: DesignSystem.tiny + DesignSystem.atomic) {
                if coordinator.streamingContent.isEmpty {
                    // 获取当前活跃任务的阶段
                    let stage: TaskStage = {
                        if let runningTask = TaskCenter.shared.tasks.first(where: { if case .running = $0.status { return true }; return false }) {
                            if case .running(_, let stage) = runningTask.status {
                                return stage
                            }
                        }
                        return .general
                    }()
                    
                    AppAILoadingSkeleton(stage: stage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    MarkdownRendererView(content: coordinator.streamingContent, isPrivate: false, onLinkTap: { _ in }, isCompact: true)
                        .padding(DesignSystem.medium)
                        .background(Color.appCard)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
                }
            }
            Spacer(minLength: DesignSystem.largeIconSize * 0.8)
        }
    }
    
    private var chatInputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .center, spacing: DesignSystem.medium) {
                Button(action: { coordinator.showPrompts.toggle() }) {
                    Image(systemName: DesignSystem.Icons.promptLibrary).font(.title3)
                        .foregroundStyle(coordinator.isProcessing ? .appSecondary.opacity(DesignSystem.Opacity.disabled) : .appAccent)
                        .frame(width: DesignSystem.Action.buttonHeight, height: DesignSystem.Action.buttonHeight)
                        .background(Color.appCard).clipShape(Circle())
                }
                .buttonStyle(.plain).disabled(coordinator.isProcessing)
                
                TextField(coordinator.isProcessing ? L10n.Chat.aiRunning : L10n.Chat.inputPlaceholder, text: $coordinator.inputText)
                    .font(.subheadline).focused($isInputFocused)
                    .foregroundStyle(coordinator.isProcessing ? .appSecondary : .appText).textFieldStyle(.plain)
                    .disabled(coordinator.isProcessing).submitLabel(.send)
                    .onSubmit { if canSend { Task { await coordinator.sendMessage(pages: store.pages) } } }
                
                Button { 
                    if coordinator.isProcessing { coordinator.cancelCurrentRequest() }
                    else { HapticFeedback.shared.trigger(.selection); Task { await coordinator.sendMessage(pages: store.pages) } }
                } label: {
                    Image(systemName: coordinator.isProcessing ? DesignSystem.Icons.stop : DesignSystem.Icons.send)
                        .font(.title2).foregroundStyle(coordinator.isProcessing ? .red : (canSend ? .appAccent : .appSecondary))
                        .symbolEffect(.bounce, value: coordinator.isProcessing)
                        .frame(width: DesignSystem.Action.inputBarHeight, height: DesignSystem.Action.inputBarHeight)
                }
                .disabled(!canSend && !coordinator.isProcessing)
            }
            .padding(.horizontal, DesignSystem.standardPadding).padding(.vertical, DesignSystem.tightPadding)
            .background(coordinator.isProcessing ? Color.appCard.opacity(DesignSystem.Opacity.soft) : Color.appCard)
            .sheet(isPresented: $coordinator.showPrompts) {
                NavigationStack {
                    ChatWelcomeView(isSheet: true)
                        .environment(coordinator)
                        .navigationTitle(L10n.Chat.explorationAndPrompts)
#if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
#endif
                        .toolbar { ToolbarItem(placement: .automatic) { Button(L10n.Common.close) { coordinator.showPrompts = false } } }
                }
                .presentationDetents([.medium, .large])
            }
        }
    }
    
    private var canSend: Bool {
        !coordinator.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !coordinator.isProcessing
    }
}
