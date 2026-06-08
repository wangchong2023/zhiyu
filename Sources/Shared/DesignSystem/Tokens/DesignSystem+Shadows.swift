//
//  DesignSystem+Shadows.swift
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
    
    // MARK: - 19.5 标准阴影令牌 (Shadows)
    public enum Shadows {
        /// 玻璃拟态卡片阴影 (轻微，黑色 5%)
        public static let glass = (color: Colors.Opacity.glassShadowColor, radius: CGFloat(10), x: CGFloat(0), y: CGFloat(5))
        /// 标准浮动卡片阴影 (中等，黑色 6%)
        public static let standard = (color: Colors.shadowColor, radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        /// 深度悬浮阴影 (强烈，用于弹出层或深色背景，黑色 12%)
        public static let deep = (color: Colors.Opacity.deepShadowColor, radius: CGFloat(15), x: CGFloat(0), y: CGFloat(8))
    }
}