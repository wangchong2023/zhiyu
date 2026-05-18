// NotebookListRow.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：笔记本列表行组件。
// 版本: 1.1
// 修改记录:
//   - 2026-05-16: 视图拆分：从 NotebookHubView 提炼。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

@MainActor
struct NotebookListRow: View {
    let notebook: Vault
    @Environment(NotebookHubViewModel.self) var viewModel
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.medium) {
                // 1. 图标展示
                ZStack {
                    Circle()
                        .fill(Color.appAccent.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Text(notebook.icon ?? defaultIcon)
                        .font(.title2)
                }
                
                // 2. 元数据展示
                VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                    Text(notebook.name)
                        .font(.system(size: DesignSystem.headlineFontSize, weight: .bold))
                        .foregroundStyle(.appText)
                    
                    if let desc = notebook.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: DesignSystem.captionFontSize))
                            .foregroundStyle(.appSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // 3. 统计指标
                VStack(alignment: .trailing, spacing: DesignSystem.tiny) {
                    Text("\(notebook.pageCount)")
                        .font(.system(size: DesignSystem.bodyFontSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(.appAccent)
                    
                    Text(L10n.Vault.pageCountSuffix)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.appSecondary.opacity(0.6))
                }
            }
            .padding(DesignSystem.medium)
            .background(Color.appCard.opacity(DesignSystem.glassOpacity))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
            .contentShape(Rectangle())
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    viewModel.deleteNotebook(id: notebook.id)
                } label: {
                    Label(L10n.Common.delete, systemImage: DesignSystem.Icons.delete)
                }
                
                Button {
                    viewModel.prepareEdit(notebook)
                } label: {
                    Label(L10n.Vault.edit, systemImage: DesignSystem.Icons.edit)
                }
            }
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
    
    /// 获取根据笔记本 ID 哈希值计算出来的兜底默认 Emoji 图标
    private var defaultIcon: String {
        let index = abs(notebook.id.hashValue) % IconTokens.options.count
        return IconTokens.options[index]
    }
}
