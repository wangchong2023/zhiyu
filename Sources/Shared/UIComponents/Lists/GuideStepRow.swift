// GuideStepRow.swift
//
// 作者: Wang Chong
// 功能说明: 本文件定义了引导步骤行组件，用于引导页面展示分步操作说明。
// MARK: [PR-03] 统一引导步骤规范，优化新用户上手路径的视觉指引
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 引导步骤行组件
/// 提供带数字序号的渐变圆圈和描述文本。
public struct GuideStepRow: View {
    // MARK: - Properties
    
    public let number: Int
    public let text: String
    public let icon: String

    // MARK: - Initialization
    
    public init(number: Int, text: String, icon: String) {
        self.number = number
        self.text = text
        self.icon = icon
    }

    // MARK: - Body
    
    public var body: some View {
        HStack(spacing: Spacing.medium + Spacing.atomic * 2) { // 14
            // 带数字序号的渐变圆
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.appAccent, .appAccent.opacity(Colors.secondaryOpacity)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: Spacing.largeIconSize, height: Spacing.largeIconSize) // 32
                    .shadow(
                        color: .appAccent.opacity(Colors.disabledOpacity), 
                        radius: Spacing.shadowRadius / 2.5, 
                        x: 0, 
                        y: Spacing.shadowY / 2
                    )

                Text("\(number)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.appText)

            Spacer()
        }
    }
}
