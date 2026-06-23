//
//  PluginDetailSupportViews.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：插件详情模块的辅助独立视图 —— 权限确认弹窗（PermissionConfirmationSheet）、
//  权限标签胶囊（PermissionTag）与要点列表项（BulletPoint）。
//

import SwiftUI

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
