//
//  EditorComponents.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：属于 Editors 模块，提供相关的结构体或工具支撑。
//
import SwiftUI

// MARK: - Knowledge Link Picker Sheet
/// PageLink 选择器面板组件
/// 负责在编辑器中搜索并插入双链引用的选择界面，支持模糊搜索及页面类型过滤
struct PageLinkPickerSheet: View {
    @Binding var page: KnowledgePage
    @Binding var editorContent: String
    @Environment(AppStore.self) var store
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredPages: [KnowledgePage] {
        let pages = store.pages.filter { $0.id != page.id }
        if searchText.isEmpty { return pages }
        return pages.filter { $0.title.lowercased().contains(searchText.lowercased()) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                pageList
            }
            .background(PageBackgroundView(accentColor: .appAccent))
            .navigationTitle(L10n.Editor.insertPageLink)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: DesignSystem.small) {
            Image(systemName: DesignSystem.Icons.search)
                .foregroundStyle(Color.appSecondary)
            TextField(L10n.Editor.searchPages, text: $searchText)
                .foregroundStyle(Color.appText)
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: DesignSystem.Icons.errorCircle)
                        .foregroundStyle(Color.appSecondary)
                }
            }
        }
        .padding(DesignSystem.standardPadding)
        .background(Color.appCard)
    }
    
    private var pageList: some View {
        List {
            ForEach(filteredPages, id: \.id) { p in
                Button {
                    let link = " [[\(p.title)]]"
                    editorContent.append(link)
                    dismiss()
                } label: {
                    HStack(spacing: DesignSystem.medium) {
                        Image(systemName: p.pageType.icon)
                            .foregroundStyle(Color.fromModelColorName(p.pageType.colorName))
                            .frame(width: DesignSystem.Gallery.iconSize, height: DesignSystem.Gallery.iconSize)
                            .background(Color.fromModelColorName(p.pageType.colorName).opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.microRadius))
                        
                        VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                            Text(p.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.appText)
                            Text(p.pageType.displayName)
                                .font(.caption2)
                                .foregroundStyle(Color.appSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: DesignSystem.Icons.plusCircle)
                            .foregroundStyle(Color.appText)
                    }
                    .padding(.vertical, DesignSystem.tiny)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Editor Toolbar Button
/// 编辑器工具栏按钮组件
struct EditorToolbarButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.atomic) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(Color.appSecondary)
            .frame(width: 44, height: 36)
            .background(Color.appBorder.opacity(DesignSystem.Opacity.glass))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.microRadius))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(title)
    }
}

// MARK: - Tag Chip
/// 标签胶囊组件
struct TagChip: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.tiny) {
            Text("#\(tag)")
                .font(.caption)
                .foregroundStyle(Color.appAccent)
            Button(action: onRemove) {
                Image(systemName: DesignSystem.Icons.errorCircle)
                    .font(.caption2)
                    .foregroundStyle(Color.appSecondary)
            }
        }
        .padding(.horizontal, DesignSystem.small)
        .padding(.vertical, DesignSystem.tiny)
        .background(Color.appAccent.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Alias Chip
/// 别名胶囊组件
struct AliasChip: View {
    let alias: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.tiny) {
            Text(alias)
                .font(.caption)
                .foregroundStyle(Color.appSource)
            Button(action: onRemove) {
                Image(systemName: DesignSystem.Icons.errorCircle)
                    .font(.caption2)
                    .foregroundStyle(Color.appSecondary)
            }
        }
        .padding(.horizontal, DesignSystem.small)
        .padding(.vertical, DesignSystem.tiny)
        .background(Color.appSource.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Inline Tag Input
/// 内联标签输入组件
struct InlineTagInput: View {
    @Binding var text: String
    let onCommit: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.small) {
            TextField(L10n.Editor.enterTag, text: $text)
                .font(.caption)
                .textFieldStyle(.plain)
                .padding(.horizontal, DesignSystem.medium)
                .padding(.vertical, DesignSystem.small)
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.microRadius))
                .foregroundStyle(Color.appText)
                .onSubmit { onCommit() }
            
            Button(action: onCommit) {
                Image(systemName: DesignSystem.Icons.checkCircle)
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            
            Button(action: onCancel) {
                Image(systemName: DesignSystem.Icons.errorCircle)
                    .font(.caption)
                    .foregroundStyle(Color.appSecondary)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, DesignSystem.small)
        .background(Color.appCard)
    }
}