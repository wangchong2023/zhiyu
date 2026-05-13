// FlowLayout.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了自动换行的流式布局容器，适用于标签云、芯片列表及令牌输入框。
// 核心职责：
// 1. 实现 Swift 6 兼容的 Layout 协议。
// 2. 根据容器宽度自动排列子视图，支持自定义间距。
// MARK: [PR-03] 高性能流式布局算法，优化高密度标签渲染性能
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 自动换行布局容器
/// 适用于标签云、芯片列表及令牌输入框等需要动态排列的场景。
public struct FlowLayout: Layout {
    // MARK: - Properties
    
    /// 元素间的间距
    public var spacing: CGFloat = Spacing.small

    // MARK: - Initialization
    
    public init(spacing: CGFloat = Spacing.small) {
        self.spacing = spacing
    }

    // MARK: - Layout Implementation
    
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), 
                proposal: .unspecified
            )
        }
    }

    // MARK: - Private Methods
    
    /// 计算子视图的排列位置
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            // 检查是否需要换行
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (CGSize(width: maxX, height: currentY + rowHeight), positions)
    }
}
