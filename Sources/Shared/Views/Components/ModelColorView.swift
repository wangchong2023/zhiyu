// ModelColorView.swift
//
// 作者: Wang Chong
// 功能说明: 本文件定义了 Color 转换扩展，用于将模型层定义的颜色名称（String）转换为视图层可用的 SwiftUI.Color。
// 日期: 2026-05-07
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

extension Color {
    /// 从模型层的颜色名称字符串转换为 SwiftUI.Color
    /// - Parameter name: 颜色名称（如 "green", "red" 等）
    /// - Returns: 对应的 SwiftUI.Color，默认为 .gray
    static func fromModelColorName(_ name: String) -> Color {
        switch name {
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
