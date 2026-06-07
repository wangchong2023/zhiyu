//
//  MarkdownProcessor.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：Markdown 解析门面。
//           块级解析委托给 Apple swift-markdown（通过 MarkdownBlockAdapter 映射为内部 BlockType），
//           行内解析委托给 AppLinkInlineParser（自研两阶段算法以保护 `[[双链]]` 不被正则破坏）。
//
import Foundation

// MARK: - Markdown 解析门面

/// Markdown 内容解析的统一入口。
/// 该门面将块级解析委托给基于 swift-markdown 的 `MarkdownBlockAdapter`，
/// 行内富文本解析委托给自研的 `AppLinkInlineParser`，
/// 保持对外 API 完全向后兼容。
final class MarkdownProcessor: Sendable {

    // MARK: - 块类型

    /// 代表 Markdown 结构化文档中的高级排版物理块 (BlockType)。
    enum BlockType {
        /// 标题块，层级 1 至 6 分别对应 # 至 ######。
        case heading(text: String, level: Int)
        /// 普通段落文本块。
        case paragraph(text: String)
        /// 无序或有序列表块（indent 为 -1 时表示有序列表）。
        case bulletList(items: [String], indent: Int)
        /// 引用块（以 `>` 引导）。
        case blockquote(text: String)
        /// 代码块（以 ``` 引导与收尾）。
        case codeBlock(code: String, language: String)
        /// 标准 Markdown 表格块。
        case table(headers: [String], rows: [[String]])
        /// 水平分割线（如 `---` 或 `***`）。
        case horizontalRule
        /// 带有复选框的任务列表块。
        case taskList(items: [(text: String, checked: Bool)])
        /// HTML 折叠细节块（`<details>` 标签）。
        case details(summary: String, content: String)
    }

    // MARK: - 内部适配器

    /// swift-markdown 块适配器，负责将 Apple 官方解析器的 Markup AST 转换为 BlockType 数组。
    private let blockAdapter = MarkdownBlockAdapter()

    /// 自研行内解析器，基于两阶段算法保护智宇双链 `[[...]]` 不被正则匹配破坏。
    private let inlineParser = AppLinkInlineParser()

    // MARK: - 解析接口

    /// 解析整段 Markdown 文本为结构化块数组。
    /// 块级解析委托给 swift-markdown（通过 MarkdownBlockAdapter），保留对 `<details>` 自定义块的后处理支持。
    func parse(_ content: String) -> [BlockType] {
        return blockAdapter.convert(content: content)
    }

    /// 解析单行文本中的行内富文本样式。
    /// 委托给自研 `AppLinkInlineParser`，以两阶段算法保护 `[[双链]]` 同时提取标准 Markdown 格式。
    func parseInlineSegments(_ text: String) -> [AppLinkInlineParser.InlineSegment] {
        return inlineParser.parseInlineSegments(text)
    }
}
