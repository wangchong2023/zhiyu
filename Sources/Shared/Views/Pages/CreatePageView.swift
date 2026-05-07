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
                    TextEditor(text: $content)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 150)
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
            .background(Color.appBackground)
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
    
    private func applyEntityTemplate() {
        content = """
        # \(title)
        
        【\(L10n.Creation.tr("template.entity.overview"))】
        在这里输入人物、机构或物品的简要介绍...
        
        【\(L10n.Creation.tr("template.entity.contributions"))】
        列出核心成就或主要贡献...
        
        【\(L10n.Creation.tr("template.entity.related"))】
        使用 [[页面标题]] 关联到其他知识点...
        
        """
    }
    
    private func applyConceptTemplate() {
        content = """
        # \(title)

        【\(L10n.Creation.tr("template.concept.definition"))】
        在这里输入概念的定义或核心内涵...

        【\(L10n.Creation.tr("template.concept.analysis"))】
        1. 关键要素 A：[描述...]
        2. 关键要素 B：[描述...]

        【\(L10n.Creation.tr("template.concept.links"))】
        关联概念：[[概念名称]]

        """
    }

    private func applyComparisonTemplate() {
        content = """
        # \(title) \(L10n.Creation.tr("template.comparison.suffix"))

        【\(L10n.Creation.tr("template.comparison.dimensions"))】
        - 维度 1: 对象 A vs 对象 B
        - 维度 2: 对象 A vs 对象 B

        【\(L10n.Creation.tr("template.comparison.conclusion"))】
        在这里输入对比后的总结性见解...

        """
    }
}
