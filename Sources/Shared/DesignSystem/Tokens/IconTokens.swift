// IconTokens.swift
//
// 作者: Wang Chong
// 功能说明: [Shared] 共享标准层：设计系统图标与视觉资产强类型令牌 (Icon Tokens)。
// 本文件统一收拢全工程所有高频使用的 Emoji 图标、SFSymbols 图标及备选列表常量，
// 旨在消灭散落在 UI 功能层和基础设施初始化中的硬编码魔鬼字串。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 智宇全局图标与视觉资产令牌 (Icon Tokens)
public enum IconTokens {
    
    // MARK: - 笔记本与知识库默认 Emoji
    
    /// 我的知识库默认 Emoji 图标
    public static let defaultBook: String = "📚"
    
    /// 项目调研默认 Emoji 图标
    public static let defaultResearch: String = "🔍"
    
    /// 缺省容错兜底笔记本 Emoji 图标
    public static let fallbackNotebook: String = "📓"
    
    // MARK: - 笔记本与知识库可选列表
    
    /// 笔记本卡片、列表及创建表单中可选的所有高品质 Emoji 图标数组
    public static let options: [String] = [
        "📓", "📚", "💡", "🧠", "✍️", "🚀", "🎨", "📁", "🌟", "🛠️", "📅", "🎯", "🔥", "🌈", "🧩"
    ]
}
