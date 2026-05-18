// NotebookCard.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：笔记本卡片组件。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

struct NotebookCard: View {
    @Environment(NotebookHubViewModel.self) var viewModel
    let notebook: Vault
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: DesignSystem.standardPadding) {
                // 1. 图标展示 (彩色光晕底座)
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(colorForVault.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Text(notebook.icon ?? defaultIcon)
                        .font(.system(size: 22))
                }
                .padding(.top, DesignSystem.tiny)
                
                // 2. 标题
                Text(notebook.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                // 3. 摘要描述
                Text(notebook.description ?? L10n.Vault.defaultDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer(minLength: DesignSystem.small)
                
                // 4. 元数据 (国际化相对时间)
                Text("\(L10n.Vault.lastEdited) \(notebook.updatedAt.formatted(.relative(presentation: .numeric)))")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary.opacity(0.6))
            }
            .padding(DesignSystem.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 180)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.primary.opacity(0.04), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.02), radius: 8, y: 4)
            .contextMenu {
                Button {
                    viewModel.prepareEdit(notebook)
                } label: {
                    Label(L10n.Vault.edit, systemImage: DesignSystem.Icons.edit)
                }
                
                Button(role: .destructive) {
                    viewModel.deleteNotebook(id: notebook.id)
                } label: {
                    Label(L10n.Common.delete, systemImage: DesignSystem.Icons.delete)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var colorForVault: Color {
        let colors: [Color] = [.blue, .purple, .orange, .green, .pink, .teal]
        let index = abs(notebook.name.hashValue) % colors.count
        return colors[index]
    }
    
    private var defaultIcon: String {
        let icons = ["📓", "📚", "💡", "🧠", "✍️", "🚀", "🎨", "📁", "🌟", "🛠️"]
        let index = abs(notebook.id.hashValue) % icons.count
        return icons[index]
    }
}
