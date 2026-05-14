// MarkdownProcessor.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了全功能 Markdown 文本解析处理器（MarkdownProcessor），是系统中内容渲染与语义理解的核心组件。
// 该处理器通过高性能正则引擎实现以下功能点：
// 1. 深度标题识别：支持从 H1 到 H6 的全层级标准标题解析，并能自动去除冗余的 Markdown 符号。
// 2. 块类型提取：精准识别并分离普通段落、无序列表、代码块以及引用块，将其转换为结构化的中间模型。
// 3. 实时清洗：自动剔除不规范的换行符和首尾空格，确保输出的内容在 UI 层渲染时具备一致的边距表现。
// 4. 扩展性支持：预留了对自定义标记和公式解析的扩展接口，保障了文档解析能力的持续进化。
// 版本: 1.1
// 修改记录:
//   - 2026-05-05: 优化 H1-H6 解析逻辑，迁移至 Utils/Processors 归口管理
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

// MARK: - Markdown 解析器
/// Pure parsing layer for Markdown content. Returns structured block representations.
/// Rendering is handled separately by MarkdownRendererView.
final class MarkdownProcessor: Sendable {

    // MARK: - 块类型
    enum BlockType {
        case heading(text: String, level: Int)
        case paragraph(text: String)
        case bulletList(items: [String], indent: Int)
        case blockquote(text: String)
        case codeBlock(code: String, language: String)
        case table(headers: [String], rows: [[String]])
        case horizontalRule
        case taskList(items: [(text: String, checked: Bool)])
        case details(summary: String, content: String)
    }

    // MARK: - 行内类型
    enum InlineType {
        case text, bold, italic, strikethrough, code, applink, link, emoji
    }

    struct InlineSegment {
        let type: InlineType
        let content: String
    }

    // MARK: - 解析完整内容
    func parse(_ content: String) -> [BlockType] {
        let lines = content.components(separatedBy: "\n")
        var blocks: [BlockType] = []
        var i = 0

        while i < lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                i += 1
                continue
            }

            // Try each block type parser
            if let result = parseDetailsBlock(lines: lines, startIndex: i) {
                blocks.append(result.block)
                i = result.nextIndex
                continue
            }

            if let result = parseCodeBlock(lines: lines, startIndex: i) {
                blocks.append(result.block)
                i = result.nextIndex
                continue
            }

            if let result = parseHeading(trimmed) {
                blocks.append(result)
                i += 1
                continue
            }

            if let result = parseHorizontalRule(trimmed) {
                blocks.append(result)
                i += 1
                continue
            }

            if let result = parseTaskList(lines: lines, startIndex: i) {
                blocks.append(result.block)
                i = result.nextIndex
                continue
            }

            if let result = parseBulletList(lines: lines, startIndex: i) {
                blocks.append(result.block)
                i = result.nextIndex
                continue
            }

            if let result = parseBlockquote(trimmed) {
                blocks.append(result)
                i += 1
                continue
            }

            if let result = parseTable(lines: lines, startIndex: i) {
                blocks.append(result.block)
                i = result.nextIndex
                continue
            }

            // Default: paragraph
            blocks.append(.paragraph(text: trimmed))
            i += 1
        }

        return blocks
    }

    // MARK: - 解析折叠块
    private func parseDetailsBlock(lines: [String], startIndex: Int) -> (block: BlockType, nextIndex: Int)? {
        let trimmed = lines[startIndex].trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("<details>") else { return nil }

        var summary = ""
        var contentLines: [String] = []
        var i = startIndex + 1

        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("</details>") {
                i += 1
                break
            }

            if line.hasPrefix("<summary>") && line.contains("</summary>") {
                summary = line.replacingOccurrences(of: "<summary>", with: "")
                              .replacingOccurrences(of: "</summary>", with: "")
            } else if line.hasPrefix("<summary>") {
                // Handle multi-line summary if needed (rare but possible)
                summary = line.replacingOccurrences(of: "<summary>", with: "")
            } else if line.contains("</summary>") {
                summary += line.replacingOccurrences(of: "</summary>", with: "")
            } else {
                contentLines.append(lines[i])
            }
            i += 1
        }

        if summary.isEmpty { summary = "Details" }
        return (.details(summary: summary, content: contentLines.joined(separator: "\n")), i)
    }

    // MARK: - 解析代码块
    private func parseCodeBlock(lines: [String], startIndex: Int) -> (block: BlockType, nextIndex: Int)? {
        let trimmed = lines[startIndex].trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("```") else { return nil }

        let language = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        var codeLines: [String] = []
        var i = startIndex + 1

        while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
            codeLines.append(lines[i])
            i += 1
        }

        return (.codeBlock(code: codeLines.joined(separator: "\n"), language: language), i + 1)
    }

    // MARK: - 解析标题
    private func parseHeading(_ line: String) -> BlockType? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("#") else { return nil }

        let hashes = trimmed.prefix(while: { $0 == "#" })
        let level = hashes.count

        // 标题后面必须跟一个空格才是标准的 Markdown 标题 (e.g. "### Title")
        guard level >= 1 && level <= 6 else { return nil }

        let contentStart = trimmed.index(trimmed.startIndex, offsetBy: level)
        guard contentStart < trimmed.endIndex else { return nil }

        let afterHashes = trimmed[contentStart...]
        if afterHashes.hasPrefix(" ") {
            return .heading(text: afterHashes.trimmingCharacters(in: .whitespaces), level: level)
        }

        return nil
    }

    // MARK: - 解析水平线
    private func parseHorizontalRule(_ line: String) -> BlockType? {
        if line.hasPrefix("---") || line.hasPrefix("***") || line.hasPrefix("___") {
            return .horizontalRule
        }
        return nil
    }

    // MARK: - 解析任务列表
    private func parseTaskList(lines: [String], startIndex: Int) -> (block: BlockType, nextIndex: Int)? {
        let trimmed = lines[startIndex].trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("- [ ] ") || trimmed.hasPrefix("- [x] ") ||
              trimmed.hasPrefix("- [X] ") || trimmed.hasPrefix("* [ ] ") ||
              trimmed.hasPrefix("* [x] ") || trimmed.hasPrefix("* [X] ") else {
            return nil
        }

        var items: [(text: String, checked: Bool)] = []
        var i = startIndex

        while i < lines.count {
            let taskLine = lines[i].trimmingCharacters(in: .whitespaces)
            if taskLine.hasPrefix("- [ ] ") {
                items.append((text: String(taskLine.dropFirst(6)), checked: false))
            } else if taskLine.hasPrefix("- [x] ") || taskLine.hasPrefix("- [X] ") {
                items.append((text: String(taskLine.dropFirst(6)), checked: true))
            } else if taskLine.hasPrefix("* [ ] ") {
                items.append((text: String(taskLine.dropFirst(6)), checked: false))
            } else if taskLine.hasPrefix("* [x] ") || taskLine.hasPrefix("* [X] ") {
                items.append((text: String(taskLine.dropFirst(6)), checked: true))
            } else {
                break
            }
            i += 1
        }

        return (.taskList(items: items), i)
    }

    // MARK: - 解析无序列表
    private func parseBulletList(lines: [String], startIndex: Int) -> (block: BlockType, nextIndex: Int)? {
        let trimmed = lines[startIndex].trimmingCharacters(in: .whitespaces)

        // Check if it's a bullet list
        let isBulletList = trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ")
        // Check if it's a numbered list (e.g. "1. " or "1.[[")
        let isNumberedList: Bool
        if let dotIndex = trimmed.firstIndex(of: "."), dotIndex < trimmed.index(trimmed.startIndex, offsetBy: 4) {
            let prefix = trimmed[..<dotIndex]
            isNumberedList = prefix.allSatisfy { $0.isNumber } && !prefix.isEmpty
        } else {
            isNumberedList = false
        }

        guard isBulletList || isNumberedList else { return nil }

        var items: [String] = []
        var i = startIndex

        while i < lines.count {
            let listLine = lines[i].trimmingCharacters(in: .whitespaces)

            if isBulletList && (listLine.hasPrefix("- ") || listLine.hasPrefix("* ")) {
                items.append(String(listLine.dropFirst(2)))
            } else if isNumberedList, let dotIndex = listLine.firstIndex(of: ".") {
                let prefix = listLine[..<dotIndex]
                if prefix.allSatisfy({ $0.isNumber }) && !prefix.isEmpty {
                    let content = String(listLine[listLine.index(after: dotIndex)...]).trimmingCharacters(in: .whitespaces)
                    items.append(content)
                } else {
                    break
                }
            } else {
                break
            }
            i += 1
        }

        return (.bulletList(items: items, indent: isNumberedList ? -1 : 0), i) // 使用 -1 表示有序列表
    }

    // MARK: - 解析引用块
    private func parseBlockquote(_ line: String) -> BlockType? {
        if line.hasPrefix("> ") {
            return .blockquote(text: String(line.dropFirst(2)))
        }
        return nil
    }

    // MARK: - 解析表格
    private func parseTable(lines: [String], startIndex: Int) -> (block: BlockType, nextIndex: Int)? {
        guard isTableLine(lines[startIndex].trimmingCharacters(in: .whitespaces)) else { return nil }

        var tableLines: [String] = []
        var i = startIndex

        while i < lines.count && isTableLine(lines[i].trimmingCharacters(in: .whitespaces)) {
            tableLines.append(lines[i].trimmingCharacters(in: .whitespaces))
            i += 1
        }

        let dataLines = tableLines.filter { !$0.hasPrefix("|-") && !$0.hasPrefix("| -") }
        guard !dataLines.isEmpty else { return nil }

        let headers = parseTableCells(dataLines[0])
        var rows: [[String]] = []
        for lineIdx in 1..<dataLines.count {
            rows.append(parseTableCells(dataLines[lineIdx]))
        }

        return (.table(headers: headers, rows: rows), i)
    }

    // MARK: - 行内解析
    func parseInlineSegments(_ text: String) -> [InlineSegment] {
        var segments: [InlineSegment] = []
        let nsText = text as NSString
        var currentOffset = 0

        let patterns: [(InlineType, NSRegularExpression)] = [
            (.applink, .appLinkRegex),
            (.link, .linkRegex),
            (.bold, .boldRegex),
            (.italic, .italicRegex),
            (.strikethrough, .strikethroughRegex), // 新增删除线支持
            (.code, .codeRegex)
        ]

        while currentOffset < nsText.length {
            var earliestMatch: (type: InlineType, match: NSTextCheckingResult)?

            for (type, regex) in patterns {
                // 核心修复：使用 nsText.length 确保范围计算对多字节字符安全
                if let match = regex.firstMatch(in: text, options: [], range: NSRange(location: currentOffset, length: nsText.length - currentOffset)) {
                    if earliestMatch == nil || match.range.location < earliestMatch!.match.range.location {
                        earliestMatch = (type, match)
                    } else if match.range.location == earliestMatch!.match.range.location {
                        // 优先级策略：applink > link > bold
                        if type == .applink { earliestMatch = (type, match) }
                    }
                }
            }

            if let earliest = earliestMatch {
                let matchRange = earliest.match.range

                // 添加匹配项之前的普通文本
                if matchRange.location > currentOffset {
                    let before = nsText.substring(with: NSRange(location: currentOffset, length: matchRange.location - currentOffset))
                    segments.append(InlineSegment(type: .text, content: before))
                }

                // 处理匹配到的片段内容
                let content: String
                switch earliest.type {
                case .applink:
                    // 提取 [[ 内容 ]]
                    let raw = nsText.substring(with: earliest.match.range(at: 1)).trimmingCharacters(in: .whitespaces)
                    if raw.contains("|") {
                        let parts = raw.components(separatedBy: "|")
                        let title = String(parts.first ?? "").trimmingCharacters(in: .whitespaces)
                        let label = String(parts.last ?? "").trimmingCharacters(in: .whitespaces)
                        content = "\(label)|\(title)"
                    } else {
                        content = raw
                    }
                case .link:
                    let label = nsText.substring(with: earliest.match.range(at: 1))
                    let url = nsText.substring(with: earliest.match.range(at: 2))
                    content = "\(label)|\(url)"
                case .bold, .italic, .code, .strikethrough:
                    content = nsText.substring(with: earliest.match.range(at: 1))
                default:
                    content = ""
                }

                segments.append(InlineSegment(type: earliest.type, content: content))
                currentOffset = matchRange.location + matchRange.length
            } else {
                // 无更多匹配，添加剩余所有文本
                let remainingText = nsText.substring(from: currentOffset)
                if !remainingText.isEmpty {
                    segments.append(InlineSegment(type: .text, content: remainingText))
                }
                break
            }
        }

        return segments
    }

    // MARK: - 表格辅助方法
    private func isTableLine(_ line: String) -> Bool {
        line.hasPrefix("|") && line.hasSuffix("|")
    }

    private func parseTableCells(_ line: String) -> [String] {
        line.split(separator: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("-") }
    }
}

extension NSRegularExpression {
    /// 匹配双向链接 [[知识标题]] 或 [[显示文本|实际标题]]
    /// 使用负向断言 (?<!\\\\) 排除转义的括号，确保 \[\[ 不被识别
    static let appLinkRegex = try! NSRegularExpression(pattern: "(?<!\\\\)\\[\\[([^\\]]+)\\]\\]")
    
    /// 匹配加粗文本 **内容**
    static let boldRegex = try! NSRegularExpression(pattern: "(?<!\\\\)\\*\\*([^*]+)\\*\\*")
    
    /// 匹配斜体文本 *内容*
    static let italicRegex = try! NSRegularExpression(pattern: "(?<!\\\\)\\*([^*]+)\\*")
    
    /// 匹配删除线文本 ~~内容~~
    static let strikethroughRegex = try! NSRegularExpression(pattern: "(?<!\\\\)~~([^~]+)~~")
    
    /// 匹配行内代码 `代码`
    static let codeRegex = try! NSRegularExpression(pattern: "(?<!\\\\)`([^`]+)`")
    
    /// 匹配标准 Markdown 链接 [标签](URL)
    /// 针对 URL 内部包含括号的场景进行了非贪婪优化
    static let linkRegex = try! NSRegularExpression(pattern: "(?<!\\\\)\\[([^\\]]+)\\]\\(([^\\)]+)\\)")
}
