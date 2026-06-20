//
//  PluginDetailView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：参照业界最佳实践（VS Code 扩展商店、Obsidian 社区插件）构建插件详情展示页面，
//  包含完整的元数据、版本、权限说明和操作入口。

import SwiftUI

/// 插件详情页（参照 VS Code 扩展商店 / Obsidian 社区插件标准）
struct PluginDetailView: View {
    let plugin: MarketPlugin
    @ObservedObject var marketService: PluginMarketService

    @Environment(\.dismiss) var dismiss
    @State private var isInstalling = false
    @State private var localIcon: UIImage?
    @State private var localReadme: String?
    @State private var remoteReadme: String?
    @State private var isReadmeLoading = false
    @State private var isDescriptionExpanded = false

    /// 计算插件的当前展示版本 (如果已安装则展示本地已安装的真实版本号，否则展示市场版本)
    private var displayVersion: String {
        if let localPlugin = PluginRegistry.shared.plugins.first(where: { $0.manifest.id == plugin.id }) {
            return localPlugin.manifest.version
        }
        return plugin.version
    }

    private var isInstalled: Bool {
        PluginRegistry.shared.plugins.contains(where: { $0.manifest.id == plugin.id })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.giant) {

                // MARK: - 1. 头部信息区 (Squircle 图标与简要)
                headerSection

                // MARK: - 2. 操作按钮 (获取/卸载与分享)
                actionButtons

                if let error = marketService.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.top, -DesignSystem.small)
                }

                Divider()

                // MARK: - App Store 风格快捷指标横向栏
                appStoreMetricsBar

                Divider()

                // MARK: - 4. 功能描述 (README 折叠渐变展开)
                descriptionSection

                Divider()

                // MARK: - 5. 权限声明
                permissionsSection

                Divider()

                // MARK: - 3. 详细信息面板 (底栏信息)
                metadataSection
            }
            .padding()
        }
        .background(PageBackgroundView(accentColor: .appAccent))
        .task {
            // 异步加载本地图标和 README，避免主线程 I/O 阻塞
            if let url = PluginRegistry.shared.iconURL(for: plugin.id) {
                localIcon = UIImage(data: (try? Data(contentsOf: url)) ?? Data())
            }
            localReadme = PluginRegistry.shared.localizedReadme(for: plugin.id)
            
            // 异步拉取云端多语言 README
            await fetchRemoteReadme()
        }
        .appNavigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 头部信息区

    private var headerSection: some View {
        HStack(alignment: .top, spacing: DesignSystem.wide) {
            // 插件大图标 — 优先显示已缓存的本地 icon.png，使用 App Store 经典的 Squircle 平滑圆角
            if let uiImage = localIcon {
                Image(uiImage: uiImage)
                    .resizable().scaledToFit()
                    .frame(width: DesignSystem.Gallery.itemSize, height: DesignSystem.Gallery.itemSize)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.chipRadius + Spacing.atomic, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: DesignSystem.chipRadius + Spacing.atomic, style: .continuous).stroke(Color.appBorder.opacity(DesignSystem.subtleOpacity * 1.66), lineWidth: 0.5))
                    .shadow(color: Color.theme.black.opacity(DesignSystem.subtleOpacity), radius: 12, x: 0, y: 6)
            } else {
                Image(systemName: plugin.icon)
                    .font(.system(size: DesignSystem.Gallery.mainIconSize * 0.9))
                    .foregroundStyle(.white)
                    .frame(width: DesignSystem.Gallery.itemSize, height: DesignSystem.Gallery.itemSize)
                    .background(
                        LinearGradient(colors: [Color.appAccent, Color.appAccent.opacity(DesignSystem.subtleOpacity * 6.25)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.chipRadius + Spacing.atomic, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: DesignSystem.chipRadius + Spacing.atomic, style: .continuous).stroke(Color.theme.white.opacity(DesignSystem.subtleOpacity * 1.25), lineWidth: 0.5))
                    .shadow(color: Color.appAccent.opacity(DesignSystem.subtleOpacity * 1.66), radius: 12, x: 0, y: 6)
            }

            VStack(alignment: .leading, spacing: DesignSystem.small) {
                // 名称 + 版本标签
                HStack(spacing: DesignSystem.small) {
                    Text(plugin.name)
                        .font(.title2.bold())
                        .foregroundStyle(.appText)

                    // 版本号标签
                    Text("v\(displayVersion)")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, DesignSystem.small)
                        .padding(.vertical, DesignSystem.atomic * 2)
                        .background(Color.appAccent.opacity(DesignSystem.Opacity.subtle))
                        .foregroundStyle(.appAccent)
                        .clipShape(Capsule())
                }

                // 作者
                Text(L10n.Plugin.Detail.byAuthor(plugin.author))
                    .font(.subheadline)
                    .foregroundStyle(.appSecondary)

                // 安装状态标签 (移至大字号区域下端，保持视觉重点清晰)
                if isInstalled {
                    HStack(spacing: DesignSystem.tiny) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text(L10n.Plugin.Detail.installed)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.green)
                    }
                    .padding(.top, DesignSystem.atomic)
                }
            }
        }
    }

    // MARK: - 操作按钮

    private var actionButtons: some View {
        HStack(spacing: DesignSystem.small) {
            // 安装 / 卸载
            Button(action: {
                if isInstalled {
                    PluginRegistry.shared.unloadPlugin(id: plugin.id)
                    HapticFeedback.shared.trigger(.success)
                } else {
                    HapticFeedback.shared.trigger(.selection)
                    isInstalling = true
                    Task {
                        _ = await marketService.downloadPlugin(plugin)
                        isInstalling = false
                    }
                }
            }) {
                HStack(spacing: DesignSystem.tiny) {
                    if isInstalling || marketService.downloadingPluginID == plugin.id {
                        ProgressView().scaleEffect(DesignSystem.iconSmall / DesignSystem.largeIconSize)
                    } else {
                        Image(systemName: isInstalled ? "trash" : "icloud.and.arrow.down")
                    }
                    Text(isInstalled ? L10n.Plugin.Action.uninstall : L10n.Plugin.Action.install)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, DesignSystem.standardPadding)
                .padding(.vertical, DesignSystem.small)
            }
            .buttonStyle(.borderedProminent)
            .tint(isInstalled ? .red : .appAccent)
            .disabled(isInstalling || marketService.downloadingPluginID == plugin.id)

            // 分享
            ShareLink(item: "\(plugin.name) — v\(plugin.version)\n\(plugin.description)") {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - App Store 风格快捷指标滚轴

    private var appStoreMetricsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                // 卡片 1: 评分与星级
                let reviewLabel = plugin.reviewCount.map { L10n.Plugin.Detail.reviewCount($0) } ?? L10n.Plugin.Stats.rating
                metricCard(
                    title: String(format: "%.1f ★", plugin.rating),
                    subtitle: reviewLabel
                )
                
                metricDivider
                
                // 卡片 2: 安全检测认证 (沙盒审计通过)
                metricCard(
                    title: L10n.Plugin.Detail.securePassed,
                    subtitle: L10n.Plugin.Detail.secureLabel,
                    icon: "lock.shield.fill",
                    iconColor: .green
                )
                
                metricDivider
                
                // 卡片 3: 开发者
                metricCard(
                    title: plugin.author,
                    subtitle: L10n.Plugin.Detail.author
                )
                
                metricDivider
                
                // 卡片 4: 最低系统要求
                let compatVal = plugin.minAppVersion.map { "iOS \($0)+" } ?? L10n.Plugin.Detail.allPlatforms
                metricCard(
                    title: compatVal,
                    subtitle: L10n.Plugin.Detail.compatibilityTitle
                )
            }
            .padding(.horizontal, DesignSystem.small)
        }
        .frame(height: DesignSystem.iconDisplay + Spacing.giant)
    }

    /// 单个快捷指标项卡片渲染
    private func metricCard(title: String, subtitle: String, icon: String? = nil, iconColor: Color = .secondary) -> some View {
        VStack(spacing: DesignSystem.tiny) {
            Text(subtitle)
                .font(.system(size: 10, weight: .bold)) // Dynamic Type
                .foregroundStyle(.appSecondary)
                .lineLimit(1)
                
            Spacer(minLength: 0)

            if let icon = icon {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                        .font(.caption.bold())
                    Text(title)
                        .font(.headline.bold())
                        .foregroundStyle(.appText)
                }
            } else {
                Text(title)
                    .font(.headline.bold())
                    .foregroundStyle(.appText)
                    .lineLimit(1)
            }
        }
        .frame(width: Spacing.Action.buttonHeight * 2.0 + Spacing.atomic, height: Spacing.Action.buttonHeight)
    }

    private var metricDivider: some View {
        Divider()
            .frame(height: Spacing.huge)
            .padding(.horizontal, DesignSystem.medium)
    }

    // MARK: - 元数据面板（参照 VS Code 扩展详情页）

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            Text(L10n.Plugin.Detail.metadataTitle)
                .font(.headline)
                .foregroundStyle(.appText)

            VStack(spacing: 0) {
                // 版本
                metadataRow(
                    icon: "number",
                    label: L10n.Plugin.Detail.version,
                    value: displayVersion
                )

                Divider().padding(.leading, 40)

                // 作者
                metadataRow(
                    icon: "person.fill",
                    label: L10n.Plugin.Detail.author,
                    value: plugin.author
                )

                Divider().padding(.leading, 40)

                // 最低应用版本
                if let minVersion = plugin.minAppVersion {
                    metadataRow(
                        icon: "app.badge.checkmark",
                        label: L10n.Plugin.Detail.minAppVersion,
                        value: minVersion
                    )
                    Divider().padding(.leading, 40)
                }

                // 分类
                metadataRow(
                    icon: "folder.fill",
                    label: L10n.Plugin.Detail.category,
                    value: categoryName
                )

                Divider().padding(.leading, 40)

                // 许可
                metadataRow(
                    icon: "checkmark.seal.fill",
                    label: L10n.Plugin.Detail.license,
                    value: monetizationLabel
                )
            }
            .background(Color.appCard.opacity(DesignSystem.Opacity.disabled))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
        }
    }

    /// 单行元数据
    private func metadataRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: DesignSystem.medium) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.appAccent)
                .frame(width: DesignSystem.IconSize.small, alignment: .center)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.appSecondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.appText)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, DesignSystem.medium)
        .padding(.vertical, DesignSystem.small + 2)
    }

    // MARK: - 功能描述

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            Text(L10n.Plugin.section.about)
                .font(.headline)
                .foregroundStyle(.appText)

            // 如果本地没有 README 缓存，且远端 README 正在加载，则呈现骨架屏
            if localReadme == nil && isReadmeLoading {
                VStack(alignment: .leading, spacing: DesignSystem.small) {
                    RoundedRectangle(cornerRadius: DesignSystem.microRadius)
                        .fill(Color.appCard.opacity(DesignSystem.subtleOpacity * 2.5))
                        .frame(height: Spacing.large)
                    RoundedRectangle(cornerRadius: DesignSystem.microRadius)
                        .fill(Color.appCard.opacity(DesignSystem.subtleOpacity * 2.5))
                        .frame(height: Spacing.large)
                    RoundedRectangle(cornerRadius: DesignSystem.microRadius)
                        .fill(Color.appCard.opacity(DesignSystem.subtleOpacity * 2.5))
                        .frame(height: Spacing.large)
                        .frame(maxWidth: 200)
                }
                .opacity(isReadmeLoading ? 0.6 : 1.0)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isReadmeLoading)
                .padding(.vertical, DesignSystem.small)
            } else {
                // 降级选择链：优先显示本地缓存的 README -> 远端多语言 README -> 插件自身的简短描述
                let content = localReadme ?? remoteReadme ?? plugin.description
                let lineCount = content.components(separatedBy: .newlines).count
                let showExpandButton = lineCount > 5
                
                VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                    MarkdownRendererView(content: content, isPrivate: false, onLinkTap: { _ in }, isCompact: true)
                        .frame(maxHeight: (showExpandButton && !isDescriptionExpanded) ? 180 : nil, alignment: .top)
                        .clipped()
                        .overlay(
                            Group {
                                if showExpandButton && !isDescriptionExpanded {
                                    VStack {
                                        Spacer()
                                        // 渐变蒙层，在折叠状态下于底部实现优雅淡出效果
                                        LinearGradient(
                                            colors: [Color.appBackground.opacity(Double.zero), Color.appBackground.opacity(DesignSystem.Metrics.lockOverlayScaleMultiplier), Color.appBackground],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        .frame(height: DesignSystem.iconDisplay)
                                    }
                                }
                            }
                        )
                    
                    if showExpandButton {
                        // 轻量级展开/折叠更多按钮
                        Button(action: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                isDescriptionExpanded.toggle()
                            }
                        }) {
                            HStack(spacing: DesignSystem.tiny) {
                                Text(isDescriptionExpanded ? L10n.Plugin.Detail.showLess : L10n.Plugin.Detail.readMore)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.appAccent)
                                Image(systemName: isDescriptionExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.appAccent)
                            }
                            .padding(.vertical, DesignSystem.atomic)
                        }
                    }
                }
            }
        }
    }

    /// 异步拉取云端多语言 README.md，包含首选语言 -> 英文 -> 默认无后缀的自动降级策略
    /// - Returns: Void。更新 `@State` 的 `remoteReadme` 与 `isReadmeLoading`。
    private func fetchRemoteReadme() async {
        // 如果本地已存在 README 缓存，或者下载 URL 缺失，直接返回无需重复抓取
        guard localReadme == nil,
              let downloadURLString = plugin.downloadURL else { return }
        
        let urlsToTry = marketService.readmeCandidateURLs(forID: plugin.id, downloadURLString: downloadURLString)
        guard !urlsToTry.isEmpty else { return }
        
        await MainActor.run { isReadmeLoading = true }
        
        // 依次尝试降级拉取云端文档数据
        for readmeURL in urlsToTry {
            do {
                Logger.shared.info("PluginDetail.fetchRemoteReadme.try: \(readmeURL.absoluteString)")
                let (data, response) = try await URLSession.shared.data(from: readmeURL)
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                
                if statusCode == 200, !data.isEmpty, let text = String(data: data, encoding: .utf8) {
                    Logger.shared.info("PluginDetail.fetchRemoteReadme.success: \(readmeURL.lastPathComponent)")
                    await MainActor.run {
                        self.remoteReadme = text
                        self.isReadmeLoading = false
                    }
                    return
                }
            } catch {
                Logger.shared.warning("PluginDetail.fetchRemoteReadme.error: \(readmeURL.lastPathComponent), error: \(error.localizedDescription)")
            }
        }
        
        await MainActor.run { isReadmeLoading = false }
    }

    // MARK: - 权限声明

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            HStack(spacing: DesignSystem.small) {
                Text(L10n.Plugin.section.permissions)
                    .font(.headline)
                    .foregroundStyle(.appText)

                if let perms = plugin.requiredPermissions, !perms.isEmpty {
                    Text("\(perms.count)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.appAccent)
                        .padding(.horizontal, DesignSystem.small)
                        .padding(.vertical, DesignSystem.atomic)
                        .background(Color.appAccent.opacity(DesignSystem.Opacity.subtle))
                        .clipShape(Capsule())
                }
            }

            if let perms = plugin.requiredPermissions, !perms.isEmpty {
                VStack(spacing: DesignSystem.small) {
                    ForEach(perms, id: \.self) { perm in
                        HStack(spacing: DesignSystem.medium) {
                            Image(systemName: permIcon(for: perm))
                                .foregroundStyle(permColor(for: perm))
                                .font(.subheadline)
                                .frame(width: DesignSystem.IconSize.small)

                            VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                                Text(L10n.Plugin.permTitle(for: perm))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.appText)
                                Text(L10n.Plugin.permDesc(for: perm))
                                    .font(.caption)
                                    .foregroundStyle(.appSecondary)
                            }
                        }
                        .padding(DesignSystem.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.appCard.opacity(DesignSystem.Opacity.disabled))
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
                    }
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                    Text(L10n.Plugin.perm.none)
                        .font(.subheadline)
                        .foregroundStyle(.appSecondary)
                }
                .padding(DesignSystem.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appCard.opacity(DesignSystem.Opacity.disabled))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
            }
        }
    }

    // MARK: - 辅助方法

    /// 分类名称（从插件元数据获取）
    private var categoryName: String {
        return plugin.category ?? L10n.Plugin.Detail.categoryCommunity
    }

    /// 商业化模式标签
    private var monetizationLabel: String {
        guard let model = plugin.monetization?.model else {
            return L10n.Plugin.Detail.licenseFree
        }
        switch model {
        case .free:
            return L10n.Plugin.Detail.licenseFree
        case .donation:
            return L10n.Plugin.Detail.licenseDonation
        case .subscription:
            return L10n.Plugin.Detail.licenseSubscription
        }
    }

    /// 权限图标
    private func permIcon(for perm: String) -> String {
        switch perm {
        case "readContent": return "doc.text.magnifyingglass"
        case "writeContent": return "square.and.pencil"
        case "network": return "globe"
        case "aiAccess": return "brain.head.profile"
        case "log": return "list.bullet.clipboard"
        default: return "key.fill"
        }
    }

    /// 权限颜色
    private func permColor(for perm: String) -> Color {
        switch perm {
        case "readContent": return .blue
        case "writeContent": return .orange
        case "network": return .purple
        case "aiAccess": return .pink
        case "log": return .gray
        default: return .appSecondary
        }
    }
}

// MARK: - 权限确认面板

struct PermissionConfirmationSheet: View {
    let plugin: MarketPlugin
    var onConfirm: () -> Void

    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: DesignSystem.giant) {
            VStack(spacing: DesignSystem.medium) {
                Image(systemName: "lock.shield.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.appAccent)

                Text(L10n.Plugin.permission.title)
                    .font(.title3.bold())

                Text(L10n.Plugin.permissionMessage(plugin.name))
                    .font(.subheadline)
                    .foregroundStyle(.appSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)

            // 权限列表（带图标和详细说明）
            VStack(alignment: .leading, spacing: DesignSystem.standardPadding) {
                Text(L10n.Plugin.section.permissions)
                    .font(.caption.bold())
                    .foregroundStyle(.appSecondary)

                if let perms = plugin.requiredPermissions {
                    ForEach(perms, id: \.self) { perm in
                        HStack(spacing: DesignSystem.medium) {
                            Image(systemName: permIcon(for: perm))
                                .foregroundStyle(.appAccent)
                                .frame(width: DesignSystem.IconSize.standard)

                            VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                                Text(L10n.Plugin.permTitle(for: perm))
                                    .font(.subheadline.bold())
                                Text(L10n.Plugin.permDesc(for: perm))
                                    .font(.caption)
                                    .foregroundStyle(.appSecondary)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.largeRadius))

            Spacer()

            VStack(spacing: DesignSystem.medium) {
                Button(action: onConfirm) {
                    Text(L10n.Plugin.Action.confirmInstall)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appAccent)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
                }

                Button(L10n.Common.cancel) {
                    dismiss()
                }
                .foregroundStyle(.appSecondary)
            }
        }
        .padding(DesignSystem.giant)
        .background(PageBackgroundView(accentColor: .appAccent))
    }

    private func permIcon(for perm: String) -> String {
        switch perm {
        case "readContent": return "doc.text.magnifyingglass"
        case "writeContent": return "square.and.pencil"
        case "network": return "globe"
        case "aiAccess": return "brain.head.profile"
        case "log": return "list.bullet.clipboard"
        default: return "key.fill"
        }
    }
}

// MARK: - 权限标签

struct PermissionTag: View {
    let perm: String

    var body: some View {
        HStack(spacing: DesignSystem.tiny) {
            Image(systemName: icon)
            Text(L10n.Plugin.permTitle(for: perm))
        }
        .font(.caption2.bold())
        .padding(.horizontal, DesignSystem.small)
        .padding(.vertical, DesignSystem.tiny)
        .background(color.opacity(DesignSystem.Opacity.subtle))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }

    private var color: Color {
        switch perm {
        case "readContent": return .blue
        case "writeContent": return .orange
        case "network": return .purple
        case "aiAccess": return .pink
        case "log": return .gray
        default: return .appSecondary
        }
    }

    private var icon: String {
        switch perm {
        case "readContent": return "doc.text.magnifyingglass"
        case "writeContent": return "square.and.pencil"
        case "network": return "globe"
        case "aiAccess": return "brain.head.profile"
        case "log": return "list.bullet.clipboard"
        default: return "key.fill"
        }
    }
}

// MARK: - 要点列表

struct BulletPoint: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.small) {
            Text("·").bold()
            Text(text).font(.subheadline).foregroundStyle(.appSecondary)
        }
    }
}
