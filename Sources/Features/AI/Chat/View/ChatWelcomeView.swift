// ChatWelcomeView.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：AI 助手欢迎与引导视图，展示指令快捷方式及 AI 启发式问题。
// 版本: 1.0
// 修改记录:
//   - 2026-05-15: 从 ChatView 物理拆分，实现组件化。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

struct ChatWelcomeView: View {
    let isSheet: Bool
    @Environment(ChatCoordinator.self) var coordinator
    @Environment(AppStore.self) var store
    @StateObject private var promptService = PromptService.shared

    init(isSheet: Bool = false) {
        self.isSheet = isSheet
    }

    var body: some View {
        VStack(spacing: isSheet ? DesignSystem.medium : DesignSystem.small) {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.wide) {
                    // 1. 我的指令 (置顶)
                    SuggestionGroupView(
                        title: L10n.Chat.tr("group.user"),
                        icon: DesignSystem.Icons.pinFill,
                        queries: promptService.userShortcuts.map { $0.text }
                    )
                    
                    // 2. AI 启发 (动态生成)
                    if coordinator.isGeneratingAIQuestions {
                        HStack {
                            ProgressView().scaleEffect(0.8)
                            Text(L10n.Chat.tr("ai.thinking")).font(.caption).foregroundStyle(.appSecondary)
                        }.padding(.leading)
                    } else if !coordinator.insightfulQuestions.isEmpty {
                        SuggestionGroupView(
                            title: L10n.Chat.tr("group.ai"),
                            icon: DesignSystem.Icons.sparkles,
                            queries: coordinator.insightfulQuestions,
                            color: .appAccent
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct SuggestionGroupView: View {
    let title: String
    let icon: String
    let queries: [String]
    var color: Color = .appSecondary
    
    @Environment(ChatCoordinator.self) var coordinator
    @Environment(AppStore.self) var store

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.small + DesignSystem.atomic) {
            // 标题现在支持点击直接触发“总体探索”
            Button(action: {
                HapticFeedback.shared.trigger(.link)
                let query = Localized.trf("chat.deepExplorePrompt", title)
                Task { await coordinator.sendMessage(query: query, pages: store.pages) }
            }) {
                HStack(spacing: DesignSystem.tiny + DesignSystem.atomic) {
                    Image(systemName: icon).font(.caption2)
                    Text(title).font(.caption.weight(.bold))
                    Spacer()
                    Image(systemName: DesignSystem.Icons.promptLibrary)
                        .font(.system(size: DesignSystem.Metrics.heroValueSize * 0.38))
                        .opacity(0.5)
                }
                .foregroundStyle(color)
                .padding(.leading, DesignSystem.atomic * 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            ForEach(queries, id: \.self) { query in
                Button(action: { 
                    HapticFeedback.shared.trigger(.link)
                    coordinator.showPrompts = false
                    Task { await coordinator.sendMessage(query: query, pages: store.pages) }
                }) {
                    HStack {
                        Text(query).font(.subheadline).foregroundStyle(.appText).multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: DesignSystem.Icons.arrowUpRight).font(.caption2).foregroundStyle(.appAccent.opacity(0.7))
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
}
