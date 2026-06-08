//
//  LocalPluginDetailView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/06.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：展示已安装本地插件的详细信息（manifest 数据 + 卸载操作）。

import SwiftUI

/// 本地已安装插件详情页（基于 PluginManifest，无需网络）
@MainActor
struct LocalPluginDetailView: View {
    let manifest: PluginManifest

    @Environment(\.dismiss) private var dismiss
    @State private var showUninstallConfirm = false
    @State private var localIcon: UIImage?
    @State private var localReadme: String?

    private var isInstalled: Bool {
        PluginRegistry.shared.plugins.contains(where: { $0.manifest.id == manifest.id })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.giant) {

                // MARK: - 头部
                HStack(spacing: DesignSystem.wide) {
                    // 优先显示本地 icon.png，fallback SF Symbol
                    if let image = localIcon {
                        Image(uiImage: image).resizable().scaledToFit()
                            .frame(width: DesignSystem.Gallery.itemSize, height: DesignSystem.Gallery.itemSize)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.largeRadius))
                    } else {
                        Image(systemName: "puzzlepiece.extension.fill")
                            .font(.system(size: DesignSystem.Gallery.mainIconSize * 0.9))
                            .foregroundStyle(.white)
                            .frame(width: DesignSystem.Gallery.itemSize, height: DesignSystem.Gallery.itemSize)
                            .background(
                                LinearGradient(colors: [Color.appAccent, Color.appAccent.opacity(0.8)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.giant))
                    }

                    VStack(alignment: .leading, spacing: DesignSystem.small) {
                        Text(manifest.name)
                            .font(.title2.bold()).foregroundStyle(.appText)
                        Text(L10n.Plugin.Detail.byAuthor(manifest.author))
                            .font(.subheadline).foregroundStyle(.appSecondary)

                        HStack(spacing: DesignSystem.small) {
                            Text("v\(manifest.version)")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, DesignSystem.small).padding(.vertical, DesignSystem.atomic * 2)
                                .background(Color.appAccent.opacity(0.12)).foregroundStyle(.appAccent)
                                .clipShape(Capsule())

                            if isInstalled {
                                Label(L10n.Plugin.Detail.installed, systemImage: "checkmark.circle.fill")
                                    .font(.caption.weight(.medium)).foregroundStyle(.green)
                            }
                        }
                    }
                }

                // MARK: - 操作
                Button(role: .destructive, action: {
                    PluginRegistry.shared.unloadPlugin(id: manifest.id)
                    dismiss()
                }) {
                    Label(L10n.Plugin.Action.uninstall, systemImage: "trash")
                        .font(.headline).frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.small)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Divider()

                // MARK: - 元数据
                VStack(alignment: .leading, spacing: DesignSystem.medium) {
                    Text(L10n.Plugin.Detail.metadataTitle).font(.headline).foregroundStyle(.appText)
                    VStack(spacing: 0) {
                        detailRow(icon: "number", label: L10n.Plugin.Detail.version, value: manifest.version)
                        Divider().padding(.leading, DesignSystem.medium)
                        detailRow(icon: "person.fill", label: L10n.Plugin.Detail.author, value: manifest.author)
                        Divider().padding(.leading, DesignSystem.medium)
                        detailRow(icon: "key.fill", label: "ID", value: manifest.id)
                    }
                    .background(Color.appCard.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
                }

                Divider()

                // MARK: - 权限
                VStack(alignment: .leading, spacing: DesignSystem.medium) {
                    Text(L10n.Plugin.section.permissions).font(.headline).foregroundStyle(.appText)
                    ForEach(manifest.permissions, id: \.self) { perm in
                        HStack(spacing: DesignSystem.medium) {
                            Image(systemName: permIcon(for: perm)).foregroundStyle(.appAccent)
                            Text(L10n.Plugin.permTitle(for: perm)).font(.subheadline).foregroundStyle(.appText)
                        }
                        .padding(DesignSystem.medium).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.appCard.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
                    }
                }

                // MARK: - 描述
                VStack(alignment: .leading, spacing: DesignSystem.medium) {
                    Text(L10n.Plugin.section.about).font(.headline).foregroundStyle(.appText)
                    MarkdownRendererView(content: localReadme ?? manifest.description, isPrivate: false, onLinkTap: { _ in }, isCompact: true)
                }
            }
            .padding()
        }
        .background(PageBackgroundView(accentColor: .appAccent))
        .task {
            if let url = PluginRegistry.shared.iconURL(for: manifest.id), let d = try? Data(contentsOf: url) { localIcon = UIImage(data: d) }
            localReadme = PluginRegistry.shared.localizedReadme(for: manifest.id)
        }
        .navigationTitle(manifest.name)
        .appNavigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: DesignSystem.medium) {
            Image(systemName: icon).font(.subheadline).foregroundStyle(.appAccent).frame(width: 20)
            Text(label).font(.subheadline).foregroundStyle(.appSecondary).frame(width: 60, alignment: .leading)
            Spacer()
            Text(value).font(.subheadline.weight(.medium)).foregroundStyle(.appText)
        }
        .padding(.horizontal, DesignSystem.medium).padding(.vertical, DesignSystem.small + 2)
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