// ButtonStyles.swift
//
// 作者: Wang Chong
// 功能说明: 本文件定义了应用内通用的按钮样式，确保交互动效的一致性与物理感。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 适用于卡片类按钮的标准缩放与透明度交互样式
struct AppCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? DesignSystem.Animation.pressScale : 1.0)
            .opacity(configuration.isPressed ? DesignSystem.pressedOpacity : DesignSystem.fullOpacity)
            .animation(.easeInOut(duration: DesignSystem.Animation.standardDuration / 2), value: configuration.isPressed)
    }
}
