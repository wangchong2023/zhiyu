//
//  DesignSystem+List.swift
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

    // MARK: - 14. 列表模式 (List)
    public enum List {
        public static let rowVerticalPadding: CGFloat = Spacing.List.rowVerticalPadding
        public static let rowHorizontalPadding: CGFloat = Spacing.List.rowHorizontalPadding
        public static let rowSpacing: CGFloat = Spacing.List.rowSpacing
        public static let rowRadius: CGFloat = Spacing.List.rowRadius
    }
}
