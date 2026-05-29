//
//  DesignSystem+Graph.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：属于 Tokens 模块，提供相关的结构体或工具支撑。
//
import SwiftUI
import CoreGraphics

extension DesignSystem {

    // MARK: - 9. 图谱模式 (Graph)
    public enum Graph {
        public static let nodeSize: CGFloat = Spacing.Graph.nodeSize
        public static let selectedNodeSize: CGFloat = Spacing.Graph.selectedNodeSize
        public static let nodeSizeReference: CGFloat = Spacing.Graph.nodeSizeReference
        public static let centralNodeSize: CGFloat = Spacing.Graph.centralNodeSize
        public static let linkWidth: CGFloat = Spacing.Graph.linkWidth
        public static let forceStrength: CGFloat = Spacing.Graph.forceStrength
        public static let minScale: CGFloat = Spacing.Graph.minScale
        public static let maxScale: CGFloat = Spacing.Graph.maxScale
        public static let tightPadding: CGFloat = Spacing.Graph.tightPadding
        public static let toolbarPaddingTrailing: CGFloat = Spacing.Graph.toolbarPaddingTrailing
        public static let toolbarPaddingBottomExpanded: CGFloat = Spacing.Graph.toolbarPaddingBottomExpanded
        public static let toolbarPaddingBottomDefault: CGFloat = Spacing.Graph.toolbarPaddingBottomDefault
        public static let layoutPadding: CGFloat = Spacing.Graph.layoutPadding
        public static let minLayoutDimension: CGFloat = Spacing.Graph.minLayoutDimension
        public static let highlightedLineWidth: CGFloat = Spacing.Graph.highlightedLineWidth
        public static let emptyIconSize: CGFloat = Spacing.Graph.emptyIconSize
        
        public enum ThreeD {
            public static let baseNodeSize: CGFloat = Spacing.Graph.ThreeD.baseNodeSize
            public static let minNodeSize: CGFloat = Spacing.Graph.ThreeD.minNodeSize
            public static let maxNodeSize: CGFloat = Spacing.Graph.ThreeD.maxNodeSize
            public static let nodeLinkWeight: Double = Spacing.Graph.ThreeD.nodeLinkWeight
            public static let labelOffset: Float = Spacing.Graph.ThreeD.labelOffset
            public static let labelScale: Float = Spacing.Graph.ThreeD.labelScale
            public static let edgeRadius: CGFloat = Spacing.Graph.ThreeD.edgeRadius
            public static let edgeRadiusHighlighted: CGFloat = Spacing.Graph.ThreeD.edgeRadiusHighlighted
            public static let starRadius: CGFloat = Spacing.Graph.ThreeD.starRadius
            public static let starFieldRadius: Float = Spacing.Graph.ThreeD.starFieldRadius
        }
    }
}
