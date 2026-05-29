//
//  DesignSystem+Opacity.swift
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

    // MARK: - 6. 视觉令牌 (Visual Tokens)
    public enum Opacity {
        public static let ghost: Double = 0.05
        public static let glass: Double = 0.15
        public static let soft: Double = 0.5
        public static let prominent: Double = 0.8
        public static let disabled: Double = 0.4
    }
}
