//
//  VaultLayout.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：属于 Layouts 模块，提供相关的结构体或工具支撑。
//
import SwiftUI

/// 笔记本网格容器布局
public struct VaultGridLayout<Content: View>: View {
    let content: () -> Content
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: DesignSystem.Vault.gridCardMin, maximum: DesignSystem.Vault.gridCardMax), spacing: DesignSystem.Vault.gridSpacing)
    ]
    
    public var body: some View {
        LazyVGrid(columns: columns, spacing: DesignSystem.giant) {
            content()
        }
        .padding(.horizontal, DesignSystem.Vault.homePadding)
    }
}

/// 笔记本列表容器布局
public struct VaultListLayout<Content: View>: View {
    let content: () -> Content
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
        LazyVStack(spacing: DesignSystem.Vault.listSpacing) {
            content()
        }
        .padding(.horizontal, DesignSystem.Vault.homePadding)
    }
}
