//
//  NotebookThemeBackgroundView.swift
//  ZhiYu
//
//  Created by Gemini CLI on 2026-05-13.
//  Copyright © 2026 ZhiYu. All rights reserved.
//

import SwiftUI

/// 笔记本主题背景视图
/// 负责根据主题配置渲染笔记本卡片的背景，支持线性渐变和网格渐变（iOS 18+）
struct NotebookThemeBackgroundView: View {
    /// 主题配置
    let config: NotebookThemeConfig
    
    var body: some View {
        ZStack {
            switch config.type {
            case .linear:
                // 渲染线性渐变背景
                LinearGradient(
                    colors: config.colors.map { Color(hex: $0) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .mesh:
                // 如果是 iOS 18.0 或 macOS 15.0 以上版本，可以考虑实现 MeshGradient
                // 目前先回退到线性渐变，直到具体的网格参数被精细化
                if #available(iOS 18.0, macOS 15.0, *) {
                    // TODO: 在后续版本中实现真正的 MeshGradient 渲染逻辑
                    // 需要根据 seed 和 colors 计算网格点位置
                    LinearGradient(
                        colors: config.colors.map { Color(hex: $0) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    LinearGradient(
                        colors: config.colors.map { Color(hex: $0) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
        }
    }
}


