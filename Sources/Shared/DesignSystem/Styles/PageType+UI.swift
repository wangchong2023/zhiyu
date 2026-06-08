//
//  PageType+UI.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：设计系统令牌：颜色、排版、间距、动画、图标等可视化常量。
//
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