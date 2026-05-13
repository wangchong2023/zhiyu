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

// MARK: - Color Extension

extension Color {
    /// 从十六进制字符串创建颜色
    /// - Parameter hex: 十六进制字符串（支持 RGB, RGBA, RRGGBB, RRGGBBAA 格式）
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
