//
//  SynthesisProcessor.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：属于 Synthesis 模块，提供相关的结构体或工具支撑。
//
import Foundation

/// 针对知识合成（思维导图、演示文稿、知识测验、深度报告、信息图）的通用处理工具
enum SynthesisProcessor {

    /// 格式化 Mermaid 代码块
    /// - Parameters:
    ///   - text: 包含 Mermaid 代码的原始文本
    ///   - fallbackPrefix: 当无法自动识别图表类型时的默认前缀
    /// - Returns: 标准化的 Mermaid 代码块
    static func formatMermaid(_ text: String, fallbackPrefix: String) -> String {
        var cleaned = text.replacingOccurrences(of: "```mermaid", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. 提取标题 (如果有 # 标题)
        var title: String?
        if cleaned.hasPrefix("# ") {
            if let firstLineEnd = cleaned.firstIndex(of: "\n") {
                title = String(cleaned[..<firstLineEnd])
                cleaned = String(cleaned[cleaned.index(after: firstLineEnd)...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // 2. 尝试提取核心代码块 (更加灵活的正则，支持不带方向的 graph)
        let patterns = ["mindmap.*", "graph.*", "pie.*", "timeline.*", "sequenceDiagram.*", "gantt.*"]
        var mermaidCode: String = cleaned
        var foundMatch = false

        for pattern in patterns {
            if let range = cleaned.range(of: "(?s)\(pattern)", options: .regularExpression) {
                mermaidCode = String(cleaned[range])
                foundMatch = true
                break
            }
        }

        // 3. 增强：确保关键字与根节点之间有换行，防止 "mindmap root" 这种在一行导致的解析错误
        if foundMatch {
            for keyword in ["mindmap", ["graph", "TD"].joined(separator: " "), ["graph", "LR"].joined(separator: " "), ["graph", "TB"].joined(separator: " "), ["graph", "BT"].joined(separator: " "), "graph", "timeline", "gantt", "pie", "sequenceDiagram"] {
                if mermaidCode.hasPrefix(keyword) {
                    let afterKeyword = mermaidCode.dropFirst(keyword.count)
                    if !afterKeyword.isEmpty && !afterKeyword.hasPrefix("\n") {
                        mermaidCode = keyword + "\n  " + afterKeyword.trimmingCharacters(in: .whitespaces)
                    }
                    break
                }
            }
        }

        // 4. 如果完全没有匹配且不包含关键字，则尝试加上前缀
        if !foundMatch {
            mermaidCode = "\(fallbackPrefix)\n  " + mermaidCode.replacingOccurrences(of: "\n", with: "\n  ")
        } else if mermaidCode.trimmingCharacters(in: .whitespaces) == "graph" {
            mermaidCode = ["graph", "TD"].joined(separator: " ")
        }

        // 对最终确定的 Mermaid 代码进行语法纠错加固
        mermaidCode = sanitizeMermaidSyntax(mermaidCode)

        if let title = title {
            return "\(title)\n\n\(mermaidCode)"
        } else {
            return mermaidCode
        }
    }

    /// 对 Mermaid 进行语法纠错加固 (处理节点文本中的非法字符)
    private static func sanitizeMermaidSyntax(_ code: String) -> String {
        let isMindmap = code.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("mindmap")
        var lines = code.components(separatedBy: .newlines)

        for i in 0..<lines.count {
            var line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed == "mindmap" { continue }

            // 获取缩进
            let indentation = line.prefix { $0.isWhitespace }

            if isMindmap {
                // 针对 mindmap 的特殊处理：
                // 1. 移除行尾可能导致解析错误的连字符
                var content = trimmed.replacingOccurrences(of: #"-+$"#, with: "", options: .regularExpression)

                // 2. 如果包含特殊字符且没带括号，套上引号
                let hasBrackets = (content.contains("((") && content.contains("))")) ||
                                  (content.contains("[") && content.contains("]")) ||
                                  (content.contains("{{") && content.contains("}}")) ||
                                  (content.contains("(") && content.contains(")"))

                if !hasBrackets && !content.hasPrefix("\"") {
                    // 清理内容中的非法引号
                    let safeText = content.replacingOccurrences(of: "\"", with: "'")
                                          .replacingOccurrences(of: ":", with: ":")
                    content = "\"\(safeText)\""
                } else if hasBrackets {
                    // 如果有括号，确保括号内的内容也是安全的
                    content = content.replacingOccurrences(of: ":", with: ":")
                }

                line = String(indentation) + content
            } else {
                // 针对 graph 等其他图表的通用处理
                // 1. 处理节点定义 ID[Label] -> ID["Label"]
                let pattern = #"(\w+)(\[+|\(+|\{+)(.+?)(\]+|\)+|\}+)"#
                if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                    let range = NSRange(location: 0, length: line.utf16.count)
                    line = regex.stringByReplacingMatches(in: line, options: [], range: range, withTemplate: #"$1["$3"]"#)
                }

                // 2. 标签内容净化
                if let start = line.firstIndex(of: "["), let end = line.lastIndex(of: "]") {
                    let range = line.index(after: start)..<end
                    let inner = line[range]
                    var innerText = String(inner)
                    if innerText.hasPrefix("\"") && innerText.hasSuffix("\"") {
                        innerText = String(innerText.dropFirst().dropLast())
                    }

                    let cleaned = innerText.replacingOccurrences(of: "(", with: "(")
                                           .replacingOccurrences(of: ")", with: ")")
                                           .replacingOccurrences(of: "\"", with: "'")
                                           .trimmingCharacters(in: .whitespaces)
                    line.replaceSubrange(range, with: "\"\(cleaned)\"")
                }
            }

            lines[i] = line
        }
        return lines.joined(separator: "\n")
    }

    /// 从文本内容中提取第一个 H1 级别的标题
    static func extractTitle(from content: String) -> String? {
        let lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        // 寻找第一个非空的 Markdown 标题行
        if let firstLine = lines.first(where: { !$0.isEmpty && $0.hasPrefix("# ") }) {
            return firstLine.replacingOccurrences(of: #"^#+\s*"#, with: "", options: .regularExpression)
                            .replacingOccurrences(of: "```", with: "")
                            .trimmingCharacters(in: .whitespaces)
        }

        return nil
    }

    /// 清理 Markdown 内容中的冗余转义（如 \+ -> +）
    static func cleanMarkdown(_ text: String) -> String {
        var cleaned = text
        // 移除常见的冗余转义字符，LLM 经常在列表中或 Knowledge links 中转义这些字符
        let replacements = [
            "\\+": "+",
            "\\-": "-",
            "\\*": "*",
            "\\. ": ". ",
            "\\!": "!",
            "\\[\\[": "[[",
            "\\]\\]": "]]",
            "\\\\[": "[",
            "\\\\]": "]"
        ]

        for (target, replacement) in replacements {
            cleaned = cleaned.replacingOccurrences(of: target, with: replacement)
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
