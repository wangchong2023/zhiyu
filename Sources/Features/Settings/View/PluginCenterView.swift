// PluginCenterView.swift
//
// 作者: Wang Chong
// 功能说明: 插件中心 (Stub: 为未来生态预留位置)
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
//   - 更新: 2026-05-03
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
                    Text(Localized.tr("plugin.market")).tag(0)
                    Text(Localized.tr("plugin.myPlugins")).tag(1)
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
                .navigationTitle(Localized.tr("plugin.center"))
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
#if !os(watchOS)
                .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.item]) { result in
                    // 处理文件选择结果
                }
#endif
                .confirmationDialog(
            Localized.tr("plugin.safeMode.warning.title"),
            isPresented: $showSafeModeWarning,
            titleVisibility: .visible
        ) {
            Button(Localized.tr("plugin.safeMode.turnOff"), role: .destructive) {
                isSafeModeOn = false
                HapticFeedback.shared.trigger(.warning)
            }
            Button(L10n.Common.tr("cancel"), role: .cancel) {
                isSafeModeOn = true
            }
        } message: {
            Text(Localized.tr("plugin.safeMode.warning.message"))
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: DesignSystem.standardPadding) {
            // 搜索框：玻璃拟态
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.appAccent)
                TextField(Localized.tr("plugin.searchPlaceholder"), text: $searchText)
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
                    Label(Localized.tr("plugin.safeMode"), systemImage: isSafeModeOn ? "shield.fill" : "shield.slash")
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
                    Label(Localized.tr("plugin.local.mount"), systemImage: "plus.circle")
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
                Text(Localized.tr("plugin.status.enabled"))
                    .font(.caption.bold())
                    .foregroundStyle(.appSecondary)
                    .padding(.horizontal)
                
                ForEach(filtered, id: \.manifest.id) { plugin in
                    PluginCard(name: plugin.manifest.name, version: plugin.manifest.version, isLocal: true)
                }
                .padding(.horizontal)
            } else if searchText.isEmpty {
                // 如果没有插件且不在搜索状态，显示空状态
                emptyStateView(icon: "puzzlepiece", title: Localized.tr("plugin.noPlugins"), sub: Localized.tr("plugin.noPluginsHint"))
            } else {
                // 搜索结果为空
                emptyStateView(icon: "magnifyingglass", title: Localized.tr("plugin.noResults"), sub: Localized.tr("plugin.noResultsHint"))
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
                    emptyStateView(icon: "storefront", title: Localized.tr("plugin.market.empty"), sub: Localized.tr("plugin.market.emptyHint"))
                } else {
                    ForEach(filtered) { p in
                        NavigationLink(destination: PluginDetailView(name: p.name, author: p.author, version: p.version, description: p.description, icon: p.icon)) {
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
                        Label(downloads, systemImage: "arrow.down.circle").font(.system(size: DesignSystem.microFontSize))
                        Label(String(format: "%.1f", rating), systemImage: "star.fill").font(.system(size: DesignSystem.microFontSize)).foregroundStyle(.yellow)
                    }
                    .foregroundStyle(.appSecondary)
                    .padding(.top, DesignSystem.atomic)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.appSecondary)
        }
        .padding()
        .background(Color.appCard.opacity(DesignSystem.glassOpacity * 4))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Task.dashboardRadius))
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.Task.dashboardRadius).stroke(Color.white.opacity(DesignSystem.glassOpacity / 3), lineWidth: DesignSystem.borderWidth))
    }
}
