//
//  ReadabilityModifiers.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：可复用 UI 组件库：编辑器、卡片、加载态、空状态等通用视图。
//
import SwiftUI

// MARK: - Readable Content Width Modifier
/// iPad 大屏幕下约束内容最大宽度（680pt），居中显示
/// iPhone 或紧凑宽度下保持全宽
struct ReadableContentWidth: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// 最大内容宽度
    private let maxWidth: CGFloat = 680

    /// 是否在 iPad/大屏幕启用宽度约束
    private var isEnabled: Bool {
        horizontalSizeClass == .regular
    }

    /// 视图主体
    /// - Parameter content: content
    /// - Returns: 返回值
    func body(content: Content) -> some View {
        if isEnabled {
            content
                .frame(maxWidth: maxWidth, alignment: .center)
        } else {
            content
        }
    }
}

// MARK: - Convenience Extension
extension View {
    /// 包装内容在大屏幕下限制宽度为 680pt 并居中
    func readableContentWidth() -> some View {
        modifier(ReadableContentWidth())
    }
}