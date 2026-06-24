//
//  AuthComponents.swift
//  ZhiYu
//
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：Auth 模块可复用的表单组件 — AuthTextField 与 ThirdPartyButton。
//
import SwiftUI

// MARK: - AuthTextField

/// 认证表单文本输入框组件
struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: icon)
                .foregroundStyle(.appSecondary)
                .frame(width: Spacing.wide)

            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding()
        .background(Color.appCard.opacity(DesignSystem.Opacity.prominent))
        .clipShape(RoundedRectangle(cornerRadius: Spacing.standardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.standardRadius)
                .stroke(Color.appBorder, lineWidth: DesignSystem.borderWidth)
        )
    }
}

// MARK: - ThirdPartyButton

/// 传统第三方登录全宽按钮（保留向后兼容）
struct ThirdPartyButton: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon == "apple_logo" ? DesignSystem.Icons.apple : (icon == "wechat_logo" ? DesignSystem.Icons.message : DesignSystem.Icons.persons))
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.medium)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.standardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.standardRadius)
                    .stroke(Color.appBorder.opacity(DesignSystem.softOpacity), lineWidth: DesignSystem.borderWidth)
            )
        }
        .buttonStyle(.plain)
    }
}
