//
//  MarkdownBlockAdapter.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/07.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：将 swift-markdown 解析产生的 Markup 树映射为 ZhiYu 内部的 BlockType 枚举，
//           替代原自研 Markdown 块解析器，利用 Apple 官方解析器提升标准兼容性。
//
import Foundation
import Markdown

// MARK: - swift-markdown 块适配器

/// 将 swift-markdown 解析的 Markup AST 递归转换为 ZhiYu 内部 `MarkdownProcessor.BlockType` 数组。
/// 该适配器消除自研块解析器的维护负担，仅保留 swift-markdown 不支持的 `<details>` 折叠块后处理。
struct MarkdownBlockAdapter: Sendable {

    /// 解析原始 Markdown 字符串并转换为 BlockType 数组。
    /// - Parameter content: 原始 Markdown 文本。
    /// - Returns: 扁平化后的 BlockType 物理块数组。
    func convert(content: String) -> [MarkdownProcessor.BlockType] {
        // 预处理：提取 swift-markdown 不支持的 `<details>` 折叠块
        // swift-markdown 遇到空白行会打断 HTML 块，导致 `<details>` 内容被拆散
        let (strippedContent, detailsBlocks) = extractDetailsBlocks(from: content)

        let document = Document(parsing: strippedContent)
        var blocks = convertChildren(of: document)

        // 后处理：将 `<details>` 块插回原位（按占位符标记位置）
        blocks = restoreDetailsBlocks(detailsBlocks, into: blocks)

        return blocks
    }

    /// 将 swift-markdown 的 Document 根节点转换为 BlockType 数组。

    // MARK: - 递归子节点转换

    /// 递归遍历 Markup 节点的直接子元素，转换为 BlockType 数组。
    private func convertChildren(of parent: some Markup) -> [MarkdownProcessor.BlockType] {
        var blocks: [MarkdownProcessor.BlockType] = []

        for child in parent.children {
            switch child {
            case let heading as Heading:
                blocks.append(convertHeading(heading))

            case let paragraph as Paragraph:
                let text = plainText(from: paragraph)
                // 检测 <details> 自定义折叠块（swift-markdown 不支持，需自研后处理）
                if let detailsBlock = tryParseDetailsBlock(text) {
                    blocks.append(detailsBlock)
                } else if !text.isEmpty {
                    blocks.append(.paragraph(text: text))
                }

            case let codeBlock as CodeBlock:
                blocks.append(.codeBlock(
                    code: codeBlock.code,
                    language: codeBlock.language ?? ""
                ))

            case let list as UnorderedList:
                // 检测是否为任务列表（列表项带有复选框）
                if list.hasCheckboxItems {
                    blocks.append(convertTaskList(list))
                } else {
                    blocks.append(convertUnorderedList(list))
                }

            case let list as OrderedList:
                blocks.append(convertOrderedList(list))

            case let table as Markdown.Table:
                blocks.append(convertTable(table))

            case is ThematicBreak:
                blocks.append(.horizontalRule)

            case let blockquote as BlockQuote:
                blocks.append(convertBlockquote(blockquote))

            case let htmlBlock as HTMLBlock:
                // swift-markdown 将 <details> 解析为 HTMLBlock，尝试提取内容
                if let detailsBlock = tryParseDetailsBlock(htmlBlock.rawHTML) {
                    blocks.append(detailsBlock)
                }

            default:
                // 忽略未知或不支持的块类型
                break
            }
        }

        return blocks
    }

    // MARK: - 块类型转换

    /// 转换标题。提取标题文字与层级。
    private func convertHeading(_ heading: Heading) -> MarkdownProcessor.BlockType {
        let text = plainText(from: heading)
        let level = min(max(heading.level, 1), 6)
        return .heading(text: text, level: level)
    }

    /// 转换无序列表。提取各列表项文字及缩进级别。
    private func convertUnorderedList(_ list: UnorderedList) -> MarkdownProcessor.BlockType {
        var items: [String] = []
        for item in list.listItems {
            let text = plainText(from: item)
            if !text.isEmpty {
                items.append(text)
            }
        }
        return .bulletList(items: items, indent: 0)
    }

    /// 转换有序列表。缩进级别统一约定为 -1 以标识有序特性。
    private func convertOrderedList(_ list: OrderedList) -> MarkdownProcessor.BlockType {
        var items: [String] = []
        for item in list.listItems {
            let text = plainText(from: item)
            if !text.isEmpty {
                items.append(text)
            }
        }
        return .bulletList(items: items, indent: -1)
    }

    /// 转换 Markdown 表格。提取表头和数据行。
    private func convertTable(_ table: Markdown.Table) -> MarkdownProcessor.BlockType {
        var headers: [String] = []
        var rows: [[String]] = []

        // 提取表头
        for cell in table.head.cells {
            headers.append(plainText(from: cell))
        }

        // 提取数据行
        for row in table.body.rows {
            var rowCells: [String] = []
            for cell in row.cells {
                rowCells.append(plainText(from: cell))
            }
            rows.append(rowCells)
        }

        return .table(headers: headers, rows: rows)
    }

    /// 转换任务列表。提取各任务项文字与勾选状态。
    private func convertTaskList(_ list: UnorderedList) -> MarkdownProcessor.BlockType {
        var items: [(text: String, checked: Bool)] = []
        for item in list.listItems {
            let text = plainText(from: item)
            if !text.isEmpty {
                let checked = item.checkbox == .checked
                items.append((text: text, checked: checked))
            }
        }
        return .taskList(items: items)
    }

    /// 转换引用块。递归提取引用块内所有嵌套文本。
    private func convertBlockquote(_ blockquote: BlockQuote) -> MarkdownProcessor.BlockType {
        // swift-markdown 的 BlockQuote 可能嵌套多层，
        // 递归提取所有内联文字并合并为单行文本
        let text = blockquote.children
            .map { plainText(from: $0) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        return .blockquote(text: text)
    }

    // MARK: - 纯文本提取

    /// 递归提取 Markup 节点的纯文本内容，剔除所有格式标记。
    /// - Parameter markup: swift-markdown 的 Markup 节点（Paragraph、Heading 等）。
    /// - Returns: 合并后的纯文本字符串。
    private func plainText(from markup: some Markup) -> String {
        var result = ""
        for child in markup.children {
            switch child {
            case let text as Markdown.Text:
                result += text.string
            case let softBreak as SoftBreak:
                result += " "
            case let lineBreak as LineBreak:
                result += "\n"
            case let inlineCode as InlineCode:
                result += inlineCode.code
            case let link as Markdown.Link:
                result += link.plainText
            case let emphasis as Emphasis:
                result += plainText(from: emphasis)
            case let strong as Strong:
                result += plainText(from: strong)
            case let strikethrough as Strikethrough:
                result += plainText(from: strikethrough)
            case let image as Markdown.Image:
                if let title = image.title {
                    result += title
                } else {
                    result += image.plainText
                }
            default:
                // 对未知节点尝试递归提取
                if let markupChild = child as? (any Markup) {
                    result += plainText(from: markupChild)
                }
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - <details> 折叠块后处理

    /// 尝试从 HTML 或段落文本中解析 `<details>` 折叠块。
    /// swift-markdown 将 `<details>` 解析为 HTMLBlock 或将其内容放入 Paragraph，
    /// 此方法兼容两种场景。
    /// - Parameter text: 潜在包含 `<details>` 标签的原始文本。
    /// - Returns: 若匹配成功，返回 `.details` 块；否则返回 `nil`。
    private func tryParseDetailsBlock(_ text: String) -> MarkdownProcessor.BlockType? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("<details>") else { return nil }

        var summary = "Details"
        var contentLines: [String] = []
        var inSummary = false
        var summaryText = ""

        let lines = trimmed.components(separatedBy: "\n")
        for line in lines {
            let stripped = line.trimmingCharacters(in: .whitespaces)

            if stripped.hasPrefix("</details>") {
                break
            }

            if stripped.hasPrefix("<summary>") && stripped.contains("</summary>") {
                summary = stripped
                    .replacingOccurrences(of: "<summary>", with: "")
                    .replacingOccurrences(of: "</summary>", with: "")
                    .trimmingCharacters(in: .whitespaces)
                continue
            } else if stripped.hasPrefix("<summary>") {
                inSummary = true
                summaryText = stripped.replacingOccurrences(of: "<summary>", with: "")
                continue
            } else if inSummary && stripped.contains("</summary>") {
                inSummary = false
                summaryText += " " + stripped.replacingOccurrences(of: "</summary>", with: "")
                summary = summaryText.trimmingCharacters(in: .whitespaces)
                continue
            } else if inSummary {
                summaryText += " " + stripped
                continue
            } else if stripped.hasPrefix("<details>") {
                continue
            }

            contentLines.append(line)
        }

        if summary.isEmpty { summary = "Details" }
        return .details(summary: summary, content: contentLines.joined(separator: "\n"))
    }

    // MARK: - <details> 预处理

    /// 详情块占位符前缀标记（使用纯文本前缀避免被 swift-markdown 解析为 HTML 注释块）。
    private static let detailsPlaceholderPrefix = "ZHIYU_DETAILS_BLOCK_"

    /// 从原始 Markdown 文本中提取所有 `<details>...</details>` 块并替换为占位符段落。
    /// 使用逐行扫描替代正则，避免 UTF-16 范围计算与多语言字符的兼容问题。
    /// - Parameter content: 原始 Markdown 文本。
    /// - Returns: (去除 details 块后的文本, 提取到的详情块数组)。
    private func extractDetailsBlocks(from content: String) -> (String, [MarkdownProcessor.BlockType]) {
        var blocks: [MarkdownProcessor.BlockType] = []
        let lines = content.components(separatedBy: "\n")
        var resultLines: [String] = []
        var index = 0
        var i = 0

        while i < lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("<details>") {
                // 收集完整的 <details>...</details> 块
                var detailsLines: [String] = []
                detailsLines.append(lines[i])
                i += 1
                while i < lines.count {
                    detailsLines.append(lines[i])
                    if lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("</details>") {
                        i += 1
                        break
                    }
                    i += 1
                }

                let rawHTML = detailsLines.joined(separator: "\n")
                if let detailsBlock = tryParseDetailsBlock(rawHTML) {
                    let placeholder = "\(Self.detailsPlaceholderPrefix)\(index)"
                    resultLines.append(placeholder)
                    blocks.append(detailsBlock)
                    index += 1
                } else {
                    resultLines.append(contentsOf: detailsLines)
                }
            } else {
                resultLines.append(lines[i])
                i += 1
            }
        }

        return (resultLines.joined(separator: "\n"), blocks)
    }

    /// 将占位符替换回实际的 `.details` BlockType。
    private func restoreDetailsBlocks(
        _ detailsBlocks: [MarkdownProcessor.BlockType],
        into blocks: [MarkdownProcessor.BlockType]
    ) -> [MarkdownProcessor.BlockType] {
        var result: [MarkdownProcessor.BlockType] = []
        var detailIndex = 0

        for block in blocks {
            if case .paragraph(let text) = block,
               text.trimmingCharacters(in: .whitespaces).hasPrefix(Self.detailsPlaceholderPrefix) {
                if detailIndex < detailsBlocks.count {
                    result.append(detailsBlocks[detailIndex])
                    detailIndex += 1
                }
            } else {
                result.append(block)
            }
        }

        return result
    }
}

// MARK: - UnorderedList 扩展

private extension UnorderedList {
    /// 判断无序列表是否为任务列表（至少包含一个带复选框的项）。
    var hasCheckboxItems: Bool {
        return listItems.contains { $0.checkbox != nil }
    }
}
