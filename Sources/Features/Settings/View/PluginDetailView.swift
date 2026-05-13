// PluginDetailView.swift
//
// 作者: Wang Chong
// 功能说明: struct PluginDetailView
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

struct PluginDetailView: View {
    let name: String
    let author: String
    let version: String
    let description: String
    let icon: String
    
    @Environment(\.dismiss) var dismiss
    @State private var isInstalled = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header section
                HStack(spacing: 20) {
                    Image(systemName: icon)
                        .font(.system(size: DesignSystem.Gallery.mainIconSize))
                        .foregroundStyle(.white)
                        .frame(width: DesignSystem.Gallery.itemSize, height: DesignSystem.Gallery.itemSize)
                        .background(LinearGradient(colors: [Color.appAccent, Color.appAccent.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: Color.appAccent.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(name).font(.title2.bold()).foregroundStyle(.appText)
                        Text(author).font(.subheadline).foregroundStyle(.appSecondary)
                        
                        HStack(spacing: 15) {
                            statItem(label: Localized.tr("plugin.stat.downloads"), value: "1.2K", icon: "arrow.down.circle")
                            statItem(label: Localized.tr("plugin.stat.rating"), value: "4.9", icon: "star.fill", color: .yellow)
                        }
                        .padding(.top, DesignSystem.tiny)
                    }
                }
                
                // Action Section
                actionButtons
                
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
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation { isInstalled.toggle() }
                HapticFeedback.shared.trigger(.success)
            }) {
                Label(isInstalled ? Localized.tr("plugin.action.uninstall") : Localized.tr("plugin.action.install"), systemImage: isInstalled ? "trash" : "icloud.and.arrow.down")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.small)
            }
            .buttonStyle(.borderedProminent)
            .tint(.appAccent)
            
            Button(action: {}) {
                Image(systemName: "square.and.arrow.up")
                    .padding(DesignSystem.small)
            }
            .buttonStyle(.bordered)
        }
    }
    
    private func statItem(label: String, value: String, icon: String, color: Color = .appSecondary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon).foregroundStyle(color)
                Text(value).bold()
            }
            .font(.caption)
            Text(label).font(.system(size: DesignSystem.microFontSize)).foregroundStyle(.appSecondary)
        }
    }
    
    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localized.tr("plugin.section.permissions"))
                .font(.headline)
            
            HStack(spacing: 8) {
                PermissionTag(icon: "lock.shield", text: Localized.tr("plugin.perm.sandbox"), color: .green)
                PermissionTag(icon: "network", text: Localized.tr("plugin.perm.network"), color: .blue)
                PermissionTag(icon: "pencil.and.outline", text: Localized.tr("plugin.perm.content"), color: .orange)
            }
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localized.tr("plugin.section.about"))
                .font(.headline)
            
            Text(description)
                .font(.body)
                .foregroundStyle(.appText)
                .lineSpacing(6)
        }
    }
}

struct PermissionTag: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption2.bold())
        .padding(.horizontal, DesignSystem.small)
        .padding(.vertical, DesignSystem.tiny)
        .background(color.opacity(0.1))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

struct BulletPoint: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").bold()
            Text(text).font(.subheadline).foregroundStyle(.appSecondary)
        }
    }
}
