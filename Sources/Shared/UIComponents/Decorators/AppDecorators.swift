//
//  AppDecorators.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：属于 Decorators 模块，提供相关的结构体或工具支撑。
//
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
