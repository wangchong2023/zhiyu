//
//  PDFHighlight+UI.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：属于 Styles 模块，提供相关的结构体或工具支撑。
//
import SwiftUI

extension PDFHighlight {
    /// 语义化颜色映射
    var highlightColor: Color {
        switch color {
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "pink": return .pink
        case "purple": return .purple
        default: return .yellow
        }
    }
}
