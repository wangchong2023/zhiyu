//
//  PluginDetailView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：构建 PluginDetail 界面的 UI 视图层组件。
//
import SwiftUI

struct PluginDetailView: View {
    let plugin: MarketPlugin
    @ObservedObject var marketService: PluginMarketService
    
    @Environment(\.dismiss) var dismiss
    @State private var showPermissionSheet = false
    @State private var isInstalling = false
    
    private var isInstalled: Bool {
        PluginRegistry.shared.plugins.contains(where: { $0.manifest.id == plugin.id })
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.giant) {
                // Header section
                HStack(spacing: DesignSystem.wide) {
                    Image(systemName: plugin.icon)
                        .font(.system(size: DesignSystem.Gallery.mainIconSize))
                        .foregroundStyle(.white)
                        .frame(width: DesignSystem.Gallery.itemSize, height: DesignSystem.Gallery.itemSize)
                        .background(LinearGradient(colors: [Color.appAccent, Color.appAccent.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: Color.appAccent.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.small) {
                        Text(plugin.name).font(.title2.bold()).foregroundStyle(.appText)
                        Text(plugin.author).font(.subheadline).foregroundStyle(.appSecondary)
                        
                        HStack(spacing: 15) {
                            statItem(label: L10n.Plugin.Stats.downloads, value: plugin.downloads, icon: DesignSystem.Icons.arrowDownCircle)
                            statItem(label: L10n.Plugin.Stats.rating, value: String(format: "%.1f", plugin.rating), icon: DesignSystem.Icons.star, color: .yellow)
                        }
                        .padding(.top, DesignSystem.tiny)
                    }
                }
                
                // Action Section
                actionButtons
                
                if let error = marketService.errorMessage {
                    Text(error).font(.caption).foregroundStyle(.red).padding(.top, -DesignSystem.small)
                }
                
                Divider()
                
                // Permissions Section
                permissionsSection
                
                Divider()
                
                // Description Section
                descriptionSection
                
                Spacer()
            }
            .padding()
        }
        .background(PageBackgroundView(accentColor: .appAccent))
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
    
    private var actionButtons: some View {
        HStack(spacing: DesignSystem.medium) {
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
                    Label(isInstalled ? L10n.Plugin.Action.uninstall : L10n.Plugin.Action.install, 
                          systemImage: isInstalled ? DesignSystem.Icons.delete : DesignSystem.Icons.pullFromCloud)
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.small)
            }
            .buttonStyle(.borderedProminent)
            .tint(isInstalled ? .red : .appAccent)
            .disabled(isInstalling || marketService.downloadingPluginID == plugin.id)
            
            Button(action: {}) {
                Image(systemName: DesignSystem.Icons.export)
                    .padding(DesignSystem.small)
            }
            .buttonStyle(.bordered)
        }
    }
    
    private func statItem(label: String, value: String, icon: String, color: Color = .appSecondary) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.atomic) {
            HStack(spacing: DesignSystem.tiny) {
                Image(systemName: icon).foregroundStyle(color)
                Text(value).bold()
            }
            .font(.caption)
            Text(label).font(.system(size: DesignSystem.microFontSize)).foregroundStyle(.appSecondary)
        }
    }
    
    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            Text(L10n.Plugin.section.permissions)
                .font(.headline)
            
            if let perms = plugin.requiredPermissions, !perms.isEmpty {
                FlowLayout(spacing: DesignSystem.small) {
                    ForEach(perms, id: \.self) { perm in
                        PermissionTag(perm: perm)
                    }
                }
            } else {
                Text(L10n.Plugin.perm.none).font(.subheadline).foregroundStyle(.appSecondary)
            }
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            Text(L10n.Plugin.section.about)
                .font(.headline)
            
            Text(plugin.description)
                .font(.body)
                .foregroundStyle(.appText)
                .lineSpacing(6)
        }
    }
}

/// 权限确认面板
struct PermissionConfirmationSheet: View {
    let plugin: MarketPlugin
    var onConfirm: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: DesignSystem.giant) {
            VStack(spacing: DesignSystem.medium) {
                Image(systemName: DesignSystem.Icons.lockShieldFill)
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
            
            VStack(alignment: .leading, spacing: DesignSystem.standardPadding) {
                Text(L10n.Plugin.section.permissions).font(.caption.bold()).foregroundStyle(.appSecondary)
                
                if let perms = plugin.requiredPermissions {
                    ForEach(perms, id: \.self) { perm in
                        HStack(spacing: DesignSystem.medium) {
                            Image(systemName: permIcon(for: perm))
                                .foregroundStyle(.appAccent)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                                Text(permTitle(for: perm)).font(.subheadline.bold())
                                Text(permDesc(for: perm)).font(.caption).foregroundStyle(.appSecondary)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Spacer()
            
            VStack(spacing: DesignSystem.medium) {
                Button(action: onConfirm) {
                    Text(L10n.Plugin.Action.confirmInstall)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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
        case "writeContent": return DesignSystem.Icons.pencilOutline
        case "llm": return DesignSystem.Icons.brain
        case "pages.read": return DesignSystem.Icons.weeklyInsight
        default: return DesignSystem.Icons.keyFill
        }
    }
    
    private func permTitle(for perm: String) -> String {
        L10n.Plugin.permTitle(for: perm)
    }
    
    private func permDesc(for perm: String) -> String {
        L10n.Plugin.permDesc(for: perm)
    }
}

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
        case "writeContent": return .orange
        case "llm": return .purple
        case "pages.read": return .blue
        default: return .appSecondary
        }
    }
    
    private var icon: String {
        switch perm {
        case "writeContent": return DesignSystem.Icons.pencilOutline
        case "llm": return DesignSystem.Icons.brain
        case "pages.read": return DesignSystem.Icons.weeklyInsight
        default: return DesignSystem.Icons.keyFill
        }
    }
}


struct BulletPoint: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.small) {
            Text(DesignSystem.Icons.bullet).bold()
            Text(text).font(.subheadline).foregroundStyle(.appSecondary)
        }
    }
}
