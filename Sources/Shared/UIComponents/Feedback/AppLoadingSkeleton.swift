//
//  AppLoadingSkeleton.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：属于 Feedback 模块，提供相关的结构体或工具支撑。
//
import SwiftUI

/// 骨架屏占位加载组件
/// 包含流光闪烁微动画，能够模拟不同尺寸与结构的排版占位。
public struct AppLoadingSkeleton: View {
    /// 骨架屏类型
    public enum SkeletonType: Sendable {
        /// 单行占位条
        case textRow
        /// 详情段落占位
        case paragraph
        /// 卡片大图块占位
        case cardBlock
    }
    
    /// 当前骨架屏样式
    public let type: SkeletonType
    
    /// 动画透明度控制状态
    @State private var animateOpacity = 0.3
    
    /// 初始化骨架屏加载组件
    /// - Parameter type: 骨架样式，默认为 .textRow
    public init(type: SkeletonType = .textRow) {
        self.type = type
    }
    
    public var body: some View {
        Group {
            switch type {
            case .textRow:
                skeletonRectangle()
                    .frame(height: 16)
                
            case .paragraph:
                VStack(alignment: .leading, spacing: 10) {
                    skeletonRectangle().frame(height: 16).frame(maxWidth: .infinity)
                    skeletonRectangle().frame(height: 16).frame(maxWidth: .infinity)
                    skeletonRectangle().frame(height: 16).frame(width: 200)
                }
                
            case .cardBlock:
                VStack(alignment: .leading, spacing: 12) {
                    skeletonRectangle()
                        .frame(height: 120)
                    HStack(spacing: 8) {
                        skeletonRectangle().frame(width: 40, height: 40).clipShape(Circle())
                        VStack(alignment: .leading, spacing: 6) {
                            skeletonRectangle().frame(height: 14).frame(width: 120)
                            skeletonRectangle().frame(height: 10).frame(width: 80)
                        }
                    }
                }
            }
        }
        .onAppear {
            // 1. 物理挂载后立即执行无限往复的流光透明度插值动画
            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
            ) {
                animateOpacity = 0.8
            }
        }
    }
    
    /// 构建骨架屏基础灰色微动画圆角矩形
    private func skeletonRectangle() -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.secondary.opacity(0.12))
            .opacity(animateOpacity)
    }
}
