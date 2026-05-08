// PageType+UI.swift
//
// 作者: Wang Chong
// 功能说明: 为 PageType 及其相关枚举提供表现层支持，将 UI 逻辑（颜色、图标）从模型层剥离至视图层扩展。
// 版本: 1.0
// 修改记录:
//   - 2026-05-07: 初始版本，从 PageType.swift 迁移 UI 属性。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

extension PageType {
    /// 页面类型对应的图标名称
    var icon: String {
        switch self {
        case .entity: return "person.text.rectangle.fill"
        case .concept: return "lightbulb.fill"
        case .source: return "doc.richtext.fill"
        case .comparison: return "arrow.left.arrow.right.circle.fill"
        case .map: return "map.fill"
        case .raw: return "doc.plaintext.fill"
        }
    }
    
    /// 页面类型对应的品牌颜色
    var color: Color {
        switch self {
        case .entity: return .blue
        case .concept: return .purple
        case .source: return .green
        case .comparison: return .orange
        case .map: return .red
        case .raw: return .gray
        }
    }
}

extension PageStatus {
    /// 状态对应的视觉颜色
    var color: Color {
        switch self {
        case .active: return .green
        case .stub: return .yellow
        case .needsUpdate: return .orange
        case .deprecated: return .red
        }
    }
}

extension Confidence {
    /// 可信度对应的视觉颜色
    var color: Color {
        switch self {
        case .high: return .green
        case .medium: return .yellow
        case .low: return .red
        }
    }
}
