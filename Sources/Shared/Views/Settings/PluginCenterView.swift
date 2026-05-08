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
    @StateObject private var registry = PluginRegistry.shared
    @StateObject private var marketService = PluginMarketService()
    
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var isSafeModeOn = true
    @State private var showFileImporter = false
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. 高级搜索与筛选头部
                headerSection
                
                // 2. 分段切换 (带动效)
                Picker("", selection: $selectedTab) {
                    Text(Localized.tr("plugin.market")).tag(0)
                    Text(Localized.tr("plugin.myPlugins")).tag(1)
                }
                .pickerStyle(.segmented)
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
        }
        .navigationTitle(Localized.tr("plugin.center"))
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.item]) { result in
            // 处理文件选择结果
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: AppUI.standardPadding) {
            // 搜索框：玻璃拟态
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.appAccent)
                TextField(Localized.tr("plugin.searchPlaceholder"), text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(AppUI.medium)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: AppUI.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: AppUI.cardRadius).stroke(Color.appBorder.opacity(AppUI.glassOpacity * 3), lineWidth: AppUI.borderWidth / 2))
            
            // 安全模式与加载按钮：对齐全局 Action 规范
            HStack(spacing: AppUI.standardPadding) {
                // 安全模式 Chip
                HStack(spacing: AppUI.tiny) {
                    Text(Localized.tr("plugin.safeMode"))
                        .font(.system(size: AppUI.captionFontSize, weight: .semibold))
                        .foregroundStyle(.appSecondary)
                    Toggle("", isOn: $isSafeModeOn)
                        .labelsHidden()
                        .controlSize(.mini)
                        .tint(.appAccent)
                }
                .padding(.horizontal, AppUI.medium)
                .padding(.vertical, AppUI.tiny)
                .background(Color.appSecondary.opacity(0.1))
                .clipShape(Capsule())
                
                // 加载本地插件 Action
                Button(action: { 
                    HapticFeedback.shared.trigger(.selection)
                    showFileImporter = true 
                }) {
                    HStack(spacing: AppUI.tiny) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: AppUI.Action.iconSize))
                        Text(Localized.tr("plugin.local.mount"))
                            .font(.system(size: AppUI.subheadlineFontSize, weight: .bold))
                    }
                    .padding(.horizontal, AppUI.standardPadding)
                    .frame(height: AppUI.Action.compactButtonHeight)
                    .background(Color.appAccent)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: Color.appAccent.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.top, AppUI.tiny)
        }
        .padding()
        .background(Color.appBackground)
    }
    
    private var myPluginsSection: some View {
        VStack(alignment: .leading, spacing: AppUI.widePadding) {
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
        VStack(alignment: .leading, spacing: AppUI.standardPadding) {
            if marketService.isLoading {
                ProgressView().padding(.top, AppUI.Gallery.splashIconSize - AppUI.tightPadding).frame(maxWidth: .infinity)
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
        VStack(spacing: AppUI.medium) {
            Image(systemName: icon)
                .font(.system(size: AppUI.Gallery.iconSize))
                .foregroundStyle(.appSecondary.opacity(AppUI.glassOpacity * 2))
            Text(title).font(.headline).foregroundStyle(.appSecondary)
            Text(sub).font(.caption2).foregroundStyle(.appSecondary.opacity(AppUI.glassOpacity * 4))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppUI.Gallery.splashIconSize - AppUI.tightPadding)
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
        HStack(spacing: AppUI.standardPadding) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: AppUI.Action.minTouchTarget, height: AppUI.Action.minTouchTarget)
                .background(LinearGradient(colors: [Color.appAccent, Color.appAccent.opacity(AppUI.fullOpacity - AppUI.glassOpacity * 2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(RoundedRectangle(cornerRadius: AppUI.cardRadius))
            
            VStack(alignment: .leading, spacing: AppUI.tiny) {
                Text(name).font(.subheadline.bold()).foregroundStyle(.appText)
                HStack(spacing: AppUI.tightPadding) {
                    Text("v\(version)").font(.caption2).foregroundStyle(.appSecondary)
                    if let author = author {
                        Text("•").font(.caption2).foregroundStyle(.appSecondary)
                        Text(author).font(.caption2).foregroundStyle(.appSecondary)
                    }
                }
                
                if let downloads = downloads, let rating = rating {
                    HStack(spacing: AppUI.tightPadding) {
                        Label(downloads, systemImage: "arrow.down.circle").font(.system(size: AppUI.microFontSize))
                        Label(String(format: "%.1f", rating), systemImage: "star.fill").font(.system(size: AppUI.microFontSize)).foregroundStyle(.yellow)
                    }
                    .foregroundStyle(.appSecondary)
                    .padding(.top, AppUI.atomic)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.appSecondary)
        }
        .padding()
        .background(Color.appCard.opacity(AppUI.glassOpacity * 4))
        .clipShape(RoundedRectangle(cornerRadius: AppUI.Task.dashboardRadius))
        .overlay(RoundedRectangle(cornerRadius: AppUI.Task.dashboardRadius).stroke(Color.white.opacity(AppUI.glassOpacity / 3), lineWidth: AppUI.borderWidth))
    }
}
