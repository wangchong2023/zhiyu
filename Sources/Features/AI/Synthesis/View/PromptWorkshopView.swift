// PromptWorkshopView.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：struct PromptWorkshopView
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
//   - 更新: 2026-05-03
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

struct PromptWorkshopView: View {
    @StateObject private var promptService = PromptService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isIntroExpanded = true
    @State private var isMindmapExpanded = false
    @State private var isQuizExpanded = false
    @State private var isSlidesExpanded = false
    @State private var isReportExpanded = false
    @State private var showResetAlert = false
    
    var body: some View {
        Form {
            // ── 认知补全：功能简介 (可收缩) ──
            Section {
                #if os(watchOS)
                VStack(alignment: .leading, spacing: 12) {
                    Label(L10n.AI.Prompt.Workshop.Intro.title, systemImage: DesignSystem.Icons.promptWorkshop)
                        .font(.headline)
                        .foregroundStyle(.appAccent)
                    Text(L10n.AI.Prompt.Workshop.Intro.desc)
                        .font(.subheadline)
                        .foregroundStyle(.appSecondary)
                }
                #else
                DisclosureGroup(isExpanded: $isIntroExpanded) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.AI.Prompt.Workshop.Intro.desc)
                            .font(.subheadline)
                            .foregroundStyle(.appSecondary)
                            .lineSpacing(4)
                            .padding(.top, 4)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: DesignSystem.Icons.promptWorkshop)
                            .font(.title3)
                            .foregroundStyle(.appAccent)
                        Text(L10n.AI.Prompt.Workshop.Intro.title)
                            .font(.headline)
                    }
                }
                #endif
            }

            // ── 模块 1：我的快捷指令 (默认展开) ──
            Section {
                ForEach($promptService.userShortcuts) { $item in
                    HStack {
                        TextField(L10n.AI.Prompt.workshop.input.placeholder, text: $item.text)
                            .font(.subheadline)
                        
                        if promptService.userShortcuts.count > 1 {
                            Image(systemName: DesignSystem.Icons.line3Horizontal)
                                .foregroundStyle(.appSecondary.opacity(0.5))
                        }
                    }
                }
                .onDelete { indices in
                    promptService.userShortcuts.remove(atOffsets: indices)
                }
                .onMove { from, to in
                    promptService.userShortcuts.move(fromOffsets: from, toOffset: to)
                }
                
                Button(action: { 
                    promptService.userShortcuts.append(ShortcutItem(text: L10n.AI.Prompt.workshop.add))
                }) {
                    Label(L10n.AI.Prompt.workshop.add, systemImage: DesignSystem.Icons.plusCircle)
                        .font(.subheadline)
                        .foregroundStyle(.appAccent)
                }
            } header: {
                Label(L10n.AI.Prompt.workshop.shortcuts.title, systemImage: DesignSystem.Icons.pinFill)
            } footer: {
                Text(L10n.AI.Prompt.workshop.shortcuts.footer)
            }

            
            Section {
                Button(role: .destructive, action: { showResetAlert = true }) {
                    HStack {
                        Spacer()
                        Text(L10n.AI.Prompt.reset.factory)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(L10n.AI.Prompt.factory.title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .scrollContentBackground(.hidden)
        .listRowBackground(Color.appCard.opacity(0.8))
        .background(PageBackgroundView(accentColor: .appAccent))
        .onDisappear {
            promptService.save()
            HapticFeedback.shared.trigger(.success)
        }
        .alert(L10n.AI.Prompt.resetConfirm, isPresented: $showResetAlert) {
            Button(L10n.Common.reset, role: .destructive) {
                promptService.reset()
            }
            Button(L10n.Common.cancel, role: .cancel) {}
        } message: {
            Text(L10n.AI.Prompt.resetWarning)
        }
    }
}
