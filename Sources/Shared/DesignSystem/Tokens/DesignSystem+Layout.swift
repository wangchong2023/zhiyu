//
//  DesignSystem+Layout.swift
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

    // MARK: - 4. 布局模式 (Layout)
    public enum Layout {
        public static let maxReadWidth: CGFloat = Spacing.Layout.maxReadWidth
        public static let cardContentPadding: CGFloat = Spacing.Layout.cardContentPadding
        public static let tightPadding: CGFloat = Spacing.Layout.tightPadding
        public static let headerVerticalPadding: CGFloat = Spacing.Layout.headerVerticalPadding
        public static let columnSpacing: CGFloat = Spacing.Layout.columnSpacing
        public static let listRowSpacing: CGFloat = Spacing.Layout.listRowSpacing
        public static let welcomeHeaderTopPadding: CGFloat = Spacing.Layout.welcomeHeaderTopPadding
        public static let sidebarOverlayVerticalPadding: CGFloat = Spacing.Layout.sidebarOverlayVerticalPadding
    }
}
