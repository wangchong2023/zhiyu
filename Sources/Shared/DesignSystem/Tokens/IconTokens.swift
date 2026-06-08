//
//  IconTokens.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：设计系统令牌：颜色、排版、间距、动画、图标等可视化常量。
//
import Foundation

/// 智宇全局图标与视觉资产令牌 (Icon Tokens)
public enum IconTokens {
    
    // MARK: - 笔记本与知识库默认 Emoji

    /// 我的知识库默认 Emoji 图标
    public static let defaultBook: String = "📚"

    /// 项目调研默认 Emoji 图标
    public static let defaultResearch: String = "🔬"

    /// 缺省容错兜底笔记本 Emoji 图标
    public static let fallbackNotebook: String = "📓"

    // MARK: - 笔记本与知识库可选列表

    /// 笔记本卡片、列表及创建表单中可选的所有高品质 Emoji 图标数组
    public static let options: [String] = [
        "📚", "📖", "📝", "📓", "📔", "📕", "📗", "📘", "📙", "🔬", "🧪", "💡", "🎯", "🚀", "⭐️"
    ]
}
