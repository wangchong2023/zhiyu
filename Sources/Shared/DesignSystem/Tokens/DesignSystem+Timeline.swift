//
//  DesignSystem+Timeline.swift
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

    // MARK: - 7. 轴线模式 (Timeline)
    public enum Timeline {
        public static let emptyIconSize: CGFloat = Spacing.Timeline.emptyIconSize
        public static let indicatorSize: CGFloat = Spacing.Timeline.indicatorSize
        public static let detailHorizontalPadding: CGFloat = Spacing.Timeline.detailHorizontalPadding
        public static let detailVerticalPadding: CGFloat = Spacing.Timeline.detailVerticalPadding
        public static let indentPadding: CGFloat = Spacing.Timeline.indentPadding
        public static let rowVerticalPadding: CGFloat = Spacing.Timeline.rowVerticalPadding
        public static let iconCircleSize: CGFloat = Spacing.Timeline.iconCircleSize
    }
}