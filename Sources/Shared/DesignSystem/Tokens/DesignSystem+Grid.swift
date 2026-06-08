//
//  DesignSystem+Grid.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：设计系统令牌：颜色、排版、间距、动画、图标等可视化常量。
//
import SwiftUI
import CoreGraphics

extension DesignSystem {

    // MARK: - 8. 网格模式 (Grid)
    public enum Grid {
        public static let standardSpacing: CGFloat = Spacing.Grid.standardSpacing
        public static let largeSpacing: CGFloat = Spacing.Grid.largeSpacing
        public static let tightSpacing: CGFloat = Spacing.Grid.tightSpacing
        public static let flowSpacing: CGFloat = Spacing.Grid.flowSpacing
        public static let emptyStateHeight: CGFloat = Spacing.Grid.emptyStateHeight
    }
}