//
//  SettingsComponents.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：系统设置：LLM 配置、性能监控、插件管理、iCloud、备份。
//
import SwiftUI

// MARK: - Settings Navigation Row
/// 设置页导航行，支持可选副标题和尾部视图。
/// 设置页通用导航行组件
/// 负责在列表样式中展示功能图标、标题、副标题，并提供标准化的导航跳转能力
struct SettingsNavigationRow<Destination: View, Trailing: View>: View {
    let icon: String
    let title: String
    let subtitle: String?
    let identifier: String?
    let destination: Destination
    let trailing: Trailing

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        identifier: String? = nil,
        @ViewBuilder destination: () -> Destination,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.identifier = identifier
        self.destination = destination()
        self.trailing = trailing()
    }

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: DesignSystem.tightPadding + DesignSystem.atomic) { // 10
                Label(title, systemImage: icon)
                    .foregroundStyle(.appText)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                }

                Spacer()

                trailing
            }
        }
        .accessibilityIdentifier(identifier ?? title)
    }
}

/// 便利初始化（无尾部视图）
extension SettingsNavigationRow where Trailing == EmptyView {
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        identifier: String? = nil,
        @ViewBuilder destination: () -> Destination
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.identifier = identifier
        self.destination = destination()
        self.trailing = EmptyView()
    }
}

// MARK: - Settings Stat Row
/// 设置页统计行：标签 + 值。
/// 设置页统计数据展示行组件
/// 负责在设置界面以简洁的键值对形式展示系统统计信息（如存储占用、页面总数等）
struct SettingsStatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(.appText)
            Spacer()
            Text(value)
                .foregroundStyle(.appSecondary)
        }
    }
}

// MARK: - Info Row
/// 信息提示行（图标 + 文字）。
/// 基础信息提示行组件
/// 负责以图标加文字的形式展示辅助信息或状态提示，通常用于说明页面功能
struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: DesignSystem.tightPadding + DesignSystem.atomic) { // 10
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.appText)
                .frame(width: DesignSystem.Action.iconSize + DesignSystem.tiny) // 24
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.appText)
            Spacer()
        }
    }
}

// MARK: - 插件扩展组件

struct PluginExtensionsSection: View {
    @ObservedObject var registry = PluginRegistry.shared

    var body: some View {
        if !registry.settingTabs.isEmpty {
            Section(header: Text(L10n.Plugin.section.pluginSettings)) {
                ForEach(registry.settingTabs) { tab in
                    NavigationLink(destination: PluginCustomSettingsView(tab: tab)) {
                        HStack {
                            Image(systemName: DesignSystem.Icons.puzzlepieceExtension)
                                .foregroundStyle(.appAccent)
                                .frame(width: DesignSystem.IconSize.standard)
                            Text(tab.name)
                                .foregroundStyle(.appText)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

/// 插件扩展详情视图：有已安装插件时展示设置列表，无插件时展示空状态引导
struct PluginExtensionsDetailView: View {
    @ObservedObject var registry = PluginRegistry.shared
    @State private var showPluginCenter = false

    var body: some View {
        Group {
            if registry.settingTabs.isEmpty {
                // 无已安装插件：空状态引导页
                VStack(spacing: DesignSystem.large) {
                    Image(systemName: "puzzlepiece.extension.fill")
                        .font(.system(size: 48)) // Dynamic Type
                        .foregroundStyle(.appSecondary)

                    Text(L10n.Plugin.settings.noSettings)
                        .font(.headline)
                        .foregroundStyle(.appText)

                    Button(action: { showPluginCenter = true }) {
                        Label(L10n.Plugin.title, systemImage: "plus.circle.fill")
                            .font(.body.weight(.medium))
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .sheet(isPresented: $showPluginCenter) {
                    NavigationStack {
                        PluginCenterView()
                    }
                }
            } else {
                // 有已安装插件：展示设置列表
                List {
                    PluginExtensionsSection()
                        .appListRowBackground()
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
    }
}
