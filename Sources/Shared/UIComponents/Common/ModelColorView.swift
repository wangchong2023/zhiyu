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
    /// 颜色名称到 SwiftUI.Color 的映射表（集中管理以降低圈复杂度）
    private static let colorNameMap: [String: Color] = [
        "entity": .appEntity, "concept": .appConcept, "source": .appSource,
        "map": .appMap, "comparison": .appComparison,
        "green": .green, "blue": .blue, "red": .red, "orange": .orange,
        "purple": .purple, "yellow": .yellow, "teal": .teal, "indigo": .indigo,
        "pink": .pink, "gray": .gray
    ]

    /// 从模型层的颜色名称字符串转换为 SwiftUI.Color
    static func fromModelColorName(_ name: String) -> Color {
        colorNameMap[name] ?? .gray
    }
}