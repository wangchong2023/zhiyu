//
//  QuizProcessor.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：属于 Synthesis 模块，提供相关的结构体或工具支撑。
//
import Foundation

/// 专门处理知识测验数据的解析、转换与清洗
enum QuizProcessor {

    struct QuizModelShell: Codable {
        let title: String
        let questions: [QuestionShell]
        struct QuestionShell: Codable {
            let id: Int?
            let text: String
            let options: [String]
            let answer: Int
            let explanation: String?
        }
    }

    /// 检查文本是否可以解析为标准的交互式测验模型
    static func canDecodeAsQuizModel(_ text: String) -> Bool {
        let cleaned = LLMUtils.stripMarkdown(text)
        guard let data = cleaned.data(using: .utf8) else { return false }
        return (try? JSONDecoder().decode(QuizModelShell.self, from: data)) != nil
    }

    /// 尝试将 JSON 测验转换为 Markdown 格式
    static func convertJSONToMarkdown(_ text: String) -> String? {
        let cleaned = LLMUtils.stripMarkdown(text)
        guard let data = cleaned.data(using: .utf8) else { return nil }

        struct QuizJSON: Codable {
            let title: String?
            let questions: [QuestionJSON]
        }
        struct QuestionJSON: Codable {
            let id: Int?
            let text: String
            let options: [String]
            let answer: AnyCodable?
            let explanation: String?
        }

        enum AnyCodable: Codable {
            case int(Int)
            case string(String)
            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let i = try? container.decode(Int.self) { self = .int(i) } else if let s = try? container.decode(String.self) { self = .string(s) } else { throw DecodingError.dataCorruptedError(in: container, debugDescription: "Not int or string") }
            }
            func encode(to encoder: Encoder) throws {}
            var stringValue: String {
                switch self {
                case .int(let i): return "\(i)"
                case .string(let s): return s
                }
            }
        }

        guard let quiz = try? JSONDecoder().decode(QuizJSON.self, from: data) else { return nil }

        var md = "# \(quiz.title ?? L10n.Quiz.title)\n\n"
        for (index, q) in quiz.questions.enumerated() {
            md += "## \(index + 1). \(q.text)\n\n"
            for opt in q.options {
                md += "* \(opt)\n"
            }
            md += "\n<details>\n<summary>\(L10n.Quiz.showAnswer)</summary>\n\n"
            if let ans = q.answer {
                md += "**\(L10n.Quiz.correctAnswer)：** \(ans.stringValue)\n\n"
            }
            if let exp = q.explanation {
                md += "**\(L10n.Quiz.explanation)：** \(exp)\n"
            }
            md += "\n</details>\n\n"
        }

        return md
    }
}
