//
//  AnimatedSection.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：可复用 UI 组件库：编辑器、卡片、加载态、空状态等通用视图。
//
import SwiftUI

/// 带动画的展开/收起区块容器
/// 当状态发生变化时，自动应用平滑的转场动画。
public struct AnimatedSection<Content: View>: View {
    // MARK: - Properties
    
    /// 是否展开
    public let isExpanded: Bool
    /// 内容闭包
    @ViewBuilder public let content: () -> Content

    // MARK: - Initialization
    
    public init(isExpanded: Bool, @ViewBuilder content: @escaping () -> Content) {
        self.isExpanded = isExpanded
        self.content = content
    }

    // MARK: - Body
    
    public var body: some View {
        if isExpanded {
            content()
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}
