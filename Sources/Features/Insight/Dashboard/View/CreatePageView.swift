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

    // 结构化表单字段（替代单一 TextEditor）
    @State private var definition = ""   // 一句话定义/描述
    @State private var bodyContent = ""  // 主体内容
    @State private var relatedLinks = "" // 关联页面标题

    /// 当前类型对应的模板标题（由模板按钮设置，用于 Section header）
    @State private var bodySectionTitle = L10n.Creation.content

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

                // ── 结构化内容区 ──
                Section {
                    VStack(alignment: .leading, spacing: DesignSystem.medium) {
                        // 一句话定义
                        definitionField

                        Divider()

                        // 主体内容
                        bodyContentField

                        Divider()

                        // 关联页面
                        relatedLinksField
                    }
                } header: {
                    HStack {
                        Text(bodySectionTitle)
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

    // MARK: - 结构化表单组件

    @ViewBuilder
    private var definitionField: some View {
        VStack(alignment: .leading, spacing: DesignSystem.tiny) {
            Text(L10n.Creation.content)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.appSecondary)
            TextField(L10n.Creation.template.entity.desc, text: $definition, axis: .vertical)
                .font(.body)
        }
    }

    @ViewBuilder
    private var bodyContentField: some View {
        VStack(alignment: .leading, spacing: DesignSystem.tiny) {
            #if os(watchOS)
            TextField(bodySectionHint, text: $bodyContent, axis: .vertical)
                .font(.body)
            #else
            TextEditor(text: $bodyContent)
                .font(.body)
                .frame(minHeight: 100)
                .overlay(alignment: .topLeading) {
                    if bodyContent.isEmpty {
                        Text(bodySectionHint)
                            .font(.body)
                            .foregroundStyle(.appSecondary.opacity(0.4))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                }
            #endif
        }
    }

    @ViewBuilder
    private var relatedLinksField: some View {
        VStack(alignment: .leading, spacing: DesignSystem.tiny) {
            Text(verbatim: L10n.Creation.template.entity.related
                .replacingOccurrences(of: "## ", with: "")
                .replacingOccurrences(of: "\n", with: "")
                .trimmingCharacters(in: .whitespaces))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.appSecondary)
            TextField(L10n.Creation.tagsPlaceholder, text: $relatedLinks)
                .font(.body)
        }
    }

    /// 内容区 placeholder 提示文字
    private var bodySectionHint: String {
        switch type {
        case .entity: return L10n.Creation.template.entity.overviewHint
        case .concept: return L10n.Creation.template.concept.analysisHint
        case .comparison: return L10n.Creation.template.comparison.conclusionHint
        default: return ""
        }
    }

    // MARK: - 创建页面

    private func createPage() {
        let tagList = tags.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var relatedSection = ""
        if !relatedLinks.isEmpty {
            let links = relatedLinks.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            if !links.isEmpty {
                relatedSection = "\n## \(L10n.Creation.relatedLinks)\n" + links.map { "- \($0)" }.joined(separator: "\n") + "\n"
            }
        }

        let content = """
        \(definition)

        \(bodyContent)
        \(relatedSection)
        """

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
        bodySectionTitle = L10n.Creation.template.entity.overview
            .replacingOccurrences(of: "## ", with: "")
            .replacingOccurrences(of: "\n", with: "")
        if definition.isEmpty { definition = "" }
    }

    private func applyConceptTemplate() {
        type = .concept
        bodySectionTitle = L10n.Creation.template.concept.definition
            .replacingOccurrences(of: "## ", with: "")
            .replacingOccurrences(of: "\n", with: "")
        if definition.isEmpty { definition = "" }
    }

    private func applyComparisonTemplate() {
        type = .comparison
        bodySectionTitle = L10n.Creation.template.comparison.desc
        if bodyContent.isEmpty {
            bodyContent = L10n.Creation.template.comparison.table
        }
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
