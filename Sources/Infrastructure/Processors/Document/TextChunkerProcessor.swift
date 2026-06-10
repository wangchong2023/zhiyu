//
//  TextChunkerProcessor.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：文档处理器：Markdown 解析、文本分块、图谱布局、网页抓取。
//
import Foundation

/// 递归分块器 (RAG 核心：语义保真)
/// 负责将长文档拆分为适合向量检索的小块，对标 Karpathy 的 LLM Wiki 切片标准。
struct TextChunkerProcessor: Sendable {

    /// 增强型分块模型
    public struct Chunk: Identifiable, Sendable {
        public let id = UUID()
        public let text: String       // 分块文本内容
        public let startIndex: Int    // 原始文本起始偏移
        public let anchorPath: String // 标题路径 (例如: "") - 仅保持当前最近的单级标题，以维护老旧单测兼容性
        public let breadcrumbPath: String // 级联面包屑路径 (例如: " > ") - 专门用于 Hierarchy RAG
        public let isCode: Bool       // 是否包含完整代码块
        
        /// 级联面包屑注入后的上下文文本，最大化提升检索语义相关性
        public var contextualText: String {
            if breadcrumbPath == "Root" || breadcrumbPath.isEmpty {
                return text
            } else {
                return "[Context: \(breadcrumbPath)]\n\(text)"
            }
        }
    }

    /// 分块配置
    public struct Config {
        public let chunkSize: Int      // 目标字符数 (800-1200 推荐)
        public let chunkOverlap: Int   // 重叠窗口大小 (150-200 推荐)
        public let separators: [String] // 优先级梯度
    }

    public static let `default` = Config(
        chunkSize: 1000,
        chunkOverlap: 200,
        separators: ["\n# ", "\n## ", "\n### ", "\n#### ", "\n\n", "\n", ". ", ". ", " ", ""]
    )

    /**
     * @description: 执行高级语义分块
     * @param {String} text 原始文本
     * @return {[Chunk]} 包含元数据的高质量切片
     */

    /// 拆分
    /// - Parameter text: text
    /// - Parameter config: config
    /// - Returns: 列表
    func split(text: String, config: Config = TextChunkerProcessor.default) -> [Chunk] {
        guard !text.isEmpty else { return [] }
        let lines = text.components(separatedBy: .newlines)
        var state = ChunkingState()

        for line in lines {
            let shouldTurnOffCodeBlock = updateCodeBlockState(line: line, state: &state)
            if !state.isInCodeBlock && line.hasPrefix("#") {
                flushCurrentChunk(lines: lines, state: &state, text: text)
                updateHeaderTracking(line: line, state: &state)
            }
            let lineWithNewline = line + "\n"
            if (state.currentChunkText.count + lineWithNewline.count) > config.chunkSize && !state.isInCodeBlock {
                flushChunkOnOverflow(lineWithNewline: lineWithNewline, config: config, state: &state)
            } else {
                state.currentChunkText += lineWithNewline
            }
            if shouldTurnOffCodeBlock {
                state.isInCodeBlock = false
            }
        }

        let trimmedLast = state.currentChunkText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedLast.isEmpty {
            state.chunks.append(Chunk(text: trimmedLast, startIndex: state.currentStartIndex, anchorPath: state.currentAnchor, breadcrumbPath: state.currentBreadcrumb, isCode: state.currentChunkText.contains("```")))
        }
        return state.chunks
    }

    private struct ChunkingState {
        var chunks: [Chunk] = []
        var currentChunkText = ""
        var currentAnchor = "Root"
        var currentBreadcrumb = "Root"
        var anchorStack: [String] = []
        var currentStartIndex = 0
        var isInCodeBlock = false
    }

    private func updateCodeBlockState(line: String, state: inout ChunkingState) -> Bool {
        let isCodeFlag = line.trimmingCharacters(in: .whitespaces).hasPrefix("```")
        guard isCodeFlag else { return false }
        if state.isInCodeBlock {
            return true
        } else {
            state.isInCodeBlock = true
            return false
        }
    }

    private func flushCurrentChunk(lines: [String], state: inout ChunkingState, text: String) {
        let trimmedPrev = state.currentChunkText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrev.isEmpty else { return }
        state.chunks.append(Chunk(text: trimmedPrev, startIndex: state.currentStartIndex, anchorPath: state.currentAnchor, breadcrumbPath: state.currentBreadcrumb, isCode: state.currentChunkText.contains("```")))
        state.currentStartIndex += state.currentChunkText.count
        state.currentChunkText = ""
    }

    private func updateHeaderTracking(line: String, state: inout ChunkingState) {
        let headerLevel = line.prefix(while: { $0 == "#" }).count
        let headerText = line.dropFirst(headerLevel).trimmingCharacters(in: .whitespaces)
        guard headerLevel > 0 else {
            state.currentBreadcrumb = headerText
            state.currentAnchor = headerText
            return
        }
        let keepCount = headerLevel - 1
        if state.anchorStack.count > keepCount {
            state.anchorStack = Array(state.anchorStack.prefix(keepCount))
        }
        state.anchorStack.append(headerText)
        state.currentBreadcrumb = state.anchorStack.joined(separator: " > ")
        state.currentAnchor = headerText
    }

    private func flushChunkOnOverflow(lineWithNewline: String, config: Config, state: inout ChunkingState) {
        state.chunks.append(Chunk(text: state.currentChunkText.trimmingCharacters(in: .whitespacesAndNewlines), startIndex: state.currentStartIndex, anchorPath: state.currentAnchor, breadcrumbPath: state.currentBreadcrumb, isCode: state.currentChunkText.contains("```")))
        let overlapIndex = state.currentChunkText.index(state.currentChunkText.endIndex, offsetBy: -config.chunkOverlap, default: state.currentChunkText.startIndex)
        state.currentChunkText = String(state.currentChunkText[overlapIndex...]) + lineWithNewline
        state.currentStartIndex += (state.currentChunkText.count - config.chunkOverlap)
    }
}

private extension String {

    /// 索引
    /// - Parameter index: 索引
    /// - Returns: 返回值
    func index(_ index: String.Index, offsetBy offset: Int, default defaultIndex: String.Index) -> String.Index {
        return self.index(index, offsetBy: offset, limitedBy: self.startIndex) ?? defaultIndex
    }
}
