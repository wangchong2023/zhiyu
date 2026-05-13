// VaultLayout.swift
//
// 作者: Wang Chong
// 功能说明: 笔记本模块特有的布局模板，解决业务界面直接硬编码的布局技术债。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
