//
//  DesignSystem+ZIndex.swift
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

    // MARK: - 13.5 全局层级 (ZIndex)
    public enum ZIndex {
        public static let lockOverlay: Double = ZIndexTokens.lockOverlay
        public static let medalPopup: Double = ZIndexTokens.medalPopup
        public static let coachMark: Double = ZIndexTokens.coachMark
        public static let sidebarOverlay: Double = ZIndexTokens.sidebarOverlay
    }
}