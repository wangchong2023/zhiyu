//
//  PluginCenterView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：构建 PluginCenter 界面的 UI 视图层组件。
//
import SwiftUI

/// 插件中心 (Stub: 为未来生态预留位置)
struct PluginCenterView: View {
    @Environment(Router.self) var router
    @StateObject private var registry = PluginRegistry.shared
    @StateObject private var marketService = PluginMarketService()
    
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var isSafeModeOn = true
    @State private var showSafeModeWarning = false
    @State private var showFileImporter = false

    var body: some View {
            
            VStack(spacing: 0) {
                // 1. 高级搜索与筛选头部
                headerSection
                
                // 2. 分段切换 (带动效)
                Picker("", selection: $selectedTab) {
                    Text(L10n.Plugin.marketTitle).tag(0)
                    Text(L10n.Plugin.myPlugins).tag(1)
                }
                #if !os(watchOS)
                .pickerStyle(.segmented)
                #endif
                .padding()
                
                // 3. 内容主体
                ScrollView {
                    if selectedTab == 0 {
                        marketSection
                    } else {
                        myPluginsSection
                    }
                }
            }
                .background(PageBackgroundView(accentColor: .appAccent))
                .id(router.languageForceUpdate)
                .navigationTitle(L10n.Plugin.centerTitle)
                .appNavigationBarTitleDisplayMode(.inline)
                .task {
                    await marketService.fetchPlugins()
                }
#if !os(watchOS)
                .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.item]) { result in
                    // 处理文件选择结果
                }
#endif
                .confirmationDialog(
            L10n.Plugin.safeModeWarningTitle,
            isPresented: $showSafeModeWarning,
            titleVisibility: .visible
        ) {
            Button(L10n.Plugin.safeModeTurnOff, role: .destructive) {
                isSafeModeOn = false
                HapticFeedback.shared.trigger(.warning)
            }
            Button(L10n.Common.cancel, role: .cancel) {
                isSafeModeOn = true
            }
        } message: {
            Text(L10n.Plugin.safeModeWarningMessage)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: DesignSystem.standardPadding) {
            // 搜索框：玻璃拟态
            HStack {
                Image(systemName: DesignSystem.Icons.search)
                    .foregroundStyle(.appAccent)
                TextField(L10n.Plugin.searchPlaceholder, text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(DesignSystem.medium)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.cardRadius).stroke(Color.appBorder.opacity(DesignSystem.glassOpacity * 3), lineWidth: DesignSystem.borderWidth / 2))
            
            // 安全模式与加载按钮：对齐全局 Action 规范（移除冗余背景，采用轻量化风格）
            HStack(spacing: DesignSystem.wide) {
                // 安全模式切换
                HStack(spacing: DesignSystem.small) {
                    Label(L10n.Plugin.safeModeTitle, systemImage: isSafeModeOn ? DesignSystem.Icons.shieldFill : DesignSystem.Icons.shieldSlash)
                        .font(.subheadline.bold())
                        .foregroundStyle(isSafeModeOn ? .green : .orange)
                    
                    Toggle("", isOn: Binding(
                        get: { isSafeModeOn },
                        set: { newValue in
                            if !newValue {
                                showSafeModeWarning = true
                            } else {
                                isSafeModeOn = true
                            }
                        }
                    ))
                    .labelsHidden()
                    .controlSize(.mini)
                    .tint(.appAccent)
                }
                
                Spacer()
                
                // 加载本地插件 Action
                Button(action: {
                    HapticFeedback.shared.trigger(.selection)
                    showFileImporter = true
                }) {
                    Label(L10n.Plugin.local.mount, systemImage: DesignSystem.Icons.plusCircle)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appAccent)
                }

            }
            .padding(.top, DesignSystem.tiny)
        }
        .padding()
        .background(Color.clear)
    }
    
    private var myPluginsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.widePadding) {
            let filtered = registry.plugins.filter { searchText.isEmpty || $0.manifest.name.localizedCaseInsensitiveContains(searchText) }
            
            if !filtered.isEmpty {
                Text(L10n.Plugin.Status.enabled)
                    .font(.caption.bold())
                    .foregroundStyle(.appSecondary)
                    .padding(.horizontal)
                
                ForEach(filtered, id: \.manifest.id) { plugin in
                    NavigationLink {
                        LocalPluginDetailView(manifest: plugin.manifest)
                    } label: {
                        PluginCard(name: plugin.manifest.name, version: plugin.manifest.version, isLocal: true)
                    }
                }
                .padding(.horizontal)
            } else if searchText.isEmpty {
                // 如果没有插件且不在搜索状态，显示空状态
                emptyStateView(icon: DesignSystem.Icons.pluginOutline, title: L10n.Plugin.noPlugins, sub: L10n.Plugin.noPluginsHint)
            } else {
                // 搜索结果为空
                emptyStateView(icon: DesignSystem.Icons.search, title: L10n.Plugin.noResults, sub: L10n.Plugin.noResultsHint)
            }
        }
    }
    
    private var marketSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.standardPadding) {
            if marketService.isLoading {
                ProgressView().padding(.top, DesignSystem.Gallery.splashIconSize - DesignSystem.tightPadding).frame(maxWidth: .infinity)
            } else {
                let filtered = marketService.availablePlugins.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
                
                if filtered.isEmpty {
                    emptyStateView(icon: DesignSystem.Icons.storefront, title: L10n.Plugin.market.empty, sub: L10n.Plugin.market.emptyHint)
                } else {
                    ForEach(filtered) { p in
                        NavigationLink(destination: PluginDetailView(plugin: p, marketService: marketService)) {
                            PluginCard(name: p.name, version: p.version, author: p.author, downloads: p.downloads, rating: p.rating, icon: p.icon)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func emptyStateView(icon: String, title: String, sub: String) -> some View {
        VStack(spacing: DesignSystem.medium) {
            Image(systemName: icon)
                .font(.system(size: DesignSystem.Gallery.iconSize))
                .foregroundStyle(.appSecondary.opacity(DesignSystem.glassOpacity * 2))
            Text(title).font(.headline).foregroundStyle(.appSecondary)
            Text(sub).font(.caption2).foregroundStyle(.appSecondary.opacity(DesignSystem.glassOpacity * 4))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DesignSystem.Gallery.splashIconSize - DesignSystem.tightPadding)
    }
}

struct PluginCard: View {
    let name: String
    let version: String
    var author: String? = nil
    var downloads: String? = nil
    var rating: Double? = nil
    var icon: String = "puzzlepiece.fill"
    var isLocal: Bool = false
    
    var body: some View {
        HStack(spacing: DesignSystem.standardPadding) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: DesignSystem.Action.minTouchTarget, height: DesignSystem.Action.minTouchTarget)
                .background(LinearGradient(colors: [Color.appAccent, Color.appAccent.opacity(DesignSystem.fullOpacity - DesignSystem.glassOpacity * 2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
            
            VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                Text(name).font(.subheadline.bold()).foregroundStyle(.appText)
                HStack(spacing: DesignSystem.tightPadding) {
                    Text("v\(version)").font(.caption2).foregroundStyle(.appSecondary)
                    if let author = author {
                        Text(DesignSystem.Icons.bullet).font(.caption2).foregroundStyle(.appSecondary)
                        Text(author).font(.caption2).foregroundStyle(.appSecondary)
                    }
                }
                
                if let downloads = downloads, let rating = rating {
                    HStack(spacing: DesignSystem.tightPadding) {
                        Label(downloads, systemImage: DesignSystem.Icons.arrowDownCircle).font(.system(size: DesignSystem.microFontSize))
                        Label(String(format: "%.1f", rating), systemImage: DesignSystem.Icons.star).font(.system(size: DesignSystem.microFontSize)).foregroundStyle(.yellow)
                    }
                    .foregroundStyle(.appSecondary)
                    .padding(.top, DesignSystem.atomic)
                }
            }
            Spacer()
            Image(systemName: DesignSystem.Icons.forward).font(.caption2).foregroundStyle(.appSecondary)
        }
        .padding()
        .background(Color.appCard.opacity(DesignSystem.glassOpacity * 4))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Task.dashboardRadius))
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.Task.dashboardRadius).stroke(Color.white.opacity(DesignSystem.glassOpacity / 3), lineWidth: DesignSystem.borderWidth))
    }
}
