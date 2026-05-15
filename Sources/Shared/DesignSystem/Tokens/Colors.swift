// Colors.swift
//
// 作者: Wang Chong
// 功能说明: 本文件定义了智宇 (ZhiYu) 设计系统的核心语义颜色、十六进制逻辑及透明度令牌。
// 适配全平台亮暗模式，确保视觉一致性与可访问性。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// 智宇颜色令牌 (Color Tokens)
/// 包含全局语义颜色、透明度分级及环境色扩展。
public enum Colors {
    
    // MARK: - 1. 透明度令牌 (Opacity Tokens)
    
    /// 玻璃拟态透明度 (0.15)
    public static let glassOpacity: Double = 0.15
    /// 较淡的透明度 (0.7)
    public static let subtleOpacity: Double = 0.7
    /// 完全不透明度 (1.0)
    public static let fullOpacity: Double = 1.0
    /// 禁用状态透明度 (0.3)
    public static let disabledOpacity: Double = 0.3
    /// 按下状态透明度 (0.9)
    public static let pressedOpacity: Double = 0.9
    /// 暗淡/背景化状态透明度 (0.2)
    public static let dimmedOpacity: Double = 0.2
    /// 次要状态透明度 (0.8)
    public static let secondaryOpacity: Double = 0.8
    /// 中等透明度 (0.5)
    public static let halfOpacity: Double = 0.5
    /// 标准阴影透明度 (0.1)
    public static let shadowOpacity: Double = 0.1
    /// 功能引导背景透明度 (0.6)
    public static let coachMarkBackgroundOpacity: Double = 0.6
    
    /// 较浅的填充透明度 (0.1)，常用于标签背景
    public static let subtleFillOpacity: Double = 0.1
    
    /// 表面层透明度 (0.8)，常用于卡片叠加
    public static let surfaceOpacity: Double = 0.8
    /// 半透层透明度 (0.6)
    public static let translucentOpacity: Double = 0.6
    /// 软透层透明度 (0.4)
    public static let softOpacity: Double = 0.4
    /// 幽灵层透明度 (0.01)，用于交互热区
    public static let ghostOpacity: Double = 0.01
    
    /// 分割线透明度 (0.5)
    public static let dividerOpacity: Double = 0.5
    /// 强调描边透明度 (0.3)
    public static let accentStrokeOpacity: Double = 0.3
    /// 卡片背景基础透明度 (0.7)
    public static let cardOpacity: Double = 0.7
    
    // MARK: - 2. 预设容器颜色
    
    public struct Opacity {
        public static let glassOpacity: Double = Colors.glassOpacity
        public static let subtleOpacity: Double = Colors.subtleOpacity
        public static let fullOpacity: Double = Colors.fullOpacity
        public static let disabledOpacity: Double = Colors.disabledOpacity
        public static let pressedOpacity: Double = Colors.pressedOpacity
        public static let dimmedOpacity: Double = Colors.dimmedOpacity
        public static let secondaryOpacity: Double = Colors.secondaryOpacity
        public static let halfOpacity: Double = Colors.halfOpacity
        public static let shadowOpacity: Double = Colors.shadowOpacity
        public static let coachMarkBackgroundOpacity: Double = Colors.coachMarkBackgroundOpacity
        public static let subtleFillOpacity: Double = Colors.subtleFillOpacity
        
        public static let surfaceOpacity: Double = Colors.surfaceOpacity
        public static let translucentOpacity: Double = Colors.translucentOpacity
        public static let softOpacity: Double = Colors.softOpacity
        public static let ghostOpacity: Double = Colors.ghostOpacity
        public static let cardOpacity: Double = Colors.cardOpacity
        
        public static let dividerOpacity: Double = Colors.dividerOpacity
        public static let accentStrokeOpacity: Double = Colors.accentStrokeOpacity
        
        public static var shadowColor: Color { Colors.shadowColor }
        public static var glassShadowColor: Color { Color.black.opacity(0.05) }
        public static var deepShadowColor: Color { Color.black.opacity(0.12) }
    }
    
    /// 标准容器背景色
    public static var containerBackground: Color { Color.appCard }
    /// 标准容器边框色
    public static var containerBorder: Color { Color.appBorder }
    /// 标准阴影颜色
    public static var shadowColor: Color { Color.black.opacity(0.06) }
}

// MARK: - Color 扩展 (Semantic Colors)
extension Color {
    
    /// 跨平台支持的亮暗模式适配初始化器
    public init(light: Color, dark: Color) {
        #if canImport(UIKit) && !os(watchOS)
        self.init(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #else
        self.init(light) 
        #endif
    }
    
    // MARK: - 核心语义颜色
    // MARK: @LR-01: 适配全平台多语言环境下的视觉对比度
    // MARK: @PR-03: 语义化颜色规范，支持高性能亮暗模式切换
    
    public static var appBackground: Color { Color(light: Color(hex: "f5f5fa"), dark: Color(hex: "1a1b2e")) }
    public static var appCard: Color { Color(light: Color(hex: "ffffff"), dark: Color(hex: "252640")) }
    public static var appText: Color { Color(light: Color(hex: "1a1a2e"), dark: Color(hex: "e8e8f0")) }
    public static var appSecondary: Color { Color(light: Color(hex: "6b6b87"), dark: Color(hex: "ababc7")) }
    public static var appBorder: Color { Color(light: Color(hex: "ebebf2"), dark: Color(hex: "303142")) }
    
    /// 主题强调色 (通过 ThemeManager 获取，确保在主线程访问)
    public static var appAccent: Color {
        #if os(watchOS)
        return .blue // watchOS 暂不支持复杂的 ThemeManager 逻辑
        #else
        return MainActor.assumeIsolated { ThemeManager.shared.accentColor }
        #endif
    }
    
    /// 玻璃拟态高亮色/光泽色
    public static var appGloss: Color { Color(light: Color.white, dark: Color.white.opacity(0.6)) }
    
    // MARK: - 知识分类语义颜色
    
    public static var appSource: Color { .blue }
    public static var appConcept: Color { .purple }
    public static var appEntity: Color { .orange }
    public static var appMap: Color { .indigo }
    public static var appComparison: Color { .teal }

    // MARK: - 十六进制初始化逻辑
    
    /// 十六进制颜色初始化 (支持 6 位或 8 位)
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        let mask: UInt64 = 0xFF
        let maxRGB: Double = 255.0
        
        let shift24: UInt64 = 24
        let shift16: UInt64 = 16
        let shift8: UInt64 = 8
        
        switch hex.count {
        case 6: // RGB (24-bit)
            (a, r, g, b) = (UInt64(maxRGB), int >> shift16, int >> shift8 & mask, int & mask)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> shift24, int >> shift16 & mask, int >> shift8 & mask, int & mask)
        default:
            (a, r, g, b) = (UInt64(maxRGB), 0, 122, UInt64(maxRGB))
        }
        
        self.init(
            .sRGB,
            red: Double(r) / maxRGB,
            green: Double(g) / maxRGB,
            blue: Double(b) / maxRGB,
            opacity: Double(a) / maxRGB
        )
    }
}

// MARK: - ShapeStyle 扩展
extension ShapeStyle where Self == Color {
    public static var appAccent: Color { .appAccent }
    public static var appText: Color { .appText }
    public static var appSecondary: Color { .appSecondary }
    public static var appBorder: Color { .appBorder }
    public static var appCard: Color { .appCard }
    public static var appBackground: Color { .appBackground }
    public static var appSource: Color { .appSource }
    public static var appConcept: Color { .appConcept }
    public static var appEntity: Color { .appEntity }
    public static var appMap: Color { .appMap }
    public static var appComparison: Color { .appComparison }
    public static var appGloss: Color { .appGloss }
}

// MARK: - Environment 扩展
public struct AppAccentColorKey: EnvironmentKey {
    public static let defaultValue: Color = .blue
}

extension EnvironmentValues {
    /// 全局强调色环境变量
    public var appAccentColor: Color {
        get { self[AppAccentColorKey.self] }
        set { self[AppAccentColorKey.self] = newValue }
    }
}
