//
//  AIContentEnricher.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：属于 RAG 模块，提供相关的结构体或工具支撑。
//
import Foundation

/// AI 内容增强处理器
/// 负责在 RAG 流程中对原始内容进行语义丰富化。
/// 通过将文档拆分为逻辑块（文本、表格、图片），利用并行任务进行针对性的语义提取。
actor AIContentEnricher {

    static let shared = AIContentEnricher()

    private init() {}

    /// 内容块类型
    private enum ContentBlock {
        case text(String)
        case table(String)
        case image(url: String, alt: String?)
    }

    /// 对 Markdown 中的富媒体或结构化内容进行语义增强
    /// - Parameters:
    ///   - content: 原始 Markdown 文本
    ///   - llm: 调用的 LLM 服务
    /// - Returns: 增强后的文本
    func enrich(_ content: String, llm: any LLMServiceProtocol) async -> String {
        // 1. 快速判断是否需要增强
        let needsEnrichment = content.contains("| --- |") || content.contains("![]") || content.contains("![")
        guard needsEnrichment else { return content }

        // 2. 将内容拆分为逻辑块
        let blocks = parseBlocks(from: content)

        // 3. 并行处理需要增强的块
        return await withTaskGroup(of: (Int, String).self) { group in
            for (index, block) in blocks.enumerated() {
                group.addTask {
                    switch block {
                    case .text(let text):
                        return (index, text)
                    case .table(let tableContent):
                        let enriched = await self.enrichTable(tableContent, llm: llm)
                        return (index, enriched)
                    case .image(let url, let alt):
                        let enriched = await self.enrichImage(url: url, alt: alt, llm: llm)
                        return (index, enriched)
                    }
                }
            }

            var results = [(Int, String)]()
            for await result in group {
                results.append(result)
            }

            // 按原始索引排序并合并
            return results.sorted { $0.0 < $1.0 }
                .map { $0.1 }
                .joined(separator: "\n\n")
        }
    }

    // MARK: - 内部处理逻辑

    /// 解析 Markdown 块
    private func parseBlocks(from content: String) -> [ContentBlock] {
        var blocks: [ContentBlock] = []
        let lines = content.components(separatedBy: .newlines)
        var currentText = ""
        var isInsideTable = false
        var currentTable = ""

        for line in lines {
            // 简单的表格识别：以 | 开头且包含分割线
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("|") {
                if !isInsideTable {
                    if !currentText.isEmpty {
                        blocks.append(.text(currentText.trimmingCharacters(in: .whitespacesAndNewlines)))
                        currentText = ""
                    }
                    isInsideTable = true
                }
                currentTable += line + "\n"
            } else if isInsideTable {
                // 表格结束
                blocks.append(.table(currentTable.trimmingCharacters(in: .whitespacesAndNewlines)))
                currentTable = ""
                isInsideTable = false
                currentText += line + "\n"
            } else if line.contains("![") && line.contains("](") {
                // 图片识别 (Markdown 格式: ![alt](url))
                if !currentText.isEmpty {
                    blocks.append(.text(currentText.trimmingCharacters(in: .whitespacesAndNewlines)))
                    currentText = ""
                }

                // 提取图片信息
                if let block = parseImageBlock(from: line) {
                    blocks.append(block)
                } else {
                    currentText += line + "\n"
                }
            } else {
                currentText += line + "\n"
            }
        }

        // 处理最后一段
        if isInsideTable {
            blocks.append(.table(currentTable.trimmingCharacters(in: .whitespacesAndNewlines)))
        } else if !currentText.isEmpty {
            blocks.append(.text(currentText.trimmingCharacters(in: .whitespacesAndNewlines)))
        }

        return blocks
    }

    private func parseImageBlock(from line: String) -> ContentBlock? {
        // 使用正则提取 ![alt](url)
        let pattern = "!\\[(.*?)\\]\\((.*?)\\)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }

        let altRange = Range(match.range(at: 1), in: line)!
        let urlRange = Range(match.range(at: 2), in: line)!

        return .image(url: String(line[urlRange]), alt: String(line[altRange]))
    }

    /// 增强表格语义
    private func enrichTable(_ table: String, llm: any LLMServiceProtocol) async -> String {
        let systemPrompt = "你是一个专业的数据分析师。请分析 Markdown 表格并提供数据洞察。"
        let prompt = """
        分析以下表格内容，提取 3 个核心结论或趋势。
        要求：
        1. 语气简洁专业。
        2. 识别数据中的异常值或显著特征。
        3. 直接返回结论列表，以 "> [数据洞察]:" 开头。

        表格内容：
        \(table)
        """

        do {
            let insight = try await llm.generate(prompt: prompt, systemPrompt: systemPrompt)
            return table + "\n\n" + insight
        } catch {
            return table
        }
    }

    /// 增强图片语义 (基于上下文或元数据)
    private func enrichImage(url: String, alt: String?, llm: any LLMServiceProtocol) async -> String {
        let imageMarkdown = "![\(alt ?? "")](\(url))"
        guard let alt = alt, !alt.isEmpty else { return imageMarkdown }

        let systemPrompt = "你是一个视觉理解专家。请根据图片标题推测其在文档中的语义作用。"
        let prompt = """
        图片描述 (Alt Text): "\(alt)"
        图片链接: "\(url)"

        请基于以上信息，生成一段 50 字以内的图片语义说明。
        要求：
        1. 解释该图片可能展示的核心内容。
        2. 说明它对读者的认知价值。
        3. 以 "> [图片语义]:" 开头返回。
        """

        do {
            let description = try await llm.generate(prompt: prompt, systemPrompt: systemPrompt)
            return imageMarkdown + "\n\n" + description
        } catch {
            return imageMarkdown
        }
    }
}
