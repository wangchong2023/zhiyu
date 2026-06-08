//
//  PromptWorkshopView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：构建 PromptWorkshop 界面的 UI 视图层组件。
//
import SwiftUI

struct PromptWorkshopView: View {
    /// 全局提示词管理服务
    @StateObject private var promptService = PromptService.shared
    
    /// 视图 dismiss 环境变量
    @Environment(\.dismiss) private var dismiss
    
    /// 全局主题管理器，用于获取统一的高级毛玻璃背景
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var isIntroExpanded = true
    @State private var isMindmapExpanded = false
    @State private var isQuizExpanded = false
    @State private var isSlidesExpanded = false
    @State private var isReportExpanded = false
    @State private var showResetAlert = false
    
    var body: some View {
        ZStack {
            // 背景统一使用主题管理器驱动的通透背景，透射毛玻璃效果
            themeManager.pageBackground()
                .ignoresSafeArea()
            
            Form {
                // ── 认知补全：功能简介 (可收缩) ──
                Section {
                    #if os(watchOS)
                    VStack(alignment: .leading, spacing: DesignSystem.medium) {
                        Label(L10n.AI.Prompt.Workshop.Intro.title, systemImage: DesignSystem.Icons.promptWorkshop)
                            .font(.headline)
                            .foregroundStyle(.appAccent)
                        Text(L10n.AI.Prompt.Workshop.Intro.desc)
                            .font(.subheadline)
                            .foregroundStyle(.appSecondary)
                    }
                    #else
                    DisclosureGroup(isExpanded: $isIntroExpanded) {
                        VStack(alignment: .leading, spacing: DesignSystem.medium) {
                            Text(L10n.AI.Prompt.Workshop.Intro.desc)
                                .font(.subheadline)
                                .foregroundStyle(.appSecondary)
                                .lineSpacing(4)
                                .padding(.top, DesignSystem.tiny)
                        }
                    } label: {
                        HStack(spacing: DesignSystem.medium) {
                            Image(systemName: DesignSystem.Icons.promptWorkshop)
                                .font(.title3)
                                .foregroundStyle(.appAccent)
                            Text(L10n.AI.Prompt.Workshop.Intro.title)
                                .font(.headline)
                        }
                    }
                    #endif
                }
                .appListRowBackground() // 适配全局毛玻璃背景

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
                .appListRowBackground() // 适配全局毛玻璃背景

                // ── 模块 2：恢复默认选项 ──
                Section {
                    Button(role: .destructive, action: { showResetAlert = true }) {
                        HStack {
                            Spacer()
                            Text(L10n.AI.Prompt.reset.factory)
                            Spacer()
                        }
                    }
                }
                .appListRowBackground() // 适配全局毛玻璃背景
            }
            .scrollContentBackground(.hidden) // 隐藏 Form 默认的白色背景，实现高端毛玻璃穿透
        }
        .navigationTitle(L10n.AI.Prompt.factory.title)
.appNavigationBarTitleDisplayMode(.inline)
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