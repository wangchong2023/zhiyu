//
//  ModelColorView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：构建 ModelColor 界面的 UI 视图层组件。
//
import SwiftUI

extension Color {
    /// 从模型层的颜色名称字符串转换为 SwiftUI.Color
    /// - Parameter name: 颜色名称（如 "green", "red" 等）
    /// - Returns: 对应的 SwiftUI.Color，默认为 .gray
    static func fromModelColorName(_ name: String) -> Color {
        switch name {
        // 语义化名称映射（对应 AppUI 知识分类颜色）
        case "entity": return .appEntity
        case "concept": return .appConcept
        case "source": return .appSource
        case "map": return .appMap
        case "comparison": return .appComparison
        
        // 基础颜色映射
        case "green": return .green
        case "blue": return .blue
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "yellow": return .yellow
        case "teal": return .teal
        case "indigo": return .indigo
        case "pink": return .pink
        case "gray": return .gray
        default: return .gray
        }
    }
}
