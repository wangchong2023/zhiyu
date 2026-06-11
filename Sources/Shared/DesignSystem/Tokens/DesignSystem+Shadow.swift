//
//  DesignSystem+Shadow.swift
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

    public enum Shadow {
        public static let light = (color: Color.black.opacity(DesignSystem.Opacity.subtle), radius: 5.0, x: 0.0, y: 2.0)
        public static let standard = (color: Color.black.opacity(DesignSystem.Opacity.glass), radius: 10.0, x: 0.0, y: 4.0)
        public static let prominent = (color: Color.appAccent.opacity(DesignSystem.Opacity.shadow), radius: 10.0, x: 0.0, y: 5.0)
    }
}
