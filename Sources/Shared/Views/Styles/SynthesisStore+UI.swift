// SynthesisStore+UI.swift
//
// 作者: Wang Chong
// 功能说明: SynthesisStore.SynthesisType 的 UI 表现层扩展。
// 版本: 1.0
// 修改记录:
//   - 2026-05-13: 初始创建，剥离 Color 依赖。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
