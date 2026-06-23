//
//  SynthesisMindmapView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：渲染思维导图与信息图表合成输出，提取 Markdown 标题与 Mermaid 代码块。
//

import SwiftUI

// MARK: - 思维导图内容视图

/// 渲染思维导图 / 信息图类型的合成文档内容
/// 从文档 Markdown 内容中提取标题与 Mermaid 代码，驱动 MermaidWebView 进行可视化渲染
struct SynthesisMindmapView: View {
    let doc: SynthesisStore.SynthesisDocument

    var body: some View {
        VStack(spacing: DesignSystem.standardPadding) {
            if let title = extractTitle(from: doc.content) {
                Text(title)
                    .font(.title2.bold())
                    .padding(.top, DesignSystem.widePadding)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            MermaidWebView(mermaidCode: extractMermaidCode(from: doc.content))
                .id(doc.id)
        }
    }

    // MARK: - 辅助解析

    /// 从 Markdown 内容中提取一级标题（# 开头行）
    /// - Parameter content: Markdown 原始文本
    /// - Returns: 去除前缀后的标题，若不存在则返回 nil
    private func extractTitle(from content: String) -> String? {
        let lines = content.components(separatedBy: .newlines)
        if let firstLine = lines.map({ $0.trimmingCharacters(in: .whitespaces) }).first(where: { !$0.isEmpty }),
           firstLine.hasPrefix("# ") {
            return firstLine.replacingOccurrences(of: "# ", with: "")
        }
        return nil
    }

    /// 从 Markdown 内容中提取 Mermaid 代码块
    /// 优先匹配 ```mermaid … ``` 围栏代码块，若不存在则回退到排除标题行的纯文本行
    /// - Parameter content: Markdown 原始文本
    /// - Returns: Mermaid 语法代码
    private func extractMermaidCode(from content: String) -> String {
        if let regex = try? NSRegularExpression(pattern: "```(?:mermaid)?\\n([\\s\\S]*?)```", options: []),
           let match = regex.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)),
           let range = Range(match.range(at: 1), in: content) {
            return String(content[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let lines = content.components(separatedBy: .newlines)
        return lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return !trimmed.hasPrefix("#") && !trimmed.hasPrefix("```") && !trimmed.isEmpty
        }
        .joined(separator: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
