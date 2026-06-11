//
//  DesignSystem+Metrics.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：设计系统令牌：颜色、排版、间距、动画、图标等可视化常量。
//
import SwiftUI
import CoreGraphics

extension DesignSystem {

    // MARK: - 11. 指标与仪表盘 (Metrics)
    public enum Metrics {
        public static let heroValueSize: CGFloat = Spacing.Metrics.heroValueSize
        public static let subValueSize: CGFloat = Spacing.Metrics.subValueSize
        public static let chartHeight: CGFloat = Spacing.Metrics.chartHeight
        public static let boxHeight: CGFloat = Spacing.Metrics.boxHeight
        public static let indicatorSize: CGFloat = Spacing.Metrics.indicatorSize
        public static let progressHeight: CGFloat = Spacing.Metrics.progressHeight
        public static let boxAspectRatio: CGFloat = Spacing.Metrics.boxAspectRatio
        public static let dashboardValueSize: CGFloat = Spacing.Metrics.dashboardValueSize
        public static let dashboardLabelSize: CGFloat = Spacing.Metrics.dashboardLabelSize
        public static let dashboardRadius: CGFloat = Spacing.Metrics.dashboardRadius
        public static let iconBoxSize: CGFloat = Spacing.Metrics.iconBoxSize
        public static let smallIconBoxSize: CGFloat = Spacing.Metrics.smallIconBoxSize
        public static let largeIconBoxSize: CGFloat = Spacing.Metrics.largeIconBoxSize
        public static let titleFontSize: CGFloat = Spacing.Metrics.titleFontSize
        public static let sourceCardWidth: CGFloat = Spacing.Metrics.sourceCardWidth
        public static let sourceCardHeight: CGFloat = Spacing.Metrics.sourceCardHeight
        public static let titleSmallFontSize: CGFloat = Spacing.Metrics.titleSmallFontSize
        public static let maxBreadcrumbCount: Int = Spacing.Metrics.maxBreadcrumbCount
        public static let maxCollabEditHistory: Int = Spacing.Metrics.maxCollabEditHistory
        public static let maxCollabEditPreviewLength: Int = Spacing.Metrics.maxCollabEditPreviewLength
        public static let maxTagCloudHeight: CGFloat = Spacing.Metrics.maxTagCloudHeight
        public static let knowledgeGrowthDaysLimit: Int = Spacing.Metrics.knowledgeGrowthDaysLimit
        public static let graphCoachMarkThreshold: Int = Spacing.Metrics.graphCoachMarkThreshold
        public static let maxReportPageExportCount: Int = Spacing.Metrics.maxReportPageExportCount
        public static let reportContentPreviewLength: Int = Spacing.Metrics.reportContentPreviewLength
        public static let maxReportContentLineLimit: Int = Spacing.Metrics.maxReportContentLineLimit
        public static let maxDashboardItems: Int = Spacing.Metrics.maxDashboardItems
        public static let maxRecentItems: Int = Spacing.Metrics.maxRecentItems
        public static let A4Width: CGFloat = Spacing.Metrics.A4Width
        public static let A4Height: CGFloat = Spacing.Metrics.A4Height
        public static let emptyStateVerticalPadding: CGFloat = Spacing.Metrics.emptyStateVerticalPadding
        public static let emptyStateIconOpacity: CGFloat = Spacing.Metrics.emptyStateIconOpacity
        public static let sectionSpacing: CGFloat = Spacing.Metrics.sectionSpacing
        
        public static let lockOverlayScaleMultiplier: CGFloat = Spacing.Metrics.lockOverlayScaleMultiplier
        public static let coachMarkScaleMultiplier: CGFloat = Spacing.Metrics.coachMarkScaleMultiplier
        public static let splashQuoteShimmerOffset: CGFloat = Spacing.Metrics.splashQuoteShimmerOffset
        
        public static let commandPaletteHeight: CGFloat = Spacing.Metrics.commandPaletteHeight
        public static let coachMarkIconScale: CGFloat = Spacing.Metrics.coachMarkIconScale
        public static let coachMarkActionHorizontalPadding: CGFloat = Spacing.Metrics.coachMarkActionHorizontalPadding
        public static let coachMarkRadiusOffset: CGFloat = Spacing.Metrics.coachMarkRadiusOffset
        public static let coachMarkShadowRadius: CGFloat = Spacing.Metrics.coachMarkShadowRadius
        public static let coachMarkShadowY: CGFloat = Spacing.Metrics.coachMarkShadowY
        
        public static let welcomeHeroDotWidth: CGFloat = Spacing.Metrics.welcomeHeroDotWidth
        public static let welcomeHeroDotHeight: CGFloat = Spacing.Metrics.welcomeHeroDotHeight
        public static let welcomeHeroCircleSize: CGFloat = Spacing.Metrics.welcomeHeroCircleSize
        public static let welcomeHeroIconSize: CGFloat = Spacing.Metrics.welcomeHeroIconSize
        public static let statCardMinWidth: CGFloat = Spacing.Metrics.statCardMinWidth
        /// macOS/Catalyst 最小窗口宽度 (800px)
        public static let minWindowWidth: CGFloat = Spacing.Metrics.minWindowWidth
        /// macOS/Catalyst 最小窗口高度 (600px)
        public static let minWindowHeight: CGFloat = Spacing.Metrics.minWindowHeight
        /// 笔记本名称最大长度限制 (24字符)
        public static let maxNotebookNameLength: Int = 24
    
        // 自动生成的魔鬼数字补充常量
        public static let customSize150: CGFloat = 150
        public static let customSize1: CGFloat = 1
        public static let customSize56: CGFloat = 56
        public static let customSize80: CGFloat = 80
        public static let customSize36: CGFloat = 36
        public static let customSize300: CGFloat = 300
        public static let customSize96: CGFloat = 96
        public static let customSize54: CGFloat = 54
        public static let customSize40: CGFloat = 40
        public static let customSize140: CGFloat = 140
        public static let customSize180: CGFloat = 180
        public static let customSize500: CGFloat = 500
        public static let customSize400: CGFloat = 400
        public static let customSize220: CGFloat = 220
        public static let customSize14: CGFloat = 14
        public static let customSize22: CGFloat = 22
            public static let customSize100: CGFloat = 100
        public static let customSize375: CGFloat = 375
        public static let customSize50: CGFloat = 50
        public static let customSize768: CGFloat = 768
        public static let customSize1200: CGFloat = 1200
        public static let customSize812: CGFloat = 812
        public static let customSize200: CGFloat = 200
        public static let customSize800: CGFloat = 800
        public static let customSize600: CGFloat = 600
        public static let customSize1024: CGFloat = 1024
    }
}
