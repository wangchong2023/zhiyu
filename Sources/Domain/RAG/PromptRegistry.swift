// PromptRegistry.swift
//
// 作者: Wang Chong
// 功能说明: [L1.5] 领域中心层：统一提示词资产注册表。
// 将原本硬编码在逻辑代码中的 Prompt 模板进行资产化管理，支持多语言动态映射与云端同步预留。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 提示词资产注册表
public enum PromptRegistry {
    
    // MARK: - RAG 摄入管道
    
    public enum Ingest {
        /// 生成全局摘要的提示词
        public static func summary(content: String) -> String {
            "请为以下内容生成一段 200 字以内的专业摘要，直接输出摘要内容：\n\n\(content)"
        }
        
        /// 针对父块生成反向提问的提示词
        public static func reverseQA(content: String) -> String {
            "针对以下文本片段，生成 3 个用户可能会提出的核心问题。要求：问题必须专业、简练，每行一个问题。直接输出问题：\n\n\(content)"
        }
    }
    
    // MARK: - 语义链接与重构
    
    public enum Structure {
        /// 发现潜在链接的提示词 (基于现有标题)
        public static func discoverLinks(content: String, existingTitles: [String]) -> String {
            let titles = existingTitles.joined(separator: ", ")
            return "以下是一篇笔记内容和现有的知识库标题列表。请分析内容，识别其中可以链接到现有标题的关键词。仅返回一个 JSON 数组。\n\n标题列表：\(titles)\n\n内容：\(content)"
        }
    }
}
