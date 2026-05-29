//
//  DesignSystem+Chip.swift
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

    // MARK: - 15. 碎片模式 (Chip)
    public enum Chip {
        public static let horizontalPadding: CGFloat = Spacing.Chip.horizontalPadding
        public static let verticalPadding: CGFloat = Spacing.Chip.verticalPadding
        public static let spacing: CGFloat = Spacing.Chip.spacing
        public static let iconSpacing: CGFloat = Spacing.Chip.iconSpacing
        public static let cornerRadius: CGFloat = Spacing.Chip.cornerRadius
    }
}
