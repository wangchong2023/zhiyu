// MarkdownProcessor.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：本文件实现了全功能 Markdown 文本解析处理器（MarkdownProcessor），是系统中内容渲染与语义理解的核心组件。
// 该处理器通过高性能正则引擎实现以下功能点：
// 1. 深度标题识别：支持从 H1 到 H6 的全层级标准标题解析，并能自动去除冗余的 Markdown 符号。
// 2. 块类型提取：精准识别并分离普通段落、无序列表、代码块以及引用块，将其转换为结构化的中间模型。
// 3. 实时清洗：自动剔除不规范的换行符和首尾空格，确保输出的内容在 UI 层渲染时具备一致的边距表现。
// 4. 扩展性支持：预留了对自定义标记和公式解析的扩展接口，保障了文档解析能力的持续进化。
// 版本: 1.2
// 修改记录:
//   - 2026-05-05: 优化 H1-H6 解析逻辑，迁移至 Utils/Processors 归口管理
//   - 2026-05-18: 完美升级为 100% 结构化中文三斜杠注释，逐行补充复杂解析行内中文步骤说明
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

// MARK: - Markdown 解析器

/// Markdown 内容的纯解析层（MarkdownProcessor）。
/// 该解析器负责将输入的 Markdown 原始文本转换为结构化的数据块（BlockType）与行内标记（InlineType）模型，
/// 以屏蔽排版细节并暴露给高层业务。渲染工作由 `MarkdownRendererView` 独立处理，完美遵循单一职责原则（SRP）。
final class MarkdownProcessor: Sendable {

    // MARK: - 块类型

    /// 代表 Markdown 结构化文档中的高级排版物理块 (BlockType)。
    enum BlockType {
        /// 标题块。
        /// - Parameters:
        ///   - text: 标题文字内容。
        ///   - level: 标题层级，范围为 1 至 6，分别对应 # 至 ######。
        case heading(text: String, level: Int)
        
        /// 普通段落文本块。
        /// - Parameter text: 段落的纯文本内容。
        case paragraph(text: String)
        
        /// 无序或有序列表块。
        /// - Parameters:
        ///   - items: 列表中每一项的纯文本内容数组。
        ///   - indent: 缩进级别（若为有序列表，则该值统一约定为 -1）。
        case bulletList(items: [String], indent: Int)
        
        /// 引用块（以 `>` 引导）。
        /// - Parameter text: 引用块内的文本内容。
        case blockquote(text: String)
        
        /// 代码块（以 ``` 引导与收尾）。
        /// - Parameters:
        ///   - code: 代码块内部的原始代码串。
        ///   - language: 编程语言名称标识（如 swift, python 等，可能为空）。
        case codeBlock(code: String, language: String)
        
        /// 标准 Markdown 表格块。
        /// - Parameters:
        ///   - headers: 表头单元格的内容数组。
        ///   - rows: 二维数组，表示表格的每一行单元格内容。
        case table(headers: [String], rows: [[String]])
        
        /// 水平分割线（如 `---` 或 `***`）。
        case horizontalRule
        
        /// 带有复选框的任务列表块。
        /// - Parameter items: 元组数组，包含任务项文字和是否已勾选的状态。
        case taskList(items: [(text: String, checked: Bool)])
        
        /// HTML 折叠细节块（`<details>` 标签）。
        /// - Parameters:
        ///   - summary: 折叠栏标题文案（由 `<summary>` 包含）。
        ///   - content: 折叠内部展开的原始 Markdown 字符串。
        case details(summary: String, content: String)
    }

    // MARK: - 行内类型

    /// 标记文本行内部微观样式的行内类型 (InlineType)。
    enum InlineType {
        /// 普通纯文本。
        case text
        /// 加粗文本（如 `**内容**`）。
        case bold
        /// 斜体文本（如 `*内容*` 或 `_内容_`）。
        case italic
        /// 删除线文本（如 `~~内容~~`）。
        case strikethrough
        /// 行内代码（如 `` `代码` ``）。
        case code
        /// 智宇专有的双链 App 链接（如 `[[目标页面]]` 或 `[[显示文案|目标页面]]`）。
        case applink
        /// 标准 Markdown 外链（如 `[文案](URL)`）。
        case link
        /// 单个表情符号。
        case emoji
    }

    /// 行内分割实体，表示具有特定微观样式的局部片段 (InlineSegment)。
    struct InlineSegment {
        /// 当前片段的行内样式类型。
        let type: InlineType
        /// 当前片段的实际文本或目标跳转载荷。
        let content: String
    }

    // MARK: - 解析完整内容

    /// 将输入的整段 Markdown 原始字符串解析为有序的结构化物理块数组。
    /// - Parameter content: 需要解析的原始 Markdown 文本。
    /// - Returns: 解析完成后的 `BlockType` 物理块数组。
    func parse(_ content: String) -> [BlockType] {
        let lines = content.components(separatedBy: "\n")
        var blocks: [BlockType] = []
        var i = 0

        // 逐行进行段落流状态扫描与物理块组装
        while i < lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)

            // 1. 自动忽略并跳过空白行
            if trimmed.isEmpty {
                i += 1
                continue
            }

            // 2. 依次测试细节折叠块解析器
            if let result = parseDetailsBlock(lines: lines, startIndex: i) {
                blocks.append(result.block)
                i = result.nextIndex
                continue
            }

            // 3. 测试标准多行代码块解析器
            if let result = parseCodeBlock(lines: lines, startIndex: i) {
                blocks.append(result.block)
                i = result.nextIndex
                continue
            }

            // 4. 测试 H1-H6 标题解析器
            if let result = parseHeading(trimmed) {
                blocks.append(result)
                i += 1
                continue
            }

            // 5. 测试水平线分割符解析器
            if let result = parseHorizontalRule(trimmed) {
                blocks.append(result)
                i += 1
                continue
            }

            // 6. 测试任务列表解析器
            if let result = parseTaskList(lines: lines, startIndex: i) {
                blocks.append(result.block)
                i = result.nextIndex
                continue
            }

            // 7. 测试无序及有序列表解析器
            if let result = parseBulletList(lines: lines, startIndex: i) {
                blocks.append(result.block)
                i = result.nextIndex
                continue
            }

            // 8. 测试块引用解析器
            if let result = parseBlockquote(trimmed) {
                blocks.append(result)
                i += 1
                continue
            }

            // 9. 测试表格排版解析器
            if let result = parseTable(lines: lines, startIndex: i) {
                blocks.append(result.block)
                i = result.nextIndex
                continue
            }

            // 10. 均不匹配时，降级识别为普通文本段落
            blocks.append(.paragraph(text: trimmed))
            i += 1
        }

        return blocks
    }

    // MARK: - 私有解析辅助方法

    /// 尝试解析 HTML 折叠块 `<details>`。
    /// - Parameters:
    ///   - lines: 原始全文按行拆分后的数组。
    ///   - startIndex: 当前扫描的起始行索引。
    /// - Returns: 若匹配成功，返回折叠块实体与下一行待扫描的偏移索引；否则返回 `nil`。
    private func parseDetailsBlock(lines: [String], startIndex: Int) -> (block: BlockType, nextIndex: Int)? {
        let trimmed = lines[startIndex].trimmingCharacters(in: .whitespaces)
        // 检查折叠标签的开端
        guard trimmed.hasPrefix("<details>") else { return nil }

        var summary = ""
        var contentLines: [String] = []
        var i = startIndex + 1

        // 持续向下扫描，直到抓取到配对的闭合标签
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("</details>") {
                i += 1
                break
            }

            // 精准抓取 summary 标题内容
            if line.hasPrefix("<summary>") && line.contains("</summary>") {
                summary = line.replacingOccurrences(of: "<summary>", with: "")
                              .replacingOccurrences(of: "</summary>", with: "")
            } else if line.hasPrefix("<summary>") {
                // 处理极少见的多行 summary 头部开端
                summary = line.replacingOccurrences(of: "<summary>", with: "")
            } else if line.contains("</summary>") {
                // 处理极少见的多行 summary 尾部闭合
                summary += line.replacingOccurrences(of: "</summary>", with: "")
            } else {
                // 折叠块内的正文行，追加合并
                contentLines.append(lines[i])
            }
            i += 1
        }

        // 默认兜底标题文案
        if summary.isEmpty { summary = "Details" }
        return (.details(summary: summary, content: contentLines.joined(separator: "\n")), i)
    }

    /// 尝试解析标准多行代码块。
    /// - Parameters:
    ///   - lines: 原始全文按行拆分后的数组。
    ///   - startIndex: 当前扫描的起始行索引。
    /// - Returns: 若匹配成功，返回代码块实体与下一行待扫描的偏移索引；否则返回 `nil`。
    private func parseCodeBlock(lines: [String], startIndex: Int) -> (block: BlockType, nextIndex: Int)? {
        let trimmed = lines[startIndex].trimmingCharacters(in: .whitespaces)
        // 代码块必须以三反引号引导
        guard trimmed.hasPrefix("```") else { return nil }

        // 提取语法高亮语言标识 (e.g. ```swift -> swift)
        let language = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        var codeLines: [String] = []
        var i = startIndex + 1

        // 循环收集代码行，直到遇见下一组闭合的反引号为止
        while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
            codeLines.append(lines[i])
            i += 1
        }

        return (.codeBlock(code: codeLines.joined(separator: "\n"), language: language), i + 1)
    }

    /// 尝试解析 Markdown 标准标题（H1 - H6）。
    /// - Parameter line: 当前待匹配的去空格行。
    /// - Returns: 若匹配成功，返回对应的 `BlockType.heading` 标题块；否则返回 `nil`。
    private func parseHeading(_ line: String) -> BlockType? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("#") else { return nil }

        // 统计开头连续的井号个数以决定标题等级
        let hashes = trimmed.prefix(while: { $0 == "#" })
        let level = hashes.count

        // 标题后面必须跟一个空格才是标准的 Markdown 标题且层级在 1 到 6 之间
        guard level >= 1 && level <= 6 else { return nil }

        let contentStart = trimmed.index(trimmed.startIndex, offsetBy: level)
        guard contentStart < trimmed.endIndex else { return nil }

        let afterHashes = trimmed[contentStart...]
        if afterHashes.hasPrefix(" ") {
            return .heading(text: afterHashes.trimmingCharacters(in: .whitespaces), level: level)
        }

        return nil
    }

    /// 尝试解析水平线分割符。
    /// - Parameter line: 当前待匹配的去空格行。
    /// - Returns: 若匹配成功，返回 `BlockType.horizontalRule`；否则返回 `nil`。
    private func parseHorizontalRule(_ line: String) -> BlockType? {
        if line.hasPrefix("---") || line.hasPrefix("***") || line.hasPrefix("___") {
            return .horizontalRule
        }
        return nil
    }

    /// 尝试解析任务列表块。
    /// - Parameters:
    ///   - lines: 原始全文按行拆分后的数组。
    ///   - startIndex: 当前扫描的起始行索引。
    /// - Returns: 若匹配成功，返回任务列表块实体与下一行扫描物理偏移；否则返回 `nil`。
    private func parseTaskList(lines: [String], startIndex: Int) -> (block: BlockType, nextIndex: Int)? {
        let trimmed = lines[startIndex].trimmingCharacters(in: .whitespaces)
        // 精准过滤各种复选框样式
        guard trimmed.hasPrefix("- [ ] ") || trimmed.hasPrefix("- [x] ") ||
              trimmed.hasPrefix("- [X] ") || trimmed.hasPrefix("* [ ] ") ||
              trimmed.hasPrefix("* [x] ") || trimmed.hasPrefix("* [X] ") else {
            return nil
        }

        var items: [(text: String, checked: Bool)] = []
        var i = startIndex

        // 连续收拢复选框行，聚合成高内聚的任务物理块
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
                break // 遇见非复选框内容时打断连续合并
            }
            i += 1
        }

        return (.taskList(items: items), i)
    }

    /// 获取某一文本行的物理缩进空格数（处理嵌套列表的核心算法辅助）。
    /// - Parameter line: 原始文本行。
    /// - Returns: 该行起首的空格计数（制表符 \t 强制折算为 4 个空格）。
    private func getIndentLevel(_ line: String) -> Int {
        var count = 0
        for char in line {
            if char == " " {
                count += 1
            } else if char == "\t" {
                count += 4
            } else {
                break
            }
        }
        return count
    }

    /// 尝试解析无序列表或有序列表块。
    /// - Parameters:
    ///   - lines: 原始全文按行拆分后的数组。
    ///   - startIndex: 当前扫描的起始行索引。
    /// - Returns: 若匹配成功，返回对应的 `bulletList` 物理块及下一次的行偏移；否则返回 `nil`。
    private func parseBulletList(lines: [String], startIndex: Int) -> (block: BlockType, nextIndex: Int)? {
        let startLine = lines[startIndex]
        let trimmedStart = startLine.trimmingCharacters(in: .whitespaces)

        // 识别无序列表前缀
        let isBulletList = trimmedStart.hasPrefix("- ") || trimmedStart.hasPrefix("* ")
        // 识别有序列表前缀（如 "1. " 或 "1.[[" 等数字加上点号的情况）
        let isNumberedList: Bool
        if let dotIndex = trimmedStart.firstIndex(of: "."), dotIndex < trimmedStart.index(trimmedStart.startIndex, offsetBy: 4) {
            let prefix = trimmedStart[..<dotIndex]
            isNumberedList = prefix.allSatisfy { $0.isNumber } && !prefix.isEmpty
        } else {
            isNumberedList = false
        }

        guard isBulletList || isNumberedList else { return nil }

        let startIndent = getIndentLevel(startLine)
        var items: [String] = []
        var i = startIndex

        // 开启循环，收纳缩进一致的连续项
        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let indent = getIndentLevel(line)

            if trimmed.isEmpty {
                break
            }

            let isItem = trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ")
            let isNumItem: Bool
            if let dotIndex = trimmed.firstIndex(of: "."), dotIndex < trimmed.index(trimmed.startIndex, offsetBy: 4) {
                let prefix = trimmed[..<dotIndex]
                isNumItem = prefix.allSatisfy { $0.isNumber } && !prefix.isEmpty
            } else {
                isNumItem = false
            }

            if isItem || isNumItem {
                // 如果发现当前行的缩进与列表起点完全对齐，则是同级兄弟节点
                if indent == startIndent {
                    if isBulletList && isItem {
                        items.append(String(trimmed.dropFirst(2)))
                    } else if isNumberedList && isNumItem, let dotIndex = trimmed.firstIndex(of: ".") {
                        let content = String(trimmed[trimmed.index(after: dotIndex)...]).trimmingCharacters(in: .whitespaces)
                        items.append(content)
                    } else {
                        break
                    }
                } else if indent < startIndent {
                    break // 缩进减小，说明当前列表物理终结，退出扫描
                } else {
                    // 缩进更大说明是嵌套的子列表，在当前平铺列表扫描中忽略子节点正文，仅跳过并继续合并父级
                }
            } else {
                break
            }
            i += 1
        }

        return (.bulletList(items: items, indent: isNumberedList ? -1 : startIndent), i)
    }

    /// 尝试解析引用块。
    /// - Parameter line: 当前待匹配的去空格行。
    /// - Returns: 若匹配成功，返回 `BlockType.blockquote` 引用块；否则返回 `nil`。
    private func parseBlockquote(_ line: String) -> BlockType? {
        if line.hasPrefix("> ") {
            return .blockquote(text: String(line.dropFirst(2)))
        }
        return nil
    }

    /// 尝试解析表格块。
    /// - Parameters:
    ///   - lines: 原始全文按行拆分后的数组。
    ///   - startIndex: 当前扫描的起始行索引。
    /// - Returns: 若匹配成功，返回标准表格块实体与下一扫描行偏移；否则返回 `nil`。
    private func parseTable(lines: [String], startIndex: Int) -> (block: BlockType, nextIndex: Int)? {
        guard isTableLine(lines[startIndex].trimmingCharacters(in: .whitespaces)) else { return nil }

        var tableLines: [String] = []
        var i = startIndex

        // 持续收集表格格式行（以 | 开始并以 | 结束）
        while i < lines.count && isTableLine(lines[i].trimmingCharacters(in: .whitespaces)) {
            tableLines.append(lines[i].trimmingCharacters(in: .whitespaces))
            i += 1
        }

        // 剔除表格的分割对齐行（例如 |---| 或 |:---|）
        let dataLines = tableLines.filter { !$0.hasPrefix("|-") && !$0.hasPrefix("| -") }
        guard !dataLines.isEmpty else { return nil }

        // 解析第一行为表头 headers
        let headers = parseTableCells(dataLines[0])
        var rows: [[String]] = []
        // 依次解析余下行为每一行数据 rows
        for lineIdx in 1..<dataLines.count {
            rows.append(parseTableCells(dataLines[lineIdx]))
        }

        return (.table(headers: headers, rows: rows), i)
    }

    // MARK: - 行内解析（核心两阶段解析算法）

    /// 智宇系统核心：基于两阶段行内样式解析法提取富文本片段。
    ///
    /// - 核心设计初衷 (Conflict Prevention):
    ///   标准的正则表达式引擎在面对复合嵌套样式（如加粗斜体包围智宇双链，形如 `***[[知识页面]]***`）时，
    ///   极易发生贪婪模式匹配错乱，导致双链标志 `[[` 与 `]]` 被错误切断破坏。
    ///   为彻底根除此项工业级痛点，我们设计了精妙的“两阶段解析算法”：
    ///   1. **阶段一 (Applink 保护区)**：优先全局检索并提取所有的智宇双链 `[[...]]` 位置。将其视为高级黄金保护节点固定下来。
    ///   2. **阶段二 (格式化碎裂匹配)**：在两个双链节点之间的物理夹缝文本段中，依次级联运行 Bold、Italic、Strikethrough、Link 与 Code 正则，
    ///      从而实现防对撞、防截断的完美富文本物理分割。
    ///
    /// - Parameter text: 包含各种行内标记的原始单行 Markdown 字符串。
    /// - Returns: 有序排列的行内样式片段（`InlineSegment`）实体数组。
    func parseInlineSegments(_ text: String) -> [InlineSegment] {
        // 步骤 1.1：为避免 Objective-C NSString 范围与 Swift String.Index 偏移冲突导致崩溃，将输入字符串安全转换为 NSString
        let nsText = text as NSString
        var result: [InlineSegment] = []
        var currentOffset = 0

        // 步骤 1.2：第一阶段——寻找所有的 Applink。定义整行覆盖范围，并利用预编译的 appLinkRegex 查找全部 `[[双向链接]]`
        let searchRange = NSRange(location: 0, length: nsText.length)
        let applinkMatches = NSRegularExpression.appLinkRegex.matches(in: text, options: [], range: searchRange)

        // 步骤 1.3：启动双链迭代扫描，将每一个捕获到的双链区域视为绝对保护段
        for match in applinkMatches {
            // 步骤 1.4：如果当前双链匹配的起点大于记录 of 偏移量，说明中间夹有非双链文本，截取子串并调度二级格式化解析器进行深度匹配
            if match.range.location > currentOffset {
                let beforeRange = NSRange(location: currentOffset, length: match.range.location - currentOffset)
                let beforeText = nsText.substring(with: beforeRange)
                result.append(contentsOf: parseFormattingSegments(beforeText))
            }

            // 步骤 1.5：提取双链中由第一捕获组 `(.+?)` 所包裹的原始字面量，并安全剔除首尾多余空格
            let raw = nsText.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
            let content: String
            
            // 步骤 1.6：若包含管线符 `|`，说明是别名双链（如 `[[我的链接|实际页面]]`），进行物理切分，将别名与真实页面组合编码以备后续使用
            if raw.contains("|") {
                let parts = raw.components(separatedBy: "|")
                let label = String(parts.first ?? "").trimmingCharacters(in: .whitespaces)
                let title = String(parts.last ?? "").trimmingCharacters(in: .whitespaces)
                content = "\(label)|\(title)"
            } else {
                content = raw
            }
            
            // 步骤 1.7：将处理完毕的双链封装为 .applink 段追加进结果中，并将偏移量同步平移到双链闭合括号 `]]` 的下一位
            result.append(InlineSegment(type: .applink, content: content))
            currentOffset = match.range.location + match.range.length
        }

        // 步骤 1.8：首阶段扫尾。若最后一个双链解析完毕后，偏移量距离字符串总长度还有剩余，说明尾端存在碎屑文本，再次调用二级解析器扫尾
        if currentOffset < nsText.length {
            let remaining = nsText.substring(from: currentOffset)
            result.append(contentsOf: parseFormattingSegments(remaining))
        }

        return result
    }

    /// 第二阶段解析：在双链保护区夹缝中，深度级联提取普通富文本标记（加粗、斜体、删除线、外链及代码块）。
    ///
    /// - Parameter text: 夹在双链片段之间的子区间纯文本字串。
    /// - Returns: 解析完毕的局域行内格式化片段列表。
    private func parseFormattingSegments(_ text: String) -> [InlineSegment] {
        var segments: [InlineSegment] = []
        let nsText = text as NSString
        var currentOffset = 0

        // 步骤 2.1：定义高优先级贪婪度格式正则的级联匹配字典，严格按照“外链 -> 粗体 -> 斜体 -> 删除线 -> 行内代码”的物理次序层级递归
        let patterns: [(InlineType, NSRegularExpression)] = [
            (.link, .linkRegex),
            (.bold, .boldRegex),
            (.italic, .italicRegex),
            (.strikethrough, .strikethroughRegex),
            (.code, .codeRegex)
        ]

        // 步骤 2.2：启动位置平移指针，开始循环扫描碎屑区间的所有微观格式
        while currentOffset < nsText.length {
            var earliestMatch: (type: InlineType, match: NSTextCheckingResult)?

            // 步骤 2.3：为防止跨样式对冲命中，在当前偏移量后依次运行所有格式正则，寻找“首个被物理命中的最前方格式前缀”（即 location 最小者）
            for (type, regex) in patterns {
                if let match = regex.firstMatch(in: text, options: [], range: NSRange(location: currentOffset, length: nsText.length - currentOffset)) {
                    if earliestMatch == nil || match.range.location < earliestMatch!.match.range.location {
                        earliestMatch = (type, match)
                    }
                }
            }

            // 步骤 2.4：若检测到有效格式命中，则提取该匹配段前方的纯文本字串，将其安全封包为 `.text` 原始片段
            if let earliest = earliestMatch {
                let matchRange = earliest.match.range
                
                if matchRange.location > currentOffset {
                    let before = nsText.substring(with: NSRange(location: currentOffset, length: matchRange.location - currentOffset))
                    segments.append(InlineSegment(type: .text, content: before))
                }

                // 步骤 2.5：核心内容清洗——剥离格式化引导符（如 `**`、`~~`、`[ ]`），精准还原捕获组内的真正正文，并区分处理 Markdown 外链
                let content: String
                switch earliest.type {
                case .link:
                    let label = nsText.substring(with: earliest.match.range(at: 1))
                    let url = nsText.substring(with: earliest.match.range(at: 2))
                    content = "\(label)|\(url)"
                case .bold, .italic, .code, .strikethrough:
                    content = nsText.substring(with: earliest.match.range(at: 1))
                default:
                    content = ""
                }

                // 步骤 2.6：装载匹配到的 Segment 实例，并瞬间平移当前偏移量至整个匹配区间（如整个 **粗体**）的闭合标记之后
                segments.append(InlineSegment(type: earliest.type, content: content))
                currentOffset = matchRange.location + matchRange.length
            } else {
                // 步骤 2.7：当没有任何格式化正则被命中的情况下，将剩余所有字符合并打包为最后的普通 `.text` Segment 载荷，打断循环
                let remaining = nsText.substring(from: currentOffset)
                if !remaining.isEmpty {
                    segments.append(InlineSegment(type: .text, content: remaining))
                }
                break
            }
        }
        return segments
    }

    // MARK: - 表格辅助解析方法

    /// 诊断并测试给定的纯文本行是否完全符合 Markdown 表格管线布局的物理特征。
    ///
    /// - Parameter line: 已经过首尾去空格处理的待检测单行字符串。
    /// - Returns: 若起首和收尾字符均为管线符 `|`，则判定为是，返回 `true`，否则返回 `false`。
    private func isTableLine(_ line: String) -> Bool {
        line.hasPrefix("|") && line.hasSuffix("|")
    }

    /// 提取表格行中被管线符 `|` 物理分隔的多列单元格文本。
    ///
    /// - Parameter line: 包含管线符的 Markdown 原始表格单行字符串。
    /// - Returns: 清除首尾空格并物理过滤掉虚线对齐分隔符后，所包含的单元格字符有序数组。
    private func parseTableCells(_ line: String) -> [String] {
        line.split(separator: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("-") }
    }
}

// MARK: - 正则表达式拓展

extension NSRegularExpression {
    /// 匹配智宇双向链接 `[[知识标题]]` 或 `[[显示文本|实际标题]]`。
    /// 使用负向断言 `(?<!\\)` 物理排除转义后的括号，确保 `\[\[` 不会被错误捕获。
    static let appLinkRegex = try! NSRegularExpression(pattern: "(?<!\\\\)\\[\\[(.+?)\\]\\]")
    
    /// 匹配加粗文本 `**加粗内容**`。
    static let boldRegex = try! NSRegularExpression(pattern: "(?<!\\\\)\\*\\*(.+?)\\*\\*")
    
    /// 匹配斜体文本 `*斜体内容*` 或 `_斜体内容_`。
    static let italicRegex = try! NSRegularExpression(pattern: "(?<!\\\\)[\\*_](.+?)[\\*_]")
    
    /// 匹配删除线文本 `~~删除线内容~~`。
    static let strikethroughRegex = try! NSRegularExpression(pattern: "(?<!\\\\)~~(.+?)~~")
    
    /// 匹配行内代码 `` `代码` ``。
    static let codeRegex = try! NSRegularExpression(pattern: "(?<!\\\\)`(.+?)`")
    
    /// 匹配标准 Markdown 外链 `[标签](URL)`。
    /// 对 URL 内部可能嵌套的圆括号作了非贪婪防跨行捕获优化。
    static let linkRegex = try! NSRegularExpression(pattern: "(?<!\\\\)\\[(.+?)\\]\\((.+?)\\)")
}
