// View+Conditional.swift
//
// 作者: Wang Chong
// 功能说明: SwiftUI View 扩展工具类：提供条件渲染与平台适配辅助
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

extension View {
    /// 对视图应用变换逻辑 (用于链式调用中的条件分支或复杂组装)
    @ViewBuilder
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
