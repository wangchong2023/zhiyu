//
//  PromptRegistry.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：属于 RAG 模块，提供相关的结构体或工具支撑。
//
import Foundation

/// 提示词资产注册表
public enum PromptRegistry {
    
    // MARK: - RAG 摄入管道
    
    public enum Ingest {
        /// 生成全局摘要的提示词
        /// - Parameter content: 需要生成摘要的源文本内容
        /// - Returns: 组装好的摘要生成提示词
        public static func summary(content: String) -> String {
            "\(L10n.AI.Prompt.summaryPrefix)\n\n\(content)"
        }
        
        /// 针对父块生成反向提问的提示词
        /// - Parameter content: 源文本内容
        /// - Returns: 组装好的反向提问提示词
        public static func reverseQA(content: String) -> String {
            "\(L10n.AI.Prompt.reverseQAPrefix)\n\n\(content)"
        }
    }
    
    // MARK: - 语义链接与重构
    
    public enum Structure {
        /// 发现潜在链接的提示词 (基于现有标题)
        /// - Parameters:
        ///   - content: 笔记的实际内容
        ///   - existingTitles: 知识库中已有的标题列表
        /// - Returns: 组装好的链接发现提示词
        public static func discoverLinks(content: String, existingTitles: [String]) -> String {
            let titles = existingTitles.joined(separator: ", ")
            return "\(L10n.AI.Prompt.discoverLinksPrefix1)\(titles)\(L10n.AI.Prompt.discoverLinksPrefix2)\(content)"
        }
    }
}
