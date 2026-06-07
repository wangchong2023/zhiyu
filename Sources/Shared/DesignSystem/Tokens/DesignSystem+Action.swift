//
//  DesignSystem+Action.swift
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

    // MARK: - 5. 交互模式 (Action)
    public enum Action {
        public static let buttonHeight: CGFloat = Spacing.Action.buttonHeight
        public static let compactButtonHeight: CGFloat = Spacing.Action.compactButtonHeight
        public static let capsuleHeight: CGFloat = Spacing.Action.capsuleHeight
        public static let inputFieldHeight: CGFloat = Spacing.Action.inputFieldHeight
        public static let minTouchTarget: CGFloat = Spacing.Action.minTouchTarget
        public static let inputBarHeight: CGFloat = Spacing.Action.inputBarHeight
        public static let pressScale: CGFloat = Spacing.Action.pressScale
        public static let animationDuration: Double = Spacing.Action.animationDuration
        public static let buttonSpacing: CGFloat = Spacing.Action.buttonSpacing
        public static let iconSize: CGFloat = Spacing.Action.iconSize
        public static let smallIconSize: CGFloat = Spacing.Action.smallIconSize
        public static let largeIconSize: CGFloat = Spacing.Action.largeIconSize
        public static let backButtonWidth: CGFloat = Spacing.Action.backButtonWidth
    }
}
