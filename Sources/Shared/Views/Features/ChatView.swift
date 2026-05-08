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
import WebKit

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
    @State private var exportWebView: WKWebView?
    @State private var exportURL: IdentifiableURL?
    @State private var isSelectionMode = false
    @State private var selectedMessageIDs: Set<UUID> = []

    var body: some View {
        VStack(spacing: 0) {
            if !llmService.isEnabled || llmService.apiKey.isEmpty {
                notConfiguredBanner
            }

            chatMessageList

            chatInputBar
        }
        .background(Color.appBackground)
        .navigationTitle(L10n.Chat.tr("title"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    Section {
                        Button(action: { }) {
                            Label("\(llmService.chatHistory.count) \(Localized.tr("llm.messages"))", systemImage: "bubble.left.and.bubble.right")
                        }
                        .disabled(true)
                        
                        Button(role: .destructive, action: { 
                            llmService.clearChatHistory() 
                        }) {
                            Label(Localized.tr("llm.clearHistory"), systemImage: "trash")
                        }
                    }
                    
                    if !llmService.chatHistory.isEmpty {
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
                                    llmService.chatHistory.filter { selectedMessageIDs.contains($0.id) } :
                                    llmService.chatHistory
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
                        .foregroundStyle(.appSecondary)
                }
                .accessibilityIdentifier("menu")
            }
        }
        .sheet(item: $exportURL) { identifiable in
            ActivityView(activityItems: [identifiable.url])
        }
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
    
    // MARK: - Not Configured Banner
    private var notConfiguredBanner: some View {
        NavigationLink(destination: LLMSettingsView()) {
            HStack(spacing: AppUI.small + AppUI.atomic) { // 10
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
            .background(Color.orange.opacity(AppUI.glassOpacity)) // 0.1
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Chat Message List
    private var chatMessageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: AppUI.medium) {
                    if llmService.chatHistory.isEmpty && !llmService.isProcessing {
                        chatWelcome()
                    } else {
                        // 按照时间正序排列，最新的在最下面
                        ForEach(llmService.chatHistory) { message in
                            messageRow(for: message)
                        }

                        // 正在处理中，就显示流式气泡（在最下面）
                        if llmService.isProcessing {
                            streamingBubble
                                .id("processing")
                        }
                    }
                }
                .padding(.horizontal, AppUI.tiny)
                .padding(.bottom, AppUI.standardPadding)
            }
            .onChange(of: llmService.chatHistory.count) {
                // 当有新消息时，自动滚动到底部
                withAnimation { proxy.scrollTo(llmService.chatHistory.last?.id, anchor: .bottom) }
            }
            .onChange(of: llmService.isProcessing) {
                if llmService.isProcessing {
                    withAnimation { proxy.scrollTo("processing", anchor: .bottom) }
                }
            }
        }
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
        VStack(spacing: isSheet ? AppUI.medium : AppUI.small) { // 12, 8
            if !isSheet {
                // Remove Spacer to tighten layout

                // 带光晕的图标
                ZStack {
                    Circle()
                        .fill(Color.appAccent.opacity(AppUI.glassOpacity)) // 0.1
                        .frame(width: AppUI.largeIconSize * 1.6, height: AppUI.largeIconSize * 1.6)
                        .blur(radius: AppUI.medium)

                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: AppUI.largeIconSize * 0.75, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.appAccent, .appConcept],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .appAccent.opacity(AppUI.glassOpacity * 2), radius: AppUI.small, x: 0, y: AppUI.tiny)
                }

                Text(L10n.Chat.tr("welcomeTitle"))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.appText)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: AppUI.wide) { // 20
                    // 1. 我的指令 (置顶)
                    suggestionGroup(title: L10n.Chat.tr("group.user"), icon: "pin.fill", queries: promptService.userShortcuts.map { $0.text })
                    
                    // 2. AI 启发 (动态生成)
                    if isGeneratingAIQuestions {
                        HStack {
                            ProgressView()
                                .scaleEffect(AppUI.fullOpacity * 0.8) // 0.8
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
        VStack(alignment: .leading, spacing: AppUI.small + AppUI.atomic) { // 10
            // 标题现在支持点击直接触发“总体探索”
            Button(action: {
                HapticFeedback.shared.trigger(.link)
                let query = Localized.trf("chat.deepExplorePrompt", title)
                sendMessage(query)
            }) {
                HStack(spacing: AppUI.tiny + AppUI.atomic) { // 6
                    Image(systemName: icon)
                        .font(.caption2)
                    Text(title)
                        .font(.caption.weight(.bold))
                    Spacer()
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: AppUI.Metrics.heroValueSize * 0.38)) // 10
                        .opacity(AppUI.fullOpacity * 0.5) // 0.5
                }
                .foregroundStyle(color)
                .padding(.leading, AppUI.atomic * 2) // 4
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
                            .foregroundStyle(.appAccent.opacity(AppUI.fullOpacity * 0.7)) // 0.7
                    }
                    .padding()
                    .background(Color.appCard)
                    .clipShape(RoundedRectangle(cornerRadius: AppUI.standardRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppUI.standardRadius)
                            .stroke(Color.appBorder.opacity(AppUI.disabledOpacity), lineWidth: AppUI.borderWidth)
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
        HStack(alignment: .top, spacing: AppUI.tightPadding) {
            Image(systemName: "sparkles")
                .font(AppUI.secondaryFont)
                .foregroundStyle(.appAccent)
                .frame(width: AppUI.titleIconSize * 1.2, height: AppUI.titleIconSize * 1.2)
                .background(Color.appAccent.opacity(AppUI.glassOpacity * 1.5)) // 0.15
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: AppUI.tiny + AppUI.atomic) { // 6
                if llmService.streamingContent.isEmpty {
                    VStack(alignment: .leading, spacing: AppUI.tiny + AppUI.atomic) { // 6
                        Text(L10n.Chat.tr("aiThinking"))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.appAccent)
                        HStack(spacing: AppUI.atomic * 2) { // 4
                            ForEach(0..<3, id: \.self) { index in
                                Circle()
                                    .fill(Color.appAccent)
                                    .frame(width: AppUI.tiny + AppUI.atomic, height: AppUI.tiny + AppUI.atomic) // 6, 6
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
            .padding(AppUI.medium)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: AppUI.mediumRadius))
            
            Spacer(minLength: AppUI.largeIconSize * 0.8)
        }
    }
    
    // MARK: - Chat Input Bar
    private var chatInputBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(alignment: .center, spacing: AppUI.medium) { // 12
                Button(action: { showPrompts.toggle() }) {
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.title3)
                        .foregroundStyle(llmService.isProcessing ? .appSecondary.opacity(AppUI.disabledOpacity) : .appAccent)
                        .frame(width: AppUI.Action.buttonHeight, height: AppUI.Action.buttonHeight)
                        .background(Color.appCard)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(llmService.isProcessing)
                
                TextField(llmService.isProcessing ? L10n.Chat.tr("aiRunning") : L10n.Chat.tr("inputPlaceholder"), text: $chatVM.inputText)
                    .font(.subheadline)
                    .focused($isInputFocused)
                    .foregroundStyle(llmService.isProcessing ? .appSecondary : .appText)
                    .textFieldStyle(.plain)
                    .disabled(llmService.isProcessing)
                    .autocorrectionDisabled(false)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.send)
                    .onSubmit { 
                        if canSend { sendMessage() }
                    }
                
                Button { 
                    if llmService.isProcessing {
                        llmService.cancelCurrentRequest()
                    } else {
                        HapticFeedback.shared.trigger(.selection)
                        sendMessage() 
                    }
                } label: {
                    Image(systemName: llmService.isProcessing ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(llmService.isProcessing ? .red : (canSend ? .appAccent : .appSecondary))
                        .symbolEffect(.bounce, value: llmService.isProcessing)
                        .frame(width: AppUI.Action.inputBarHeight, height: AppUI.Action.inputBarHeight)
                }
                .accessibilityIdentifier("send")
                .disabled(!canSend && !llmService.isProcessing)
            }
            .padding(.horizontal, AppUI.standardPadding)
            .padding(.vertical, AppUI.tightPadding)
            .background(llmService.isProcessing ? Color.appCard.opacity(AppUI.fullOpacity * 0.5) : Color.appCard) // 0.5
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
        !chatVM.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !llmService.isProcessing
    }
    
    // MARK: - Send Message
    private func sendMessage(_ overrideText: String? = nil) {
        let text = (overrideText ?? chatVM.inputText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        if llmService.isProcessing {
            llmService.cancelCurrentRequest()
            return
        }
        
        if overrideText == nil { chatVM.inputText = "" }
        errorMessage = nil
        
        Task {
            do {
                try await llmService.sendChatMessage(query: text, pages: store.pages)
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

