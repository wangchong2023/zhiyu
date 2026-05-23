//
//  LLMUtils.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：属于 RAG 模块，提供相关的结构体或工具支撑。
//
import Foundation

/// 全局共享的 LLM 工具集
enum LLMUtils {
    /// 解析 LLM 输出中的 JSON 字符串数组，自动剥离 Markdown 代码块。
    static func parseJSONArray(_ text: String) -> [String] {
        let cleaned = stripMarkdown(text)
        if let data = cleaned.data(using: .utf8),
           let array = try? JSONDecoder().decode([String].self, from: data) {
            return array
        }
        return []
    }

    /// 解析 Smart Ingest 结果
    static func parseSmartIngest(_ text: String) -> SmartIngestResult? {
        let cleaned = stripMarkdown(text)
        guard let data = cleaned.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(SmartIngestResult.self, from: data)
    }

    /// 解析重构建议
    static func parseRefactorSuggestions(_ text: String) -> [RefactorSuggestion] {
        let cleaned = stripMarkdown(text)
        guard let data = cleaned.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([RefactorSuggestion].self, from: data)) ?? []
    }

    /// 从 LLM 标准响应字典中提取内容文本
    static func extractContent(from response: [String: Any]) -> String? {
        guard let choices = response["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            return nil
        }
        return content
    }

    /// 剥离 Markdown 语法标记（如 ```json 等）并修剪空白。
    static func stripMarkdown(_ text: String) -> String {
        text.replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
