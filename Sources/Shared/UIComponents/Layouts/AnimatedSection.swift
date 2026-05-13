// AnimatedSection.swift
//
// 作者: Wang Chong
// 功能说明: 本文件定义了带动画的条件展开区块，用于构建具有流畅过渡效果的 UI 结构。
// 核心职责：
// 1. 提供基于布尔状态的视图展开/收起容器。
// 2. 封装标准的位移与透明度组合转场效果。
// MARK: [PR-03] 统一动态布局过渡规范，提升界面的流畅性与交互质感
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
