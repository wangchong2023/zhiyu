//
//  DesignSystem+Shadow.swift
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

    public enum Shadow {
        public static let light = (color: Color.black.opacity(0.1), radius: 5.0, x: 0.0, y: 2.0)
        public static let standard = (color: Color.black.opacity(0.15), radius: 10.0, x: 0.0, y: 4.0)
        public static let prominent = (color: Color.appAccent.opacity(0.3), radius: 10.0, x: 0.0, y: 5.0)
    }
}
