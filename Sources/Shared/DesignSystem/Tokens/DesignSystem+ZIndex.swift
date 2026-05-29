//
//  DesignSystem+ZIndex.swift
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

    // MARK: - 13.5 全局层级 (ZIndex)
    public enum ZIndex {
        public static let lockOverlay: Double = ZIndexTokens.lockOverlay
        public static let medalPopup: Double = ZIndexTokens.medalPopup
        public static let coachMark: Double = ZIndexTokens.coachMark
        public static let sidebarOverlay: Double = ZIndexTokens.sidebarOverlay
    }
}
