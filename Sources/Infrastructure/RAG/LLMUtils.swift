// LLMUtils.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了大语言模型通用工具集（LLMUtils），旨在为 AI 响应处理、JSON 解析及语法清洗提供统一接口。
// 该组件主要承担以下核心任务：
// 1. 结构化 JSON 提取：专门针对 AI 返回的 JSON 列表或对象进行解析，支持自动过滤非 JSON 字符。
// 2. Markdown 语法净化：自动识别并剥离响应中的代码块声明（如 ```json 等），确保数据解析引擎能够获得纯净的 payload。
// 3. 结果提取与转换：从 LLM 标准响应格式中提取核心内容，并提供常用的解析模板。
// 版本: 1.2
// 修改记录:
//   - 2026-05-15: 重命名自 LLMResponseProcessor，整合 Quiz 解析与通用清洗逻辑。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
