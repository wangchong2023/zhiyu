//
//  ZIndexTokens.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：设计系统令牌：颜色、排版、间距、动画、图标等可视化常量。
//
import Foundation
import CoreGraphics

/// 智宇全局层级令牌 (Z-Index Tokens)
public enum ZIndexTokens {
    /// 安全锁定层 (100)
    public static let lockOverlay: Double = 100
    /// 奖章奖励弹窗 (200)
    public static let medalPopup: Double = 200
    /// 功能引导覆盖层 (300)
    public static let coachMark: Double = 300
    /// 移动端侧边栏抽屉 (1000)
    public static let sidebarOverlay: Double = 1000
}