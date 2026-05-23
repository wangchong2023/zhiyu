//
//  GuideStepRow.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：属于 Lists 模块，提供相关的结构体或工具支撑。
//
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
