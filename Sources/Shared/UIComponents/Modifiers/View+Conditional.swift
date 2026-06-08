//
//  View+Conditional.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：可复用 UI 组件库：编辑器、卡片、加载态、空状态等通用视图。
//
import SwiftUI

extension View {
    /// 对视图应用变换逻辑 (用于链式调用中的条件分支或复杂组装)
    @ViewBuilder

    /// 应用
    /// - Returns: 返回值
    func apply<Content: View>(@ViewBuilder _ transform: (Self) -> Content) -> Content {
        transform(self)
    }
    
    /// 应用设计系统标准阴影
    func appStandardShadow() -> some View {
        let shadow = DesignSystem.Shadows.standard
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    /// 应用设计系统玻璃拟态阴影
    func appGlassShadow() -> some View {
        let shadow = DesignSystem.Shadows.glass
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    /// 应用设计系统深度悬浮阴影
    func appDeepShadow() -> some View {
        let shadow = DesignSystem.Shadows.deep
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}