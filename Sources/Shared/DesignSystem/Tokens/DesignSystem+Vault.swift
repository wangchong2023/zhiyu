//
//  DesignSystem+Vault.swift
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

    // MARK: - 16.5 笔记本枢纽模式 (Vault)
    public enum Vault {
        public static let gridCardMin: CGFloat = Spacing.Vault.gridCardMin
        public static let gridCardMax: CGFloat = Spacing.Vault.gridCardMax
        public static let gridSpacing: CGFloat = Spacing.Vault.gridSpacing
        public static let listSpacing: CGFloat = Spacing.Vault.listSpacing
        public static let cardHeight: CGFloat = Spacing.Vault.cardHeight
        public static let coverHeight: CGFloat = Spacing.Vault.coverHeight
        public static let listCoverSize: CGFloat = Spacing.Vault.listCoverSize
        public static let homePadding: CGFloat = Spacing.Vault.homePadding
        public static let homeVerticalPadding: CGFloat = Spacing.Vault.homeVerticalPadding
    }
}
