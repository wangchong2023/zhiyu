//
//  PluginToolbarMenu.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/10.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：全局插件中心工具栏菜单入口

import SwiftUI

/// 全局插件中心工具栏入口（右上角菜单）
struct PluginToolbarMenu: View {
    @Environment(Router.self) var router
    @ObservedObject var registry = PluginRegistry.shared

    var body: some View {
        Menu {
            Button(action: {
                HapticFeedback.shared.trigger(.selection)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    router.navigate(to: .pluginMarket)
                }
            }) {
                Label(L10n.Settings.Section.plugins, systemImage: "puzzlepiece.extension.fill")
            }

            if !registry.ribbonItems.isEmpty {
                Divider()
                ForEach(registry.ribbonItems) { item in
                    Button(action: {
                        HapticFeedback.shared.trigger(.selection)
                        item.action()
                    }) {
                        Label(item.title, systemImage: item.icon)
                    }
                }
            }
        } label: {
            Image(systemName: "puzzlepiece.extension.fill")
                .font(.caption)
                .foregroundStyle(.appAccent)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("pluginToolbarMenu")
    }
}
