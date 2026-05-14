// ZIndex.swift
//
// 作者: Wang Chong
// 功能说明: 本文件定义了智宇 (ZhiYu) 设计系统的全局层级令牌。
// 统一管理弹窗、覆盖层及抽屉等视图的 Z-Index 顺序。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
