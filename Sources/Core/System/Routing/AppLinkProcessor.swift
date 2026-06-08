//
//  AppLinkProcessor.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0.5] 系统集成层
//  核心职责：深度链接与通用链接解析，将外部 URL 映射为内部 AppRoute。
//
import Foundation

/// 知识库链接处理器：负责处理 [[applinks]] 的解析与管理
struct AppLinkProcessor {

    /// 从 Markdown 文本中提取所有 App-link 的目标标题
    /// - Parameter content: 原始 Markdown 内容
    /// - Returns: 提取到的标题列表（已去重）
    static func extractOutgoingLinks(from content: String) -> [String] {
        let pattern = "\\[\\[([^\\]]+)\\]\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsContent = content as NSString
        let matches = regex.matches(in: content, range: NSRange(location: 0, length: nsContent.length))

        // 使用 Set 去重
        let links = matches.compactMap { match -> String? in
            guard match.numberOfRanges > 1 else { return nil }
            return nsContent.substring(with: match.range(at: 1))
        }

        return Array(Set(links)).sorted()
    }
}