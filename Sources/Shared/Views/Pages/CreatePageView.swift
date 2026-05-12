// CreatePageView.swift
//
// 作者: Wang Chong
// 功能说明: struct CreatePageView
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

struct CreatePageView: View {
    @Environment(AppStore.self) var store
    @Environment(AppRouter.self) var router
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var type: PageType = .concept
    @State private var tags = ""
    @State private var content = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L10n.Creation.tr("pageTitle"), text: $title)
                        .font(.body)
                        .accessibilityIdentifier("pageTitle")
                    
                    // Type picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(PageType.allCases) { pageType in
                                Button(action: { type = pageType }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: pageType.icon)
                                            .font(.caption)
                                        Text(pageType.displayName)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(type == pageType ? Color.fromModelColorName(pageType.colorName).opacity(0.25) : Color.appCard)
                                    .clipShape(RoundedRectangle(cornerRadius: AppUI.smallRadius))
                                    .foregroundStyle(type == pageType ? Color.fromModelColorName(pageType.colorName) : .appSecondary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppUI.smallRadius)
                                            .stroke(type == pageType ? Color.fromModelColorName(pageType.colorName).opacity(0.5) : Color.clear, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    TextField(L10n.Creation.tr("tagsPlaceholder"), text: $tags)
                } header: {
                    Text(L10n.Creation.tr("basicInfo"))
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
                        Text(L10n.Creation.tr("content"))
                        Spacer()
                        Text(L10n.Editor.tr("bidirectionalLinks"))
                            .font(.caption2)
                            .foregroundStyle(.appSecondary)
                    }
                }
                
                // Quick templates
                Section {
                    Button(action: applyEntityTemplate) {
                        Label(L10n.Creation.tr("entityTemplate"), systemImage: "person.text.rectangle.fill")
                    }
                    Button(action: applyConceptTemplate) {
                        Label(L10n.Creation.tr("conceptTemplate"), systemImage: "lightbulb.fill")
                    }
                    Button(action: applyComparisonTemplate) {
                        Label(L10n.Creation.tr("comparisonTemplate"), systemImage: "arrow.left.arrow.right.circle.fill")
                    }
                } header: {
                    Text(L10n.Creation.tr("quickTemplates"))
                }
            }
            .scrollContentBackground(.hidden)
            .background(PageBackgroundView(accentColor: .appAccent))
            .navigationTitle(L10n.Creation.tr("title"))
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Creation.tr("create")) {
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
        
        let page = store.createPage(
            title: title,
            type: type,
            content: content,
            tags: tagList
        )
        
        router.navigateToPage(id: page.id)
        dismiss()
    }
    
    private var entityTemplateContent: String {
        """
        # \(title)
        
        【\(L10n.Creation.tr("template.entity.overview"))】
        \(L10n.Creation.tr("template.entity.overviewPlaceholder"))
        
        【\(L10n.Creation.tr("template.entity.contributions"))】
        \(L10n.Creation.tr("template.entity.contributionsPlaceholder"))
        
        【\(L10n.Creation.tr("template.entity.related"))】
        \(L10n.Creation.tr("template.entity.relatedPlaceholder"))
        
        """
    }
    
    private func applyEntityTemplate() {
        content = entityTemplateContent
    }
    
    private func applyConceptTemplate() {
        content = """
        # \(title)

        【\(L10n.Creation.tr("template.concept.definition"))】
        \(L10n.Creation.tr("template.concept.definitionPlaceholder"))

        【\(L10n.Creation.tr("template.concept.analysis"))】
        \(L10n.Creation.tr("template.concept.analysisPlaceholder"))

        【\(L10n.Creation.tr("template.concept.links"))】
        \(L10n.Creation.tr("template.concept.linksPlaceholder"))

        """
    }

    private func applyComparisonTemplate() {
        content = """
        # \(title) \(L10n.Creation.tr("template.comparison.suffix"))

        【\(L10n.Creation.tr("template.comparison.dimensions"))】
        \(L10n.Creation.tr("template.comparison.dimensionsPlaceholder"))

        【\(L10n.Creation.tr("template.comparison.conclusion"))】
        \(L10n.Creation.tr("template.comparison.conclusionPlaceholder"))

        """
    }
}
