//
//  DesignSystem+Radius.swift
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
    
    // MARK: - 2. 原子圆角 (Radius)
    public enum Radius {
        public static let micro: CGFloat = Spacing.microRadius
        public static let small: CGFloat = Spacing.smallRadius
        public static let medium: CGFloat = Spacing.mediumRadius
        public static let card: CGFloat = Spacing.cardRadius
        public static let standard: CGFloat = Spacing.standardRadius
        public static let large: CGFloat = Spacing.largeRadius
        public static let chip: CGFloat = Spacing.chipRadius
    }
}