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
                        .font(.system(.body, design: .monospaced))
                    #else
                    TextEditor(text: $content)
                        .font(.system(.body, design: .monospaced))
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
                    Button(action: applyEntityTemplate) {
                        Label(L10n.Creation.entityTemplate, systemImage: DesignSystem.Icons.entity)
                    }
                    Button(action: applyConceptTemplate) {
                        Label(L10n.Creation.conceptTemplate, systemImage: DesignSystem.Icons.concept)
                    }
                    Button(action: applyComparisonTemplate) {
                        Label(L10n.Creation.comparisonTemplate, systemImage: DesignSystem.Icons.comparison)
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
    
    private var entityTemplateContent: String {
        """
        # \(title)
        
        \(L10n.Creation.template.entity.overview)
        \(L10n.Creation.template.entity.overviewPlaceholder)
        
        \(L10n.Creation.template.entity.contributions)
        \(L10n.Creation.template.entity.contributionsPlaceholder)
        
        \(L10n.Creation.template.entity.related)
        \(L10n.Creation.template.entity.relatedPlaceholder)
        
        """
    }
    
    private func applyEntityTemplate() {
        content = entityTemplateContent
    }
    
    private func applyConceptTemplate() {
        content = """
        # \(title)

        \(L10n.Creation.template.concept.definition)
        \(L10n.Creation.template.concept.definitionPlaceholder)

        \(L10n.Creation.template.concept.analysis)
        \(L10n.Creation.template.concept.analysisPlaceholder)

        \(L10n.Creation.template.concept.links)
        \(L10n.Creation.template.concept.linksPlaceholder)

        """
    }

    private func applyComparisonTemplate() {
        content = """
        # \(title) \(L10n.Creation.template.comparison.suffix)

        \(L10n.Creation.template.comparison.dimensions)
        \(L10n.Creation.template.comparison.dimensionsPlaceholder)

        \(L10n.Creation.template.comparison.conclusion)
        \(L10n.Creation.template.comparison.conclusionPlaceholder)

        """
    }
}
