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
    @Environment(\.dismiss) private var dismiss
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
                .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.item]) { _ in
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
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.Common.done) {
                    dismiss()
                }
            }
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
            HStack(spacing: DesignSystem.large) {
                // 安全模式切换
                HStack(spacing: DesignSystem.small) {
                    Image(systemName: isSafeModeOn ? DesignSystem.Icons.shieldFill : DesignSystem.Icons.shieldSlash)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appAccent) // 与右侧加载本地插件按钮相同风格的图标颜色
                    
                    Text(L10n.Plugin.safeModeTitle)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appText)
                    
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
                
                // 移除原有的占据全屏的 Spacer()
                
                // 加载本地插件 Action
                Button(action: {
                    HapticFeedback.shared.trigger(.selection)
                    showFileImporter = true
                }) {
                    Label(L10n.Plugin.local.mount, systemImage: DesignSystem.Icons.plusCircle)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appAccent)
                }
                
                Spacer() // 靠左对齐
            }
            .padding(.top, DesignSystem.tiny)
        }
        .padding()
        .background(Color.clear)
    }
    
    /// 本地已启用/已安装的插件列表区域
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
                        PluginCard(name: plugin.manifest.name, version: plugin.manifest.version, pluginID: plugin.manifest.id, source: "local", isLocal: true)
                    }
                }
                .padding(.horizontal)
            } else if searchText.isEmpty {
                // 当本地插件列表为空时，展示规范的简单空状态
                AppEmptyState.simple(
                    icon: DesignSystem.Icons.pluginOutline,
                    title: L10n.Plugin.noPlugins,
                    description: L10n.Plugin.noPluginsHint
                )
                .padding(.vertical, DesignSystem.giant)
            } else {
                // 搜索后无匹配结果，展示无结果空状态
                AppEmptyState.simple(
                    icon: DesignSystem.Icons.search,
                    title: L10n.Plugin.noResults,
                    description: L10n.Plugin.noResultsHint
                )
                .padding(.vertical, DesignSystem.giant)
            }
        }
    }
    
    /// 远端/社区插件市场的插件列表区域
    private var marketSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.standardPadding) {
            if marketService.isLoading {
                ProgressView()
                    .padding(.top, DesignSystem.Gallery.splashIconSize - DesignSystem.tightPadding)
                    .frame(maxWidth: .infinity)
            } else {
                // 优先校验并展示网络连接或元数据解析异常带来的空错误状态
                if let errorMessage = marketService.errorMessage {
                    AppEmptyState.withAction(
                        icon: "wifi.slash",
                        title: L10n.Plugin.market.connectionError,
                        description: errorMessage,
                        actionLabel: L10n.Shared.retryButton,
                        actionIcon: "arrow.clockwise"
                    ) {
                        Task {
                            await marketService.fetchPlugins()
                        }
                    }
                    .padding(.vertical, DesignSystem.giant)
                } else {
                    let filtered = marketService.availablePlugins.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
                    
                    if filtered.isEmpty {
                        // 远端市场插件拉取成功但为空，展示规范的简单空状态
                        AppEmptyState.simple(
                            icon: DesignSystem.Icons.storefront,
                            title: L10n.Plugin.market.empty,
                            description: L10n.Plugin.market.emptyHint
                        )
                        .padding(.vertical, DesignSystem.giant)
                    } else {
                        ForEach(filtered) { p in
                            NavigationLink(destination: PluginDetailView(plugin: p, marketService: marketService)) {
                                PluginCard(name: p.name, version: p.version, author: p.author, downloads: p.downloads, rating: p.rating, icon: p.icon, source: "community")
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

struct PluginCard: View {
    let name: String
    let version: String
    var author: String?
    var downloads: String?
    var rating: Double?
    var icon: String = "puzzlepiece.fill"
    var pluginID: String?
    var source: String?    // "local" / "remote" / "community"
    var isLocal: Bool = false

    @State private var localIcon: UIImage?

    /// 自适应计算插件的展示版本号，已安装则优先显示真实本地版本号
    private var displayVersion: String {
        if let localPlugin = PluginRegistry.shared.plugins.first(where: { $0.manifest.id == (pluginID ?? "") }) {
            return localPlugin.manifest.version
        }
        return version
    }

    var body: some View {
        HStack(spacing: DesignSystem.standardPadding) {
            // 优先显示本地 icon.png，fallback SF Symbol，并剪裁为连续平滑 Squircle 圆角
            if let uiImage = localIcon {
                Image(uiImage: uiImage)
                    .resizable().scaledToFit()
                    .frame(width: DesignSystem.Action.minTouchTarget, height: DesignSystem.Action.minTouchTarget)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: DesignSystem.cardRadius, style: .continuous).stroke(Color.appBorder.opacity(DesignSystem.subtleOpacity * 1.66), lineWidth: 0.5))
            } else {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: DesignSystem.Action.minTouchTarget, height: DesignSystem.Action.minTouchTarget)
                    .background(LinearGradient(colors: [Color.appAccent, Color.appAccent.opacity(DesignSystem.pressedOpacity * 4.0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: DesignSystem.cardRadius, style: .continuous).stroke(Color.white.opacity(DesignSystem.subtleOpacity * 1.25), lineWidth: 0.5))
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                Text(name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.appText)
                
                HStack(spacing: DesignSystem.tightPadding) {
                    Text("v\(displayVersion)")
                        .font(.caption2)
                        .foregroundStyle(.appSecondary)
                    
                    // 来源类型精致微缩标签
                    if let src = source {
                        Text(sourceLabel(src))
                            .font(.system(size: DesignSystem.microFontSize, weight: .semibold))
                            .padding(.horizontal, DesignSystem.tiny)
                            .padding(.vertical, 2)
                            .background(sourceColor(src).opacity(DesignSystem.subtleOpacity))
                            .clipShape(Capsule())
                            .foregroundStyle(sourceColor(src))
                    }
                    
                    if let author = author {
                        Text(DesignSystem.Icons.bullet)
                            .font(.caption2)
                            .foregroundStyle(.appSecondary)
                        Text(author)
                            .font(.caption2)
                            .foregroundStyle(.appSecondary)
                    }
                }
                
                if let downloads = downloads, let rating = rating {
                    HStack(spacing: DesignSystem.tightPadding) {
                        Label(downloads, systemImage: DesignSystem.Icons.arrowDownCircle)
                            .font(.system(size: DesignSystem.microFontSize))
                        Label(String(format: "%.1f", rating), systemImage: DesignSystem.Icons.star)
                            .font(.system(size: DesignSystem.microFontSize))
                            .foregroundStyle(.yellow)
                    }
                    .foregroundStyle(.appSecondary)
                    .padding(.top, 2)
                }
            }
            Spacer()
            Image(systemName: DesignSystem.Icons.forward)
                .font(.caption2)
                .foregroundStyle(.appSecondary)
        }
        .padding()
        // 升级为 ultraThinMaterial 亚玻璃磨砂镜面质感，提供高透明度高对比度
        .background(RoundedRectangle(cornerRadius: DesignSystem.Task.dashboardRadius, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.Task.dashboardRadius, style: .continuous).stroke(Color.white.opacity(DesignSystem.subtleOpacity * 1.25), lineWidth: 0.5))
        .shadow(color: Color.black.opacity(DesignSystem.subtleOpacity * 0.66), radius: 8, x: 0, y: 4)
        .task {
            if let id = pluginID, let url = PluginRegistry.shared.iconURL(for: id) {
                localIcon = UIImage(data: (try? Data(contentsOf: url)) ?? Data())
            }
        }
    }

    private func sourceLabel(_ src: String) -> String {
        switch src {
        case "local": return L10n.Plugin.Detail.categoryLocal
        case "remote": return L10n.Plugin.Detail.categoryRemote
        case "community": return L10n.Plugin.Detail.categoryCommunity
        default: return src
        }
    }

    private func sourceColor(_ src: String) -> Color {
        switch src {
        case "local": return .green
        case "remote": return .blue
        case "community": return .orange
        default: return .appSecondary
        }
    }
}
