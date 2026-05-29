//
//  DesignSystem+Radius.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：属于 Tokens 模块，提供相关的结构体或工具支撑。
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
