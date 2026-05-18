// PageDetailContentSection.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：知识详情页核心内容展示与编辑器区域。
// 版本: 1.0
// 修改记录:
//   - 2026-05-18: 从 PageDetailView 剥离，支持 Markdown 编辑与渲染。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 页面详情内容展示与编辑区
struct PageDetailContentSection: View {
    @Binding var page: KnowledgePage
    @Binding var isEditing: Bool
    let onLinkTap: (String) -> Void
    
    var body: some View {
        Group {
            if isEditing {
                MarkdownEditorView(text: $page.content, placeholder: L10n.Editor.placeholder)
                    .padding(.top, DesignSystem.wide)
            } else if page.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                emptyStateView
            } else {
                MarkdownRendererView(content: page.content, isPrivate: page.isPrivate, onLinkTap: onLinkTap)
                    .padding(.vertical)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.medium) {
            Image(systemName: DesignSystem.Icons.pencilLine)
                .font(.system(size: DesignSystem.huge))
                .foregroundStyle(.appSecondary)
            Text(L10n.Knowledge.Page.empty)
                .font(.subheadline)
                .foregroundStyle(.appSecondary)
            Text(L10n.Knowledge.Page.emptyHint)
                .font(.caption)
                .foregroundStyle(.appAccent.opacity(0.7))
                .padding(.horizontal, DesignSystem.wide)
                .padding(.vertical, DesignSystem.small)
                .background(Color.appAccent.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
}
