//
//  DesignSystem+Task.swift
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

    // MARK: - 12. 任务规范 (Task)
    public enum Task {
        public static let rowSpacing: CGFloat = Spacing.Task.rowSpacing
        public static let rowVerticalPadding: CGFloat = Spacing.Task.rowVerticalPadding
        public static let iconBoxSize: CGFloat = Spacing.Task.iconBoxSize
        public static let statusIndicatorSize: CGFloat = Spacing.Task.statusIndicatorSize
        public static let badgeSize: CGFloat = Spacing.Task.badgeSize
        public static let progressWidth: CGFloat = Spacing.Task.progressWidth
        public static let dashboardSpacing: CGFloat = Spacing.Task.dashboardSpacing
        public static let dashboardPadding: CGFloat = Spacing.Task.dashboardPadding
        public static let dashboardRadius: CGFloat = Spacing.Task.dashboardRadius
    }
}