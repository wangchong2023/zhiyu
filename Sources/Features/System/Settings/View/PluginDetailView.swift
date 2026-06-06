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
    @State private var showPermissionSheet = false
    @State private var isInstalling = false
    @State private var localIcon: UIImage?
    @State private var localReadme: String?

    private var isInstalled: Bool {
        PluginRegistry.shared.plugins.contains(where: { $0.manifest.id == plugin.id })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.giant) {

                // MARK: - 1. 头部信息区
                headerSection

                // MARK: - 2. 操作按钮
                actionButtons

                if let error = marketService.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.top, -DesignSystem.small)
                }

                Divider()

                // MARK: - 3. 元数据详情面板
                metadataSection

                Divider()

                // MARK: - 4. 功能描述
                descriptionSection

                Divider()

                // MARK: - 5. 权限声明
                permissionsSection

                // MARK: - 6. 底部信息
                bottomInfoSection
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
        }
        .sheet(isPresented: $showPermissionSheet) {
            PermissionConfirmationSheet(plugin: plugin) {
                Task {
                    showPermissionSheet = false
                    isInstalling = true
                    _ = await marketService.downloadPlugin(plugin)
                    isInstalling = false
                }
            }
        }
        .appNavigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 头部信息区

    private var headerSection: some View {
        HStack(alignment: .top, spacing: DesignSystem.wide) {
            // 插件图标 — 优先显示已缓存的本地 icon.png，fallback SF Symbol
            if let uiImage = localIcon {
                Image(uiImage: uiImage)
                    .resizable().scaledToFit()
                    .frame(width: DesignSystem.Gallery.itemSize, height: DesignSystem.Gallery.itemSize)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.largeRadius))
                    .shadow(color: Color.appAccent.opacity(0.3), radius: 10, x: 0, y: 5)
            } else {
                Image(systemName: plugin.icon)
                    .font(.system(size: DesignSystem.Gallery.mainIconSize * 0.9))
                    .foregroundStyle(.white)
                    .frame(width: DesignSystem.Gallery.itemSize, height: DesignSystem.Gallery.itemSize)
                    .background(
                        LinearGradient(colors: [Color.appAccent, Color.appAccent.opacity(0.8)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.giant))
                    .shadow(color: Color.appAccent.opacity(0.3), radius: 10, x: 0, y: 5)
            }

            VStack(alignment: .leading, spacing: DesignSystem.small) {
                // 名称 + 版本标签
                HStack(spacing: DesignSystem.small) {
                    Text(plugin.name)
                        .font(.title2.bold())
                        .foregroundStyle(.appText)

                    // 版本号标签
                    Text("v\(plugin.version)")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, DesignSystem.small)
                        .padding(.vertical, DesignSystem.atomic * 2)
                        .background(Color.appAccent.opacity(0.12))
                        .foregroundStyle(.appAccent)
                        .clipShape(Capsule())
                }

                // 作者
                Text(L10n.Plugin.Detail.byAuthor(plugin.author))
                    .font(.subheadline)
                    .foregroundStyle(.appSecondary)

                // 统计行：下载量 + 评分
                HStack(spacing: DesignSystem.medium) {
                    // 评分（带星号）
                    HStack(spacing: DesignSystem.tiny) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", plugin.rating))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.appText)
                        if let reviewCount = plugin.reviewCount {
                            Text(L10n.Plugin.Detail.reviewCount(reviewCount))
                                .font(.caption)
                                .foregroundStyle(.appSecondary)
                        }
                    }

                    // 下载量
                    HStack(spacing: DesignSystem.tiny) {
                        Image(systemName: "arrow.down.circle")
                            .foregroundStyle(.appSecondary)
                            .font(.caption)
                        Text(plugin.downloads)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.appText)
                        Text(L10n.Plugin.Detail.downloadsUnit)
                            .font(.caption)
                            .foregroundStyle(.appSecondary)
                    }
                }

                // 安装状态标签
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
        HStack(spacing: DesignSystem.medium) {
            // 安装 / 卸载
            Button(action: {
                if isInstalled {
                    PluginRegistry.shared.unloadPlugin(id: plugin.id)
                    HapticFeedback.shared.trigger(.success)
                } else {
                    showPermissionSheet = true
                }
            }) {
                HStack {
                    if isInstalling || marketService.downloadingPluginID == plugin.id {
                        ProgressView().tint(.white).padding(.trailing, DesignSystem.small)
                    }
                    Label(
                        isInstalled ? L10n.Plugin.Action.uninstall : L10n.Plugin.Action.install,
                        systemImage: isInstalled ? "trash" : "icloud.and.arrow.down"
                    )
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.small)
            }
            .buttonStyle(.borderedProminent)
            .tint(isInstalled ? .red : .appAccent)
            .disabled(isInstalling || marketService.downloadingPluginID == plugin.id)

            // 分享
            Button(action: {}) {
                Image(systemName: "square.and.arrow.up")
                    .padding(DesignSystem.small)
            }
            .buttonStyle(.bordered)
        }
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
                    value: plugin.version
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
            .background(Color.appCard.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
        }
    }

    /// 单行元数据
    private func metadataRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: DesignSystem.medium) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.appAccent)
                .frame(width: 20, alignment: .center)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.appSecondary)
                .frame(width: 80, alignment: .leading)

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

            // 已安装插件优先展示已缓存的本地化 README，否则使用 JSON description
            if let readme = localReadme {
                Text(readme)
                    .font(.body)
                    .foregroundStyle(.appText)
                    .lineSpacing(DesignSystem.medium)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(plugin.description)
                    .font(.body)
                    .foregroundStyle(.appText)
                    .lineSpacing(DesignSystem.medium)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
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
                        .background(Color.appAccent.opacity(0.12))
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
                                .frame(width: 20)

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
                        .background(Color.appCard.opacity(0.4))
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
                .background(Color.appCard.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
            }
        }
    }

    // MARK: - 底部信息

    private var bottomInfoSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            Text(L10n.Plugin.Detail.reportTitle)
                .font(.caption)
                .foregroundStyle(.appSecondary)

            HStack(spacing: DesignSystem.medium) {
                Button(action: {}) {
                    Label(L10n.Plugin.Detail.reportIssue, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.appSecondary)

                if plugin.downloadURL != nil {
                    Text("·")
                        .foregroundStyle(.appSecondary)
                    Link(destination: URL(string: "https://github.com/zhiyu/plugins")!) {
                        Label(L10n.Plugin.Detail.viewSource, systemImage: "chevron.left.forwardslash.chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(.appAccent)
                }
            }

            Text(plugin.id)
                .font(.system(size: 10))
                .foregroundStyle(.appSecondary.opacity(0.6))
                .padding(.top, DesignSystem.tiny)
        }
        .padding(.top, DesignSystem.medium)
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
                                .frame(width: 24)

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
        .background(color.opacity(0.1))
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
