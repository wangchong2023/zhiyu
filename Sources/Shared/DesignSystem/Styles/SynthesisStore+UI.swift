//
//  SynthesisStore+UI.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：设计系统令牌：颜色、排版、间距、动画、图标等可视化常量。
//
import SwiftUI

extension SynthesisStore.SynthesisType {
    /// 语义化颜色映射
    var formatColor: Color {
        switch self {
        case .mindmap: return .blue
        case .slides: return .orange
        case .quiz: return .green
        case .report: return .red
        case .infographic: return .purple
        case .expansion: return .indigo
        }
    }
}