//
//  BlurView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 平台适配层
//  核心职责：macOS 平台模糊背景视图，使用 NSVisualEffectView 实现原生毛玻璃效果。
//

#if os(macOS)
import SwiftUI
import AppKit

/// macOS 平台模糊背景视图，封装 NSVisualEffectView
struct BlurView: NSViewRepresentable {

    /// 创建 NSVisualEffectView
    /// - Parameter context: context
    /// - Returns: NSVisualEffectView 实例
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .withinWindow
        view.material = .hudWindow
        view.state = .active
        return view
    }

    /// 更新 NSVisualEffectView
    /// - Parameter nsView: NSVisualEffectView 实例
    /// - Parameter context: context
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
#endif
