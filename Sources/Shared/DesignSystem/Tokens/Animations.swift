// Animations.swift
//
// 作者: Wang Chong
// 功能说明: 本文件定义了智宇 (ZhiYu) 设计系统的原子动效令牌及物理交互参数。
// 遵循工业级动效规范，支持弹性过渡与高性能视觉反馈。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 智宇动效令牌 (Animation Tokens)
/// 包含物理动效常数、弹性参数及标准动画时长。
public enum Animations {
    
    // MARK: - 1. 物理交互参数 (Physical Interaction)
    // MARK: @PR-03: 交互动效参数需经过性能调优以维持高帧率交互
    
    /// 点击按下的缩放比例 (0.97)
    public static let pressScale: CGFloat = 0.97
    /// 悬停时的缩放比例 (1.02)
    public static let hoverScale: CGFloat = 1.02
    
    // MARK: - 2. 动画时长 (Durations)
    
    /// 标准线性动画时长 (0.2s)
    public static let standardDuration: Double = 0.2
    /// 快速动画时长 (0.2s)
    public static let fastDuration: Double = 0.2
    /// 慢速动画时长 (0.5s)
    public static let slowDuration: Double = 0.5
    /// 宽松动画时长 (1.5s)
    public static let looseDuration: Double = 1.5
    
    // MARK: - 3. 弹性动效参数 (Spring Parameters)
    
    /// 弹性动效响应时长 (0.3s)
    public static let springResponse: Double = 0.3
    /// 弹性动效阻尼系数 (0.8)
    public static let springDamping: Double = 0.8
    
    /// 突出弹性动效响应时长 (0.4s)
    public static let prominentSpringResponse: Double = 0.4
    /// 突出弹性动效阻尼系数 (0.8)
    public static let prominentSpringDamping: Double = 0.8
    
    // MARK: - 4. 装饰动效令牌 (Decorator Animation Tokens)
    
    /// 闪烁动画循环时长 (1.5s)
    public static let shimmerDuration: Double = 1.5
    /// 脉冲动效循环时长 (1.2s)
    public static let pulseDuration: Double = 1.2
    /// 脉冲动效缩放倍率 (1.4)
    public static let pulseScale: CGFloat = 1.4
    
    /// 闪烁动画相位偏移
    public static let shimmerPhaseShift: CGFloat = 400
    /// 闪烁光带宽度比例
    public static let shimmerWidthRatio: CGFloat = 0.6
    /// 闪烁动画终止比例
    public static let shimmerEndRatio: CGFloat = 1.6
    /// 中型发光缩放倍率
    public static let glowScaleMedium: CGFloat = 1.3
    /// 大型发光缩放倍率
    public static let glowScaleLarge: CGFloat = 1.8
    
    public struct Interaction {
        public static let pressScale: CGFloat = Animations.pressScale
        public static let hoverScale: CGFloat = Animations.hoverScale
        public static let springResponse: Double = Animations.springResponse
        public static let springDamping: Double = Animations.springDamping
        public static let standardDuration: Double = Animations.standardDuration
        public static let fastDuration: Double = Animations.fastDuration
        public static let slowDuration: Double = Animations.slowDuration
        public static let looseDuration: Double = Animations.looseDuration
        public static let standardDamping: Double = 0.8
        public static let standardAnimation: Animation = .appStandard
        public static let prominentAnimation: Animation = .appProminent
        public static let fastAnimation: Animation = .appFast
    }
    
    public struct Decorator {
        public static let shimmerDuration: Double = Animations.shimmerDuration
        public static let pulseDuration: Double = Animations.pulseDuration
        public static let pulseScale: CGFloat = Animations.pulseScale
        public static let shimmerPhaseShift: CGFloat = Animations.shimmerPhaseShift
        public static let shimmerWidthRatio: CGFloat = Animations.shimmerWidthRatio
        public static let shimmerEndRatio: CGFloat = Animations.shimmerEndRatio
        public static let glowScaleMedium: CGFloat = Animations.glowScaleMedium
        public static let glowScaleLarge: CGFloat = Animations.glowScaleLarge
    }
}

// MARK: - SwiftUI Animation 扩展
extension Animation {
    
    /// 标准弹性动画 (智宇推荐)
    public static var appStandard: Animation {
        .spring(
            response: Animations.springResponse,
            dampingFraction: Animations.springDamping
        )
    }
    
    /// 突出弹性动画
    public static var appProminent: Animation {
        .spring(
            response: Animations.prominentSpringResponse,
            dampingFraction: Animations.prominentSpringDamping
        )
    }
    
    /// 快速淡出动画
    public static var appFast: Animation {
        .easeOut(duration: Animations.fastDuration)
    }
    
    /// 缓慢平滑动画
    public static var appSlow: Animation {
        .easeInOut(duration: Animations.slowDuration)
    }
    
    // 遗留兼容支持
    public static var standardAnimation: Animation { appStandard }
    public static var fastAnimation: Animation { appFast }
}
