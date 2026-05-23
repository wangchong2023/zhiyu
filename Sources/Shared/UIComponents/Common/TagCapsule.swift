//
//  TagCapsule.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：属于 Common 模块，提供相关的结构体或工具支撑。
//
import SwiftUI

/// 知识标签胶囊组件
/// 提供一致的标签视觉样式，支持点击交互与删除操作
struct TagCapsule: View {
    let tag: String
    let count: Int
    
    var body: some View {
        HStack(spacing: DesignSystem.tiny) {
            Image(systemName: DesignSystem.Icons.tagFill)
                .font(.caption2)
            Text(tag)
                .font(.subheadline.weight(.medium))
            Text("\(count)")
                .font(.caption2)
                .padding(.horizontal, DesignSystem.tightPadding)
                .padding(.vertical, DesignSystem.atomic)
                .background(Color.appAccent.opacity(0.2))
                .clipShape(Capsule())
        }
        .padding(.horizontal, DesignSystem.medium)
        .padding(.vertical, DesignSystem.small)
        .background(Color.appCard)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .foregroundStyle(.appText)
    }
}
