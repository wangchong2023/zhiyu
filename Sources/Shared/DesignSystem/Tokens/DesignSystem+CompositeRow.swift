//
//  DesignSystem+CompositeRow.swift
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

    // MARK: - 10. 复合行模式 (CompositeRow)
    public enum CompositeRow {
        public static let spacing: CGFloat = Spacing.CompositeRow.spacing
        public static let cornerRadius: CGFloat = Spacing.CompositeRow.cornerRadius
        public static let iconBoxSize: CGFloat = Spacing.CompositeRow.iconBoxSize
        public static let actionAreaWidth: CGFloat = Spacing.CompositeRow.actionAreaWidth
        public static let indicatorWidth: CGFloat = Spacing.CompositeRow.indicatorWidth
    }
}