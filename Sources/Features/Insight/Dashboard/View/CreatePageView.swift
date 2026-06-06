//
//  CreatePageView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：构建 CreatePage 界面的 UI 视图层组件。
//
import SwiftUI

struct CreatePageView: View {
    @Environment(AppStore.self) var store
    @Environment(Router.self) var router
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var type: PageType = .concept
    @State private var tags = ""
    @State private var content = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L10n.Creation.pageTitle, text: $title)
                        .font(.body)
                        .accessibilityIdentifier("pageTitle")
                    
                    // Type picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignSystem.small) {
                            ForEach(PageType.allCases) { pageType in
                                Button(action: { type = pageType }) {
                                    HStack(spacing: DesignSystem.tightPadding) {
                                        Image(systemName: pageType.icon)
                                            .font(.caption)
                                        Text(pageType.displayName)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, DesignSystem.medium)
                                    .padding(.vertical, DesignSystem.small)
                                    .background(type == pageType ? Color.fromModelColorName(pageType.colorName).opacity(0.25) : Color.appCard)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
                                    .foregroundStyle(type == pageType ? Color.fromModelColorName(pageType.colorName) : .appSecondary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignSystem.smallRadius)
                                            .stroke(type == pageType ? Color.fromModelColorName(pageType.colorName).opacity(0.5) : Color.clear, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    TextField(L10n.Creation.tagsPlaceholder, text: $tags)
                } header: {
                    Text(L10n.Creation.basicInfo)
                }
                
                Section {
                    #if os(watchOS)
                    TextField("", text: $content, axis: .vertical)
                        .font(.body)
                    #else
                    TextEditor(text: $content)
                        .font(.body)
                        .frame(minHeight: 150)
                    #endif
                } header: {
                    HStack {
                        Text(L10n.Creation.content)
                        Spacer()
                        Text(L10n.Editor.bidirectionalLinks)
                            .font(.caption2)
                            .foregroundStyle(.appSecondary)
                    }
                }
                
                // Quick templates
                Section {
                    VStack(spacing: DesignSystem.small) {
                        templateCard(
                            icon: DesignSystem.Icons.entity,
                            title: L10n.Creation.entityTemplate,
                            description: L10n.Creation.template.entity.desc,
                            action: applyEntityTemplate
                        )
                        templateCard(
                            icon: DesignSystem.Icons.concept,
                            title: L10n.Creation.conceptTemplate,
                            description: L10n.Creation.template.concept.desc,
                            action: applyConceptTemplate
                        )
                        templateCard(
                            icon: DesignSystem.Icons.comparison,
                            title: L10n.Creation.comparisonTemplate,
                            description: L10n.Creation.template.comparison.desc,
                            action: applyComparisonTemplate
                        )
                    }
                } header: {
                    Text(L10n.Creation.quickTemplates)
                }
            }
            .scrollContentBackground(.hidden)
            .background(PageBackgroundView(accentColor: .appAccent))
            .navigationTitle(L10n.Creation.title)
.appNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Creation.create) {
                        createPage()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func createPage() {
        let tagList = tags.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        Task {
            let page = await store.createPage(
                title: title,
                pageType: type,
                content: content,
                tags: tagList
            )
            
            await MainActor.run {
                router.navigateToPage(id: page.id)
                dismiss()
            }
        }
    }
    
    // MARK: - 引导式模板

    private func applyEntityTemplate() {
        type = .entity
        content = """
        \(L10n.Creation.template.entity.overview)
        \(L10n.Creation.template.entity.overviewHint)

        """
    }

    private func applyConceptTemplate() {
        type = .concept
        content = """
        \(L10n.Creation.template.concept.definition)
        \(L10n.Creation.template.concept.analysisHint)

        """
    }

    private func applyComparisonTemplate() {
        type = .comparison
        content = """
        \(L10n.Creation.template.comparison.table)

        \(L10n.Creation.template.comparison.conclusionHint)

        """
    }

    // MARK: - 模板卡片

    private func templateCard(icon: String, title: String, description: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.medium) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.appAccent)
                    .frame(width: DesignSystem.iconLarge)
                VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.appText)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.appSecondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: DesignSystem.Icons.forward)
                    .font(.caption)
                    .foregroundStyle(.appSecondary.opacity(0.4))
            }
            .padding(.vertical, DesignSystem.tiny)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
