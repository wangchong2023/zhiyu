//
//  PageDetailContentSection.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：仪表盘：页面列表、知识统计、每周洞察、回链视图。
//
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
