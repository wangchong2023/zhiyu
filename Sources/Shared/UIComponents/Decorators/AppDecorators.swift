// AppDecorators.swift
//
// 作者: Wang Chong
// 功能说明: 本文件定义了智宇 (ZhiYu) 的视觉装饰组件体系，包括点阵背景与各种视图修饰符。
// 核心职责：
// 1. 提供点阵 (Dot Pattern) 背景渲染组件。
// 2. 封装各种细微的视觉装饰逻辑。
// MARK: [PR-03] 统一视觉装饰规范，增强界面的工业感与细节深度
// 版本: 1.2
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

// MARK: - App Dot Pattern

/// 工业级点阵背景
/// 使用 Canvas 高性能渲染重复的圆点模式，常用于背景装饰。
public struct AppDotPattern: View {
    public var dotColor: Color = .appBorder
    public var spacing: CGFloat = Spacing.wide
    public var dotSize: CGFloat = Spacing.atomic

    public init(dotColor: Color = .appBorder, spacing: CGFloat = Spacing.wide, dotSize: CGFloat = Spacing.atomic) {
        self.dotColor = dotColor
        self.spacing = spacing
        self.dotSize = dotSize
    }

    public var body: some View {
        Canvas { context, size in
            guard size.width > 1 && size.height > 1 else { return }
            let cols = Int(size.width / spacing) + 1
            let rows = Int(size.height / spacing) + 1
            for row in 0..<rows {
                for col in 0..<cols {
                    let x = CGFloat(col) * spacing
                    let y = CGFloat(row) * spacing
                    let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(dotColor.opacity(0.4))
                    )
                }
            }
        }
    }
}
