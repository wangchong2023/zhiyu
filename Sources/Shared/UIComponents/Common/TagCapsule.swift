//
//  TagCapsule.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：可复用 UI 组件库：编辑器、卡片、加载态、空状态等通用视图。
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
                .background(Color.appAccent.opacity(DesignSystem.Opacity.medium))
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
