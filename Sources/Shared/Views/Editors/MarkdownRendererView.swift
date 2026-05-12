// MarkdownRendererView.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了基于文本块解析的高级 Markdown 渲染组件（MarkdownRendererView），负责将抽象的 Markdown 语法树转化为原生 SwiftUI 视图流。
// 该渲染引擎通过以下核心功能点确保了知识内容的高效展示与沉浸式阅读体验：
// 1. 结构化块渲染：支持标题（H1-H6）、段落、列表、引用块、代码块及表格的差异化渲染，并自动适配系统的 AppUI 设计规范。
// 2. 交互式内联解析：实现了 知识库链接 内部链接、标准超链接、加粗、斜体及行内代码的混合解析，支持点击跳转至关联页面。
// 3. 多模态内容集成：深度集成了 Mermaid 绘图引擎与任务列表（Task List），支持在文档中直接嵌入动态图表与待办事项。
// 4. 安全与性能优化：内置了基于隐私模式的模糊遮罩逻辑，并利用 Skeleton View 提供流式生成阶段的视觉占位反馈。
// 版本: 1.1
// 修改记录:
//   - 2026-05-05: 升级全工程文档规范，消除渲染器内部的魔鬼数字
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。
//

@preconcurrency import SwiftUI

// MARK: - Markdown Renderer View
/// Renders structured Markdown blocks using MarkdownProcessor.
/// Parsing logic is extracted to MarkdownProcessor service for reuse.
@MainActor
struct MarkdownRendererView: View {
    @Environment(AppStore.self) var store
    let content: String
    let isPrivate: Bool
    let onLinkTap: (String) -> Void
    var isCompact: Bool = false

    @State private var tempUnlocked = false
    private let parser = MarkdownProcessor()

    var body: some View {
        Group {
            if content.isEmpty && store.llmService.isProcessing {
                renderSkeleton()
            } else {
                VStack(alignment: .leading, spacing: AppUI.medium) {
                    let blocks = parser.parse(content)
                    ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                        renderBlock(block)
                    }
                }
            }
        }
        .blur(radius: (store.isPrivacyModeEnabled && isPrivate && !tempUnlocked) ? AppUI.cardRadius : 0)
        .overlay {
            if store.isPrivacyModeEnabled && isPrivate && !tempUnlocked {
                VStack(spacing: AppUI.medium) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: AppUI.largeIconSize / 1.5))
                    Text(Localized.tr("security.privacyMasked"))
                        .font(AppUI.titleFont)
                    Button(action: {
                        authenticate()
                    }) {
                        Label(Localized.tr("security.unlockToView"), systemImage: "lock.open.fill")
                            .padding(.horizontal, AppUI.standardPadding)
                            .padding(.vertical, AppUI.tightPadding)
                            .background(Color.appAccent)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .foregroundStyle(.appText)
            }
        }
    }

    private func authenticate() {
        Task {
            if await store.securityService.authenticateWithBiometrics() {
                await MainActor.run {
                    withAnimation { tempUnlocked = true }
                    HapticFeedback.shared.trigger(.unlock)
                }
            }
        }
    }

    // MARK: - Block Renderer
    @ViewBuilder
    private func renderBlock(_ block: MarkdownProcessor.BlockType) -> some View {
        switch block {
        case .heading(let text, let level):
            renderHeading(text: text, level: level)
        case .paragraph(let text):
            renderParagraph(text: text)
        case .bulletList(let items, let indent):
            renderBulletList(items: items, indent: indent)
        case .blockquote(let text):
            renderBlockquote(text: text)
        case .codeBlock(let code, let language):
            renderCodeBlock(code: code, language: language)
        case .table(let headers, let rows):
            renderTable(headers: headers, rows: rows)
        case .horizontalRule:
            renderHorizontalRule()
        case .taskList(let items):
            renderTaskList(items: items)
        case .details(let summary, let content):
            renderDetailsBlock(summary: summary, content: content)
        }
    }

    @ViewBuilder
    private func renderDetailsBlock(summary: String, content: String) -> some View {
        #if os(watchOS)
        VStack(alignment: .leading, spacing: AppUI.tiny) {
            Text(summary)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.appAccent)
            MarkdownRendererView(content: content, isPrivate: isPrivate, onLinkTap: onLinkTap, isCompact: true)
                .padding(.top, AppUI.tiny)
        }
        .padding(AppUI.medium)
        .background(Color.appAccent.opacity(AppUI.glassOpacity / 3))
        .clipShape(RoundedRectangle(cornerRadius: AppUI.cardRadius))
        .padding(.vertical, AppUI.tiny)
        #else
        DisclosureGroup {
            MarkdownRendererView(content: content, isPrivate: isPrivate, onLinkTap: onLinkTap, isCompact: true)
                .padding(.top, AppUI.tiny)
        } label: {
            Text(summary)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.appAccent)
        }
        .padding(AppUI.medium)
        .background(Color.appAccent.opacity(AppUI.glassOpacity / 3))
        .clipShape(RoundedRectangle(cornerRadius: AppUI.cardRadius))
        .padding(.vertical, AppUI.tiny)
        #endif
    }

    // MARK: - Render Heading
    private func renderHeading(text: String, level: Int) -> some View {
        let headingLevel = AppUI.HeadingLevel(rawValue: level) ?? .h6
        let isMainTitle = level == 1
        
        return Text(text)
            .font(.system(size: headingLevel.size, design: .rounded).weight(headingLevel.weight))
            .font(.system(size: headingLevel.size + 2, design: .rounded).weight(headingLevel.weight))
            .foregroundStyle(.appText)
            .multilineTextAlignment(isMainTitle ? .center : .leading)
            .frame(maxWidth: .infinity, alignment: isMainTitle ? .center : .leading)
            .padding(.top, isMainTitle ? AppUI.widePadding : headingLevel.topPadding)
            .padding(.bottom, isMainTitle ? AppUI.standardPadding : AppUI.tiny)
    }

    @ViewBuilder
    private func renderParagraph(text: String) -> some View {
        renderInlineContent(text)
            .font(isCompact ? AppUI.secondaryFont : .system(.body, design: .serif))
            .lineSpacing(isCompact ? AppUI.atomic * 2 : AppUI.tiny * 1.5)
            .foregroundStyle(.appText.opacity(AppUI.fullOpacity - AppUI.glassOpacity))
    }

    // MARK: - Render Bullet List
    @ViewBuilder
    private func renderBulletList(items: [String], indent: Int) -> some View {
        let isOrdered = indent == -1
        VStack(alignment: .leading, spacing: AppUI.tiny) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: AppUI.tightPadding) {
                    if isOrdered {
                        Text("\(index + 1).")
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundStyle(.appAccent)
                            .frame(width: 24, alignment: .trailing)
                    } else {
                        Text("•")
                            .foregroundStyle(.appAccent)
                            .frame(width: AppUI.iconSmall)
                    }
                    
                    renderInlineContent(item)
                        .foregroundStyle(.appText)
                    Spacer(minLength: 0)
                }
                .padding(.leading, isOrdered ? 0 : CGFloat(indent) * AppUI.standardPadding)
            }
        }
        .padding(.vertical, AppUI.atomic)
    }

    // MARK: - Render Blockquote
    @ViewBuilder
    private func renderBlockquote(text: String) -> some View {
        let isAISummary = text.contains("AI") || text.hasPrefix("> AI")
        
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: AppUI.tiny)
                .fill(isAISummary ? Color.appAccent : Color.appAccent.opacity(AppUI.disabledOpacity))
                .frame(width: AppUI.atomic + AppUI.borderWidth)
                .padding(.trailing, AppUI.mediumRadius)

            renderInlineContent(text)
                .font(isAISummary ? .system(.body, design: .serif).italic() : .body.italic())
                .foregroundStyle(isAISummary ? .appAccent : .appSecondary)
                .lineSpacing(isAISummary ? AppUI.small : AppUI.tiny * 1.5) // AI 总结采用更宽松的行间距提升阅读舒适度

            Spacer(minLength: 0)
        }
        .padding(isAISummary ? AppUI.medium : 0)
        .background(isAISummary ? Color.appAccent.opacity(AppUI.glassOpacity / 3) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: isAISummary ? AppUI.smallRadius : 0))
        .padding(.vertical, AppUI.tiny)
    }

    // MARK: - Render Code Block
    @ViewBuilder
    private func renderCodeBlock(code: String, language: String) -> some View {
        if language.lowercased() == "mermaid" {
            MermaidWebView(mermaidCode: code)
                .padding(.vertical, AppUI.tightPadding)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                if !language.isEmpty {
                    Text(language)
                        .font(.system(.caption2, design: .monospaced).weight(.medium))
                        .foregroundStyle(.appSecondary)
                        .padding(.horizontal, AppUI.medium)
                        .padding(.top, AppUI.tightPadding)
                }

                ScrollView(.horizontal, showsIndicators: true) {
                    Text(code)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.appText.opacity(AppUI.fullOpacity - AppUI.glassOpacity))
                        .padding(AppUI.medium)
                }
            }
            .background(Color.appCard.opacity(AppUI.fullOpacity - AppUI.glassOpacity * 1.5))
            .clipShape(RoundedRectangle(cornerRadius: AppUI.smallRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppUI.smallRadius)
                    .stroke(Color.appBorder.opacity(AppUI.disabledOpacity), lineWidth: AppUI.borderWidth)
            )
            .padding(.vertical, AppUI.tiny)
        }
    }

    // MARK: - Render Table
    @ViewBuilder
    private func renderTable(headers: [String], rows: [[String]]) -> some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(Array(headers.enumerated()), id: \.offset) { _, cell in
                        renderInlineContent(cell)
                            .font(.system(.subheadline).weight(.semibold))
                            .foregroundStyle(.appText)
                            .frame(minWidth: 100, alignment: .leading) // 最小宽度保证列内容不被过度压缩
                            .padding(.horizontal, AppUI.tightPadding)
                            .padding(.vertical, AppUI.tightPadding)
                    }
                }
                .background(Color.appAccent.opacity(AppUI.glassOpacity / 1.5))

                ForEach(Array(rows.enumerated()), id: \.offset) { rowIdx, row in
                    HStack(spacing: 0) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                            renderInlineContent(cell)
                                .font(.system(.subheadline))
                                .foregroundStyle(.appText)
                                .frame(minWidth: 100, alignment: .leading)
                                .padding(.horizontal, AppUI.tightPadding)
                                .padding(.vertical, AppUI.small - AppUI.atomic)
                        }
                    }
                    .background(rowIdx % 2 == 0 ? Color.clear : Color.appCard.opacity(AppUI.disabledOpacity))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: AppUI.smallRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppUI.smallRadius)
                    .stroke(Color.appBorder.opacity(AppUI.disabledOpacity), lineWidth: AppUI.borderWidth)
            )
        }
        .padding(.vertical, AppUI.tiny)
    }

    // MARK: - Render Horizontal Rule
    @ViewBuilder
    private func renderHorizontalRule() -> some View {
        Divider()
            .background(Color.appBorder)
            .padding(.vertical, AppUI.tightPadding)
    }

    // MARK: - Render Task List
    @ViewBuilder
    private func renderTaskList(items: [(text: String, checked: Bool)]) -> some View {
        VStack(alignment: .leading, spacing: AppUI.tiny + AppUI.atomic) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: AppUI.tightPadding) {
                    Image(systemName: item.checked ? "checkmark.square.fill" : "square")
                        .font(.body)
                        .foregroundStyle(item.checked ? .green : .appSecondary)
                    renderInlineContent(item.text)
                        .foregroundStyle(item.checked ? .appSecondary : .appText)
                        .strikethrough(item.checked)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.vertical, AppUI.atomic)
    }

    // MARK: - Inline Content Renderer
    @ViewBuilder
    private func renderInlineContent(_ text: String) -> some View {
        let segments = parser.parseInlineSegments(text)
        
        Text(buildAttributedString(from: segments))
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.openURL, OpenURLAction { url in
                if url.scheme == "applink" {
                    let title = url.absoluteString
                        .replacingOccurrences(of: "applink://", with: "")
                        .removingPercentEncoding ?? ""
                    
                    if !title.isEmpty {
                        if title.contains("|") {
                            let actualTitle = title.split(separator: "|").last.map(String.init) ?? title
                            onLinkTap(actualTitle)
                        } else {
                            onLinkTap(title)
                        }
                    }
                    return .handled
                }
                return .systemAction
            })
    }
    
    private func buildAttributedString(from segments: [MarkdownProcessor.InlineSegment]) -> AttributedString {
        var result = AttributedString()
        
        for segment in segments {
            var container = AttributedString(segment.content)
            
            switch segment.type {
            case .text:
                container.swiftUI.font = isCompact ? Font.footnote : Font.body
            case .bold:
                container.swiftUI.font = (isCompact ? Font.footnote : Font.body).weight(.bold)
            case .italic:
                container.swiftUI.font = (isCompact ? Font.footnote : Font.body).italic()
            case .code:
                container.swiftUI.font = .system(.caption, design: .monospaced)
                container.swiftUI.backgroundColor = Color.appAccent.opacity(AppUI.glassOpacity)
                container.swiftUI.foregroundColor = .appText
                case .applink:
                    container.swiftUI.font = (isCompact ? Font.footnote : Font.body).weight(.medium)
                    container.swiftUI.foregroundColor = Color.appAccent
                    container.swiftUI.underlineStyle = .single
                    
                    if segment.content.contains("|") {
                        let parts = segment.content.split(separator: "|")
                        let label = String(parts.first ?? "")
                        let title = String(parts.last ?? "")
                        container = AttributedString(label)
                        container.swiftUI.font = (isCompact ? Font.footnote : Font.body).weight(.medium)
                        container.swiftUI.foregroundColor = Color.appAccent
                        container.swiftUI.underlineStyle = .single
                        if let encoded = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                            container.foundation.link = URL(string: "applink://\(encoded)")
                        }
                    } else {
                        if let encoded = segment.content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                            container.foundation.link = URL(string: "applink://\(encoded)")
                        }
                    }
            case .link:
                let parts = segment.content.split(separator: "|")
                let label = String(parts.first ?? "")
                let urlString = String(parts.last ?? "")
                container = AttributedString(label)
                container.swiftUI.font = isCompact ? Font.footnote : Font.body
                container.swiftUI.foregroundColor = Color.appAccent
                container.swiftUI.underlineStyle = .single
                if let url = URL(string: urlString) {
                    container.foundation.link = url
                }
            case .emoji:
                container.swiftUI.font = .body
            }
            
            result.append(container)
        }
        
        return result
    }
    
    // MARK: - Skeleton View
    @ViewBuilder
    private func renderSkeleton() -> some View {
        VStack(alignment: .leading, spacing: AppUI.standardPadding) {
            RoundedRectangle(cornerRadius: AppUI.microRadius)
                .fill(Color.appCard)
                .frame(width: AppUI.Gallery.callToActionWidth + AppUI.huge, height: AppUI.Action.largeIconSize)
            
            VStack(alignment: .leading, spacing: AppUI.tightPadding) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: AppUI.microRadius)
                        .fill(Color.appCard.opacity(AppUI.disabledOpacity * 2))
                        .frame(height: AppUI.captionFontSize + AppUI.atomic)
                        .frame(maxWidth: .infinity)
                }
            }
            
            RoundedRectangle(cornerRadius: AppUI.microRadius)
                .fill(Color.appCard.opacity(AppUI.disabledOpacity))
                .frame(width: AppUI.Gallery.callToActionWidth - AppUI.tightPadding, height: AppUI.subheadlineFontSize + AppUI.atomic * 2)
        }
        .padding(.vertical, AppUI.tightPadding)
        .opacity(AppUI.disabledOpacity * 2)
    }
}
