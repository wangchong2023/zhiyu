//
//  TextChunkerProcessor.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：属于 Document 模块，提供相关的结构体或工具支撑。
//
import Foundation

/// 递归分块器 (RAG 核心：语义保真)
/// 负责将长文档拆分为适合向量检索的小块，对标 Karpathy 的 LLM Wiki 切片标准。
struct TextChunkerProcessor: Sendable {

    /// 增强型分块模型
    public struct Chunk: Identifiable {
        public let id = UUID()
        public let text: String       // 分块文本内容
        public let startIndex: Int    // 原始文本起始偏移
        public let anchorPath: String // 标题层级路径 (例如: "核心原理 > 量子力学")
        public let isCode: Bool       // 是否包含完整代码块
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
        separators: ["\n# ", "\n## ", "\n### ", "\n#### ", "\n\n", "\n", "。 ", ". ", " ", ""]
    )

    /**
     * @description: 执行高级语义分块
     * @param {String} text 原始文本
     * @return {[Chunk]} 包含元数据的高质量切片
     */
    func split(text: String, config: Config = TextChunkerProcessor.default) -> [Chunk] {
        var chunks: [Chunk] = []
        let lines = text.components(separatedBy: .newlines)
        
        var currentChunkText = ""
        var currentAnchor = "Root"
        var currentStartIndex = 0
        var isInCodeBlock = false
        
        for line in lines {
            // 1. 状态追踪：代码块保护
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                isInCodeBlock.toggle()
            }
            
            // 2. 标题路径追踪 (Anchor Tracking)
            if !isInCodeBlock && line.hasPrefix("#") {
                currentAnchor = line.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespaces)
            }
            
            let lineWithNewline = line + "\n"
            
            // 3. 贪婪聚合与重叠判定
            if (currentChunkText.count + lineWithNewline.count) > config.chunkSize && !isInCodeBlock {
                // 当前块已满，执行封装
                chunks.append(Chunk(
                    text: currentChunkText.trimmingCharacters(in: .whitespacesAndNewlines),
                    startIndex: currentStartIndex,
                    anchorPath: currentAnchor,
                    isCode: currentChunkText.contains("```")
                ))
                
                // 计算重叠：保留当前块的末尾作为下一个块的开头
                let overlapIndex = currentChunkText.index(currentChunkText.endIndex, offsetBy: -config.chunkOverlap, default: currentChunkText.startIndex)
                currentChunkText = String(currentChunkText[overlapIndex...]) + lineWithNewline
                currentStartIndex += (currentChunkText.count - config.chunkOverlap)
            } else {
                currentChunkText += lineWithNewline
            }
        }
        
        // 补全最后一个块
        if !currentChunkText.isEmpty {
            chunks.append(Chunk(
                text: currentChunkText.trimmingCharacters(in: .whitespacesAndNewlines),
                startIndex: currentStartIndex,
                anchorPath: currentAnchor,
                isCode: currentChunkText.contains("```")
            ))
        }

        return chunks
    }
}

private extension String {
    func index(_ index: String.Index, offsetBy offset: Int, default defaultIndex: String.Index) -> String.Index {
        return self.index(index, offsetBy: offset, limitedBy: self.startIndex) ?? defaultIndex
    }
}
