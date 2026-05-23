//
//  CommandPaletteView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：构建 CommandPalette 界面的 UI 视图层组件。
//
import SwiftUI

/// 全局指令中枢 (Command Palette)
/// 满足硬核用户 Cmd+K 盲操需求，极大缩短交互路径。
struct CommandPaletteView: View {
    @Environment(KnowledgeStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            HStack {
                Image(systemName: DesignSystem.Icons.command)
                    .foregroundStyle(.appAccent)
                TextField(L10n.Common.Palette.searchPlaceholder, text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                Text(L10n.Common.Global.esc)
                    .font(.caption2.weight(.bold))
                    .padding(DesignSystem.tiny)
                    .background(Color.appBorder.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .padding()
            .background(Color.appCard)
            
            Divider()
            
            // 结果列表
            List {
                Section(L10n.Action.cmd.quickActions) {
                    CommandRow(icon: DesignSystem.Icons.sparkles, title: L10n.Action.cmd.deepExplore, shortcut: "↵") {
                        // 触发逻辑
                        dismiss()
                    }
                    CommandRow(icon: DesignSystem.Icons.docBadgePlus, title: L10n.Action.cmd.newKnowledgePage, shortcut: "N") {
                        dismiss()
                    }
                }
                
                // 插件指令板块
                if !PluginRegistry.shared.commands.isEmpty {
                    let filteredCommands = PluginRegistry.shared.commands.filter { 
                        searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) 
                    }
                    
                    if !filteredCommands.isEmpty {
                        Section(L10n.Plugin.commands.title) {
                            ForEach(filteredCommands) { command in
                                CommandRow(icon: DesignSystem.Icons.pluginOutline, title: command.name) {
                                    command.action()
                                    dismiss()
                                }
                            }
                        }
                    }
                }
                
                Section(L10n.Action.cmd.recentAccess) {
                    ForEach(store.pages.prefix(3)) { page in
                        CommandRow(icon: page.pageType.icon, title: page.title) {
                            dismiss()
                        }
                    }
                }
            }
            .listStyle(.plain)
            .frame(height: 300)
        }
        .background(PageBackgroundView(accentColor: .appAccent))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.5), radius: 20)
        .frame(width: 500)
        .onAppear { isFocused = true }
    }
}

private struct CommandRow: View {
    let icon: String
    let title: String
    var shortcut: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                    .font(.subheadline)
                Spacer()
                if let sc = shortcut {
                    Text(sc)
                        .font(.caption2)
                        .foregroundStyle(.appSecondary)
                }
            }
        }
    }
}
