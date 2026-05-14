// ChatView.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了知识管理系统的 AI 助手交互界面（ChatView），是用户与知识库进行语义化交互的核心入口。
// 视图通过以下功能点构建了高效且沉浸式的对话体验：
// 1. 语义化问答流：支持基于本地知识库的检索增强生成（RAG），通过流式渲染技术实时展示 AI 的思考与响应过程。
// 2. 多维度指令引导：集成了“我的指令”快捷方式、AI 动态生成的启发式问题以及基础功能引导，降低用户的使用门槛。
// 3. 灵活的消息管理：支持对话历史的导出（PDF/文本）、消息选择模式、上下文清除及 LLM 参数的实时配置。
// 4. 高级交互反馈：内置了带光晕效果的品牌图标、动态思考动画（PulsingDot）及触感反馈，确保对话过程具有良好的操作感知。
// 版本: 1.1
// 修改记录:
//   - 2026-05-05: 升级全工程文档规范，系统性清理聊天界面内部的魔鬼数字
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI
#if canImport(WebKit)
import WebKit
#endif

// MARK: - 导航入口
/// AI 助手对话功能主容器视图
/// 负责管理对话界面的顶层生命周期、导航路由及 AppTab 状态同步
struct ChatView: View {
    @Binding var selectedTab: AppTab
    var body: some View {
        ChatViewContent(selectedTab: $selectedTab)
    }
}

// MARK: - 视图核心
/// AI 助手对话核心业务视图
/// 负责消息流的异步渲染、输入状态管理、RAG 检索指令调度及对话历史导出逻辑
struct ChatViewContent: View {
    @Environment(AppStore.self) var store
    @EnvironmentObject var llmService: LLMService
    @StateObject private var promptService = PromptService.shared
    @Binding var selectedTab: AppTab
    @State private var chatVM = ChatViewModel()
    @State private var isExporting = false
    @State private var errorMessage: String?
    @State private var showError = false
    @FocusState private var isInputFocused: Bool
    @State private var isGeneratingAIQuestions = false
    @State private var showPrompts = false
#if canImport(WebKit)
    @State private var exportWebView: WKWebView?
#endif
    @State private var exportURL: IdentifiableURL?
    @State private var isSelectionMode = false
    @State private var selectedMessageIDs: Set<UUID> = []

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
        .sheet(item: $exportURL) { identifiable in
            ActivityView(activityItems: [identifiable.url])
        }
        #endif
        .alert(L10n.Common.tr("error"), isPresented: $showError) {
            Button(L10n.Common.tr("ok")) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .task {
            if !store.pages.isEmpty && llmService.isEnabled && chatVM.insightfulQuestions.isEmpty {
                isGeneratingAIQuestions = true
                await chatVM.loadInsightfulQuestions(pages: store.pages)
                isGeneratingAIQuestions = false
            }
        }
    }
    
    @ViewBuilder
    private var chatMenu: some View {
        #if !os(watchOS)
        Menu {
            Section {
                Button(action: { }) {
                    Label("\(chatVM.chatHistory.count) \(Localized.tr("llm.messages"))", systemImage: "bubble.left.and.bubble.right")
                }
                .disabled(true)
                
                Button(role: .destructive, action: { 
                    chatVM.clearChatHistory() 
                }) {
                    Label(Localized.tr("llm.clearHistory"), systemImage: "trash")
                }
            }
            
            if !chatVM.chatHistory.isEmpty {
                Section(L10n.Chat.tr("exportConversation")) {
                    Button(action: {
                        withAnimation {
                            isSelectionMode.toggle()
                            if !isSelectionMode { selectedMessageIDs.removeAll() }
                        }
                    }) {
                        Label(isSelectionMode ? L10n.Common.tr("done") : L10n.Chat.tr("selectToExport"), systemImage: isSelectionMode ? "checkmark.circle.fill" : "checklist")
                    }

                    Button(action: {
                        let history = isSelectionMode && !selectedMessageIDs.isEmpty ?
                            chatVM.chatHistory.filter { selectedMessageIDs.contains($0.id) } :
                            chatVM.chatHistory
                        Task {
                            do {
                                let url = try await chatVM.exportChat(history: history)
                                self.exportURL = IdentifiableURL(url: url)
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    }) {
                        Label(isSelectionMode && !selectedMessageIDs.isEmpty ? L10n.Chat.tr("exportSelectedPDF") : L10n.Chat.tr("exportPDF"), systemImage: "doc.richtext")
                    }
                }
            }
            
            Section {
                NavigationLink(destination: LLMSettingsView()) {
                    Label(L10n.Chat.tr("llmSettings"), systemImage: "gearshape")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.appSecondary)
        }
        #endif
    }
    
    // MARK: - Not Configured Banner
    private var notConfiguredBanner: some View {
        NavigationLink(destination: LLMSettingsView()) {
            HStack(spacing: DesignSystem.small + DesignSystem.atomic) { // 10
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(L10n.Chat.tr("configureFirst"))
                    .font(.subheadline)
                    .foregroundStyle(.appText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
            }
            .padding()
            .background(Color.orange.opacity(DesignSystem.glassOpacity)) // 0.1
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Chat Message List
    private var chatMessageList: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.medium) {
                if chatVM.chatHistory.isEmpty && !chatVM.isProcessing {
                    chatWelcome()
                } else {
                    // 正在处理中，就显示流式气泡（在最顶端）
                    if chatVM.isProcessing {
                        streamingBubble
                            .id("processing")
                    }

                    // 按照时间倒序排列，最新的在顶端
                    ForEach(chatVM.chatHistory.reversed()) { message in
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
            isSelectionMode: isSelectionMode,
            isSelected: selectedMessageIDs.contains(message.id)
        )
        .id(message.id)
        .overlay {
            if isSelectionMode {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedMessageIDs.contains(message.id) {
                            selectedMessageIDs.remove(message.id)
                        } else {
                            selectedMessageIDs.insert(message.id)
                        }
                        HapticFeedback.shared.trigger(.selection)
                    }
            }
        }
    }

    private func chatWelcome(isSheet: Bool = false) -> some View {
        VStack(spacing: isSheet ? DesignSystem.medium : DesignSystem.small) {
            // 直接展示提问建议列表，不再显示图标和标题
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.wide) { // 20
                    // 1. 我的指令 (置顶)
                    suggestionGroup(title: L10n.Chat.tr("group.user"), icon: "pin.fill", queries: promptService.userShortcuts.map { $0.text })
                    
                    // 2. AI 启发 (动态生成)
                    if isGeneratingAIQuestions {
                        HStack {
                            ProgressView()
                                .scaleEffect(DesignSystem.fullOpacity * 0.8) // 0.8
                            Text(L10n.Chat.tr("ai.thinking"))
                                .font(.caption)
                                .foregroundStyle(.appSecondary)
                        }
                        .padding(.leading)
                    } else if !chatVM.insightfulQuestions.isEmpty {
                        suggestionGroup(title: L10n.Chat.tr("group.ai"), icon: "sparkles", queries: chatVM.insightfulQuestions, color: .appAccent)
                    }
                    
                    // 3. 基础引导
                    suggestionGroup(title: L10n.Chat.tr("group.base"), icon: "lightbulb", queries: defaultQueries)
                }
                .padding(.horizontal)
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func suggestionGroup(title: String, icon: String, queries: [String], color: Color = .appSecondary) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.small + DesignSystem.atomic) { // 10
            // 标题现在支持点击直接触发“总体探索”
            Button(action: {
                HapticFeedback.shared.trigger(.link)
                let query = Localized.trf("chat.deepExplorePrompt", title)
                sendMessage(query)
            }) {
                HStack(spacing: DesignSystem.tiny + DesignSystem.atomic) { // 6
                    Image(systemName: icon)
                        .font(.caption2)
                    Text(title)
                        .font(.caption.weight(.bold))
                    Spacer()
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: DesignSystem.Metrics.heroValueSize * 0.38)) // 10
                        .opacity(DesignSystem.fullOpacity * 0.5) // 0.5
                }
                .foregroundStyle(color)
                .padding(.leading, DesignSystem.atomic * 2) // 4
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            ForEach(queries, id: \.self) { query in
                Button(action: { 
                    HapticFeedback.shared.trigger(.link)
                    showPrompts = false
                    // 立即填充并发送，解决“填充不提交”的问题
                    chatVM.inputText = query
                    sendMessage(query) 
                }) {
                    HStack {
                        Text(query)
                            .font(.subheadline)
                            .foregroundStyle(.appText)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.appAccent.opacity(DesignSystem.fullOpacity * 0.7)) // 0.7
                    }
                    .padding()
                    .background(Color.appCard)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.standardRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.standardRadius)
                            .stroke(Color.appBorder.opacity(DesignSystem.disabledOpacity), lineWidth: DesignSystem.borderWidth)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var defaultQueries: [String] {
        let conceptCount = store.pages.filter { $0.type == .concept }.count
        if conceptCount > 0 {
            return [L10n.Chat.tr("suggested.summarize"), L10n.Chat.tr("suggested.connections")]
        } else {
            return [L10n.Chat.tr("suggested.whatContent"), L10n.Chat.tr("suggested.organize")]
        }
    }
    
    // MARK: - Streaming Bubble
    private var streamingBubble: some View {
        HStack(alignment: .top, spacing: DesignSystem.tightPadding) {
            Image(systemName: "sparkles")
                .font(DesignSystem.secondaryFont)
                .foregroundStyle(.appAccent)
                .frame(width: DesignSystem.titleIconSize * 1.2, height: DesignSystem.titleIconSize * 1.2)
                .background(Color.appAccent.opacity(DesignSystem.glassOpacity * 1.5)) // 0.15
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: DesignSystem.tiny + DesignSystem.atomic) { // 6
                if llmService.streamingContent.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.tiny + DesignSystem.atomic) { // 6
                        Text(L10n.Chat.tr("aiThinking"))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.appAccent)
                        HStack(spacing: DesignSystem.atomic * 2) { // 4
                            ForEach(0..<3, id: \.self) { index in
                                Circle()
                                    .fill(Color.appAccent)
                                    .frame(width: DesignSystem.tiny + DesignSystem.atomic, height: DesignSystem.tiny + DesignSystem.atomic) // 6, 6
                                    .modifier(PulsingDot(delay: Double(index) * 0.2))
                            }
                        }
                    }
                } else {
                    MarkdownRendererView(
                        content: llmService.streamingContent,
                        isPrivate: false,
                        onLinkTap: { _ in },
                        isCompact: true
                    )
                }
            }
            .padding(DesignSystem.medium)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
            
            Spacer(minLength: DesignSystem.largeIconSize * 0.8)
        }
    }
    
    // MARK: - Chat Input Bar
    private var chatInputBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(alignment: .center, spacing: DesignSystem.medium) { // 12
                Button(action: { showPrompts.toggle() }) {
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.title3)
                        .foregroundStyle(chatVM.isProcessing ? .appSecondary.opacity(DesignSystem.disabledOpacity) : .appAccent)
                        .frame(width: DesignSystem.Action.buttonHeight, height: DesignSystem.Action.buttonHeight)
                        .background(Color.appCard)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(chatVM.isProcessing)
                
                TextField(chatVM.isProcessing ? L10n.Chat.tr("aiRunning") : L10n.Chat.tr("inputPlaceholder"), text: $chatVM.inputText)
                    .font(.subheadline)
                    .focused($isInputFocused)
                    .foregroundStyle(chatVM.isProcessing ? .appSecondary : .appText)
                    .textFieldStyle(.plain)
                    .disabled(chatVM.isProcessing)
                    .autocorrectionDisabled(false)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.send)
                    .onSubmit { 
                        if canSend { sendMessage() }
                    }
                
                Button { 
                    if chatVM.isProcessing {
                        chatVM.cancelCurrentRequest()
                    } else {
                        HapticFeedback.shared.trigger(.selection)
                        sendMessage() 
                    }
                } label: {
                    Image(systemName: chatVM.isProcessing ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(chatVM.isProcessing ? .red : (canSend ? .appAccent : .appSecondary))
                        .symbolEffect(.bounce, value: chatVM.isProcessing)
                        .frame(width: DesignSystem.Action.inputBarHeight, height: DesignSystem.Action.inputBarHeight)
                }
                .accessibilityIdentifier("send")
                .disabled(!canSend && !chatVM.isProcessing)
            }
            .padding(.horizontal, DesignSystem.standardPadding)
            .padding(.vertical, DesignSystem.tightPadding)
            .background(chatVM.isProcessing ? Color.appCard.opacity(DesignSystem.fullOpacity * 0.5) : Color.appCard) // 0.5
            .sheet(isPresented: $showPrompts) {
                NavigationStack {
                    chatWelcome(isSheet: true)
                        .navigationTitle(L10n.Chat.tr("explorationAndPrompts"))
#if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
#endif
                        .toolbar {
                            ToolbarItem(placement: .automatic) {
                                Button(L10n.Common.tr("close")) { showPrompts = false }
                            }
                        }
                }
                .presentationDetents([.medium, .large])
            }
        }
    }
    
    private var canSend: Bool {
        !chatVM.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !chatVM.isProcessing
    }
    
    // MARK: - Send Message
    private func sendMessage(_ overrideText: String? = nil) {
        let text = (overrideText ?? chatVM.inputText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        if chatVM.isProcessing {
            chatVM.cancelCurrentRequest()
            return
        }
        
        if overrideText == nil { chatVM.inputText = "" }
        errorMessage = nil
        
        Task {
            do {
                try await chatVM.sendChatMessage(query: text, pages: store.pages)
            } catch {
                await MainActor.run {
                    if case LLMError.notConfigured = error {
                        // Banner handles this
                    } else {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
        }
    }
}

