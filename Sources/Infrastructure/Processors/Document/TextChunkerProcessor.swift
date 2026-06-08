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
    // swiftlint:disable:next cyclomatic_complexity
    func split(text: String, config: Config = TextChunkerProcessor.default) -> [Chunk] {
        guard !text.isEmpty else { return [] }
        
        var chunks: [Chunk] = []
        let lines = text.components(separatedBy: .newlines)
        
        var currentChunkText = ""
        var currentAnchor = "Root"
        var currentBreadcrumb = "Root"
        var anchorStack: [String] = [] // 标题层级栈，保存当前所处的大纲树路径
        var currentStartIndex = 0
        var isInCodeBlock = false
        
        for line in lines {
            let isCodeFlag = line.trimmingCharacters(in: .whitespaces).hasPrefix("```")
            var shouldTurnOffCodeBlock = false
            
            // 1. 状态追踪：代码块保护前置判定
            if isCodeFlag {
                if isInCodeBlock {
                    shouldTurnOffCodeBlock = true
                } else {
                    isInCodeBlock = true
                }
            }
            
            // 2. 标题路径追踪 (Anchor Tracking)与天然物理切分
            if !isInCodeBlock && line.hasPrefix("#") {
                let trimmedPrev = currentChunkText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedPrev.isEmpty {
                    chunks.append(Chunk(
                        text: trimmedPrev,
                        startIndex: currentStartIndex,
                        anchorPath: currentAnchor,
                        breadcrumbPath: currentBreadcrumb,
                        isCode: currentChunkText.contains("```")
                    ))
                    currentStartIndex += currentChunkText.count
                    currentChunkText = ""
                }
                
                // 解析当前的标题级别（计算 # 的个数）
                let headerLevel = line.prefix(while: { $0 == "#" }).count
                let headerText = line.dropFirst(headerLevel).trimmingCharacters(in: .whitespaces)
                
                if headerLevel > 0 {
                    let keepCount = headerLevel - 1
                    if anchorStack.count > keepCount {
                        anchorStack = Array(anchorStack.prefix(keepCount))
                    }
                    anchorStack.append(headerText)
                    currentBreadcrumb = anchorStack.joined(separator: " > ")
                    currentAnchor = headerText
                } else {
                    currentBreadcrumb = headerText
                    currentAnchor = headerText
                }
            }
            
            let lineWithNewline = line + "\n"
            
            // 3. 贪婪聚合与重叠判定
            if (currentChunkText.count + lineWithNewline.count) > config.chunkSize && !isInCodeBlock {
                chunks.append(Chunk(
                    text: currentChunkText.trimmingCharacters(in: .whitespacesAndNewlines),
                    startIndex: currentStartIndex,
                    anchorPath: currentAnchor,
                    breadcrumbPath: currentBreadcrumb,
                    isCode: currentChunkText.contains("```")
                ))
                
                let overlapIndex = currentChunkText.index(currentChunkText.endIndex, offsetBy: -config.chunkOverlap, default: currentChunkText.startIndex)
                currentChunkText = String(currentChunkText[overlapIndex...]) + lineWithNewline
                currentStartIndex += (currentChunkText.count - config.chunkOverlap)
            } else {
                currentChunkText += lineWithNewline
            }
            
            // 4. 代码块保护后置判定
            if shouldTurnOffCodeBlock {
                isInCodeBlock = false
            }
        }
        
        // 补全最后一个块
        let trimmedLast = currentChunkText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedLast.isEmpty {
            chunks.append(Chunk(
                text: trimmedLast,
                startIndex: currentStartIndex,
                anchorPath: currentAnchor,
                breadcrumbPath: currentBreadcrumb,
                isCode: currentChunkText.contains("```")
            ))
        }

        return chunks
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
