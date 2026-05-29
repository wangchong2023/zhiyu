//
//  DesignSystem+CompositeRow.swift
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

    // MARK: - 10. 复合行模式 (CompositeRow)
    public enum CompositeRow {
        public static let spacing: CGFloat = Spacing.CompositeRow.spacing
        public static let cornerRadius: CGFloat = Spacing.CompositeRow.cornerRadius
        public static let iconBoxSize: CGFloat = Spacing.CompositeRow.iconBoxSize
        public static let actionAreaWidth: CGFloat = Spacing.CompositeRow.actionAreaWidth
        public static let indicatorWidth: CGFloat = Spacing.CompositeRow.indicatorWidth
    }
}
