//
//  DesignSystem+Decorator.swift
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

    // MARK: - 17. 视觉装饰模式 (Decorator)
    public enum Decorator {
        public static let shadowRadiusSmall: CGFloat = Spacing.Decorator.shadowRadiusSmall
        public static let shadowRadiusLarge: CGFloat = Spacing.Decorator.shadowRadiusLarge
        public static let shadowOffsetYSmall: CGFloat = Spacing.Decorator.shadowOffsetYSmall
        public static let shadowOffsetYLarge: CGFloat = Spacing.Decorator.shadowOffsetYLarge
        public static let shimmerPhaseShift: CGFloat = Animations.Decorator.shimmerPhaseShift
        public static let shimmerDuration: Double = Animations.Decorator.shimmerDuration
        public static let shimmerWidthRatio: CGFloat = Animations.Decorator.shimmerWidthRatio
        public static let shimmerEndRatio: CGFloat = Animations.Decorator.shimmerEndRatio
        public static let glowScaleMedium: CGFloat = Spacing.Decorator.glowScaleMedium
        public static let glowScaleLarge: CGFloat = Spacing.Decorator.glowScaleLarge
        public static let glowBlurSmall: CGFloat = Spacing.Decorator.glowBlurSmall
        public static let glowBlurMedium: CGFloat = Spacing.Decorator.glowBlurMedium
        public static let pulseScale: CGFloat = Spacing.Decorator.pulseScale
        public static let pulseDuration: Double = Animations.Decorator.pulseDuration
        public static let accentLineWidth: CGFloat = Spacing.Decorator.accentLineWidth
        public static let badgeMinSize: CGFloat = Spacing.Decorator.badgeMinSize
        public static let desktopSheetMinWidth: CGFloat = Spacing.Decorator.desktopSheetMinWidth
        public static let desktopSheetMinHeight: CGFloat = Spacing.Decorator.desktopSheetMinHeight
    }
}
