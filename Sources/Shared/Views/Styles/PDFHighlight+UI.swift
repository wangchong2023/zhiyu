// PDFHighlight+UI.swift
//
// 作者: Wang Chong
// 功能说明: PDFHighlight 模型的 UI 表现层扩展。
// 版本: 1.0
// 修改记录:
//   - 2026-05-13: 初始创建，从 PDFProcessor.swift 剥离 UI 逻辑。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
