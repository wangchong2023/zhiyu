// DesignSystem.swift
//
// 作者: Wang Chong
// 功能说明: 智宇 (ZhiYu) 设计系统核心入口。
// 本文件整合了原子令牌 (Tokens)，为应用提供统一的视觉与交互规范。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 智宇设计系统 (ZhiYu Design System)
/// 统一管理应用内的间距、圆角、排版、颜色与动效规范。
public enum DesignSystem {
    
    // MARK: - 1. 原子间距 (Spacing)
    public static let atomic: CGFloat = Spacing.atomic
    public static let tiny: CGFloat = Spacing.tiny
    public static let small: CGFloat = Spacing.small
    public static let medium: CGFloat = Spacing.medium
    public static let standardPadding: CGFloat = Spacing.standardPadding
    public static let large: CGFloat = Spacing.large
    public static let wide: CGFloat = Spacing.wide
    public static let giant: CGFloat = Spacing.giant
    public static let huge: CGFloat = Spacing.huge
    public static let inputBarHeight: CGFloat = Spacing.inputBarHeight
    public static let loosePadding: CGFloat = Spacing.loosePadding
    public static let widePadding: CGFloat = Spacing.widePadding
    public static let tightPadding: CGFloat = Spacing.tightPadding
    
    // MARK: - 2. 原子圆角 (Radius)
    public enum Radius {
        public static let micro: CGFloat = Spacing.microRadius
        public static let small: CGFloat = Spacing.smallRadius
        public static let medium: CGFloat = Spacing.mediumRadius
        public static let card: CGFloat = Spacing.cardRadius
        public static let standard: CGFloat = Spacing.standardRadius
        public static let large: CGFloat = Spacing.largeRadius
        public static let chip: CGFloat = Spacing.chipRadius
    }
    
    // 兼容原 DesignSystem.microRadius 等命名
    public static let microRadius: CGFloat = Spacing.microRadius
    public static let smallRadius: CGFloat = Spacing.smallRadius
    public static let mediumRadius: CGFloat = Spacing.mediumRadius
    public static let cardRadius: CGFloat = Spacing.cardRadius
    public static let standardRadius: CGFloat = Spacing.standardRadius
    public static let largeRadius: CGFloat = Spacing.largeRadius
    public static let chipRadius: CGFloat = Spacing.chipRadius
    
    // MARK: - 3. 图标体系 (Iconography)
    public enum Icons {
        public static let tiny: CGFloat = Spacing.iconTiny
        public static let small: CGFloat = Spacing.iconSmall
        public static let medium: CGFloat = Spacing.iconMedium
        public static let large: CGFloat = Spacing.iconLarge
        public static let huge: CGFloat = Spacing.iconHuge
        public static let display: CGFloat = Spacing.iconDisplay
        
        // 系统图标符号 (来自 Typography.Icons)
        public static let trophy = Typography.Icons.trophy
        public static let tag = Typography.Icons.tag
        public static let hashtag = Typography.Icons.hashtag
        public static let link = Typography.Icons.link
        public static let sparkles = Typography.Icons.sparkles
        public static let more = Typography.Icons.more
        public static let edit = Typography.Icons.edit
        public static let delete = Typography.Icons.delete
        public static let pin = Typography.Icons.pin
        public static let unpin = Typography.Icons.unpin
        public static let history = Typography.Icons.history
        public static let refresh = Typography.Icons.refresh
        public static let reset = Typography.Icons.reset
        public static let plus = Typography.Icons.plus
        public static let lock = Typography.Icons.lock
        public static let lockOpen = Typography.Icons.lockOpen
        
        public static let entity = Typography.Icons.entity
        public static let concept = Typography.Icons.concept
        public static let source = Typography.Icons.source
        public static let comparison = Typography.Icons.comparison
    }
    
    // 兼容原 DesignSystem.iconTiny 等命名
    public static let iconTiny: CGFloat = Spacing.iconTiny
    public static let iconSmall: CGFloat = Spacing.iconSmall
    public static let iconMedium: CGFloat = Spacing.iconMedium
    public static let iconLarge: CGFloat = Spacing.iconLarge
    public static let iconHuge: CGFloat = Spacing.iconHuge
    public static let iconDisplay: CGFloat = Spacing.iconDisplay
    public static let smallIconSize: CGFloat = Spacing.smallIconSize
    public static let titleIconSize: CGFloat = Spacing.titleIconSize
    public static let largeIconSize: CGFloat = Spacing.largeIconSize
    public static let microIconSize: CGFloat = Spacing.microIconSize
    public static let captionIconSize: CGFloat = Spacing.captionIconSize

    // MARK: - 4. 布局模式 (Layout)
    public enum Layout {
        public static let maxReadWidth: CGFloat = Spacing.Layout.maxReadWidth
        public static let cardContentPadding: CGFloat = Spacing.Layout.cardContentPadding
        public static let tightPadding: CGFloat = Spacing.Layout.tightPadding
        public static let headerVerticalPadding: CGFloat = Spacing.Layout.headerVerticalPadding
        public static let columnSpacing: CGFloat = Spacing.Layout.columnSpacing
        public static let listRowSpacing: CGFloat = Spacing.Layout.listRowSpacing
    }

    // MARK: - 5. 交互模式 (Action)
    public enum Action {
        public static let buttonHeight: CGFloat = Spacing.Action.buttonHeight
        public static let compactButtonHeight: CGFloat = Spacing.Action.compactButtonHeight
        public static let capsuleHeight: CGFloat = Spacing.Action.capsuleHeight
        public static let inputFieldHeight: CGFloat = Spacing.Action.inputFieldHeight
        public static let minTouchTarget: CGFloat = Spacing.Action.minTouchTarget
        public static let inputBarHeight: CGFloat = Spacing.Action.inputBarHeight
        public static let pressScale: CGFloat = Spacing.Action.pressScale
        public static let animationDuration: Double = Spacing.Action.animationDuration
        public static let buttonSpacing: CGFloat = Spacing.Action.buttonSpacing
        public static let iconSize: CGFloat = Spacing.Action.iconSize
        public static let smallIconSize: CGFloat = Spacing.Action.smallIconSize
        public static let largeIconSize: CGFloat = Spacing.Action.largeIconSize
        public static let backButtonWidth: CGFloat = Spacing.Action.backButtonWidth
    }

    // MARK: - 6. 展示模式 (Gallery)
    public enum Gallery {
        public static let itemSize: CGFloat = Spacing.Gallery.itemSize
        public static let iconSize: CGFloat = Spacing.Gallery.iconSize
        public static let badgeOffset: CGFloat = Spacing.Gallery.badgeOffset
        public static let itemRadius: CGFloat = Spacing.Gallery.itemRadius
        public static let displayIconSize: CGFloat = Spacing.Gallery.displayIconSize
        public static let splashIconSize: CGFloat = Spacing.Gallery.splashIconSize
        public static let blurRadius: CGFloat = Spacing.Gallery.blurRadius
        public static let mainIconSize: CGFloat = Spacing.Gallery.mainIconSize
        public static let callToActionWidth: CGFloat = Spacing.Gallery.callToActionWidth
        public static let callToActionHeight: CGFloat = Spacing.Gallery.callToActionHeight
        public static let containerRadius: CGFloat = Spacing.Gallery.containerRadius
        public static let containerPadding: CGFloat = Spacing.Gallery.containerPadding
        public static let showcaseRadius: CGFloat = Spacing.Gallery.showcaseRadius
        public static let hoverScale: CGFloat = Spacing.Gallery.hoverScale
        public static let splashLogoBottomPadding: CGFloat = Spacing.Gallery.splashLogoBottomPadding
        public static let splashButtonBottomPadding: CGFloat = Spacing.Gallery.splashButtonBottomPadding
    }

    // MARK: - 7. 轴线模式 (Timeline)
    public enum Timeline {
        public static let emptyIconSize: CGFloat = Spacing.Timeline.emptyIconSize
        public static let indicatorSize: CGFloat = Spacing.Timeline.indicatorSize
        public static let detailHorizontalPadding: CGFloat = Spacing.Timeline.detailHorizontalPadding
        public static let detailVerticalPadding: CGFloat = Spacing.Timeline.detailVerticalPadding
        public static let indentPadding: CGFloat = Spacing.Timeline.indentPadding
        public static let rowVerticalPadding: CGFloat = Spacing.Timeline.rowVerticalPadding
        public static let iconCircleSize: CGFloat = Spacing.Timeline.iconCircleSize
    }

    // MARK: - 8. 网格模式 (Grid)
    public enum Grid {
        public static let standardSpacing: CGFloat = Spacing.Grid.standardSpacing
        public static let largeSpacing: CGFloat = Spacing.Grid.largeSpacing
        public static let tightSpacing: CGFloat = Spacing.Grid.tightSpacing
        public static let flowSpacing: CGFloat = Spacing.Grid.flowSpacing
        public static let emptyStateHeight: CGFloat = Spacing.Grid.emptyStateHeight
    }

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

    // MARK: - 10. 复合行模式 (CompositeRow)
    public enum CompositeRow {
        public static let spacing: CGFloat = Spacing.CompositeRow.spacing
        public static let cornerRadius: CGFloat = Spacing.CompositeRow.cornerRadius
        public static let iconBoxSize: CGFloat = Spacing.CompositeRow.iconBoxSize
        public static let actionAreaWidth: CGFloat = Spacing.CompositeRow.actionAreaWidth
        public static let indicatorWidth: CGFloat = Spacing.CompositeRow.indicatorWidth
    }

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
    }

    // MARK: - 12. 任务规范 (Task)
    public enum Task {
        public static let rowSpacing: CGFloat = Spacing.Task.rowSpacing
        public static let rowVerticalPadding: CGFloat = Spacing.Task.rowVerticalPadding
        public static let iconBoxSize: CGFloat = Spacing.Task.iconBoxSize
        public static let statusIndicatorSize: CGFloat = Spacing.Task.statusIndicatorSize
        public static let badgeSize: CGFloat = Spacing.Task.badgeSize
        public static let progressWidth: CGFloat = Spacing.Task.progressWidth
        public static let dashboardSpacing: CGFloat = Spacing.Task.dashboardSpacing
        public static let dashboardPadding: CGFloat = Spacing.Task.dashboardPadding
        public static let dashboardRadius: CGFloat = Spacing.Task.dashboardRadius
    }

    // MARK: - 13. 动效令牌 (Animation)
    public enum Animation {
        public static let springResponse: Double = Animations.Interaction.springResponse
        public static let springDamping: Double = Animations.Interaction.springDamping
        public static let pressScale: CGFloat = Animations.Interaction.pressScale
        public static let hoverScale: CGFloat = Animations.Interaction.hoverScale
        public static let standardDuration: Double = Animations.Interaction.standardDuration
        public static let looseDuration: Double = Animations.Interaction.looseDuration
        public static let fastDuration: Double = Animations.Interaction.fastDuration
        public static let slowDuration: Double = Animations.Interaction.slowDuration
        public static let standardDamping: Double = Animations.Interaction.standardDamping
        
        public static var standard: SwiftUI.Animation { Animations.Interaction.standardAnimation }
        public static var prominent: SwiftUI.Animation { Animations.Interaction.prominentAnimation }
        public static var fast: SwiftUI.Animation { Animations.Interaction.fastAnimation }
        
        /// 启动页动画序列 (Splash)
        public enum Splash {
            public static let quoteDelay: Double = Animations.Splash.quoteDelay
            public static let authorDelay: Double = Animations.Splash.authorDelay
            public static let shimmerDelay: Double = Animations.Splash.shimmerDelay
            public static let autoDismissDelay: Double = Animations.Splash.autoDismissDelay
        }
        
        public struct Config {
            public static var prominentSpring: SwiftUI.Animation { Animations.Interaction.prominentAnimation }
        }
    }

    // MARK: - 13.5 全局层级 (ZIndex)
    public enum ZIndex {
        public static let lockOverlay: Double = ZhiYu_DesignSystem.ZIndex.lockOverlay
        public static let medalPopup: Double = ZhiYu_DesignSystem.ZIndex.medalPopup
        public static let coachMark: Double = ZhiYu_DesignSystem.ZIndex.coachMark
        public static let sidebarOverlay: Double = ZhiYu_DesignSystem.ZIndex.sidebarOverlay
    }

    // MARK: - 14. 列表模式 (List)
    public enum List {
        public static let rowVerticalPadding: CGFloat = Spacing.List.rowVerticalPadding
        public static let rowHorizontalPadding: CGFloat = Spacing.List.rowHorizontalPadding
        public static let rowSpacing: CGFloat = Spacing.List.rowSpacing
        public static let rowRadius: CGFloat = Spacing.List.rowRadius
    }

    // MARK: - 15. 碎片模式 (Chip)
    public enum Chip {
        public static let horizontalPadding: CGFloat = Spacing.Chip.horizontalPadding
        public static let verticalPadding: CGFloat = Spacing.Chip.verticalPadding
        public static let spacing: CGFloat = Spacing.Chip.spacing
        public static let iconSpacing: CGFloat = Spacing.Chip.iconSpacing
        public static let cornerRadius: CGFloat = Spacing.Chip.cornerRadius
    }

    // MARK: - 16. 侧边栏模式 (Sidebar)
    public enum Sidebar {
        public static let rowSpacing: CGFloat = Spacing.Sidebar.rowSpacing
        public static let rowRadius: CGFloat = Spacing.Sidebar.rowRadius
        public static let rowVerticalPadding: CGFloat = Spacing.Sidebar.rowVerticalPadding
        public static let iconBoxSize: CGFloat = Spacing.Sidebar.iconBoxSize
        public static let iconFrameWidth: CGFloat = Spacing.Sidebar.iconFrameWidth
        public static let badgePadding: CGFloat = Spacing.Sidebar.badgePadding
        public static let vaultShadowRadius: CGFloat = Spacing.Sidebar.vaultShadowRadius
        public static let vaultShadowY: CGFloat = Spacing.Sidebar.vaultShadowY
        public static let width: CGFloat = Spacing.Sidebar.width
    }

    // MARK: - 16.5 笔记本枢纽模式 (Vault)
    public enum Vault {
        public static let gridCardMin: CGFloat = Spacing.Vault.gridCardMin
        public static let gridCardMax: CGFloat = Spacing.Vault.gridCardMax
        public static let gridSpacing: CGFloat = Spacing.Vault.gridSpacing
        public static let listSpacing: CGFloat = Spacing.Vault.listSpacing
        public static let cardHeight: CGFloat = Spacing.Vault.cardHeight
        public static let coverHeight: CGFloat = Spacing.Vault.coverHeight
        public static let listCoverSize: CGFloat = Spacing.Vault.listCoverSize
        public static let homePadding: CGFloat = Spacing.Vault.homePadding
        public static let homeVerticalPadding: CGFloat = Spacing.Vault.homeVerticalPadding
    }

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

    // MARK: - 18. 排版规范 (Typography)
    public typealias HeadingLevel = Typography.HeadingLevel
    public static let microFontSize: CGFloat = Typography.microFontSize
    public static let captionFontSize: CGFloat = Typography.captionFontSize
    public static let caption2FontSize: CGFloat = Typography.caption2FontSize
    public static let subheadlineFontSize: CGFloat = Typography.subheadlineFontSize
    public static let bodyFontSize: CGFloat = Typography.bodyFontSize
    public static let standardFontSize: CGFloat = Typography.standardFontSize
    public static let headlineFontSize: CGFloat = Typography.headlineFontSize
    public static let titleFontSize: CGFloat = Typography.titleFontSize
    public static let title2FontSize: CGFloat = Typography.HeadingLevel.h2.size
    public static let displayFontSize: CGFloat = Typography.displayFontSize
    public static var captionFont: Font { Typography.captionFont }
    public static var caption2Font: Font { Typography.caption2Font }
    public static var secondaryFont: Font { Typography.secondaryFont }
    public static var subheadlineFont: Font { Typography.secondaryFont }
    public static var titleFont: Font { Typography.titleFont }

    // MARK: - 19. 视觉风格常数 (Styling)
    public static let borderWidth: CGFloat = Spacing.borderWidth
    public static let shadowRadius: CGFloat = Spacing.shadowRadius
    public static let shadowY: CGFloat = Spacing.shadowY
    public static let shadowOpacity: Double = Spacing.shadowOpacity
    public static let shadowColor = Colors.Opacity.shadowColor
    public static let glassOpacity: Double = Colors.Opacity.glassOpacity
    public static let subtleOpacity: Double = Colors.Opacity.subtleOpacity
    public static let subtleFillOpacity: Double = Colors.subtleFillOpacity
    public static let fullOpacity: Double = Colors.Opacity.fullOpacity
    public static let disabledOpacity: Double = Colors.Opacity.disabledOpacity
    public static let pressedOpacity: Double = Colors.Opacity.pressedOpacity
    public static let dimmedOpacity: Double = Colors.Opacity.dimmedOpacity
    public static let secondaryOpacity: Double = Colors.Opacity.secondaryOpacity
    public static let coachMarkBackgroundOpacity: Double = Colors.Opacity.coachMarkBackgroundOpacity
    
    public static let surfaceOpacity: Double = Colors.Opacity.surfaceOpacity
    public static let translucentOpacity: Double = Colors.Opacity.translucentOpacity
    public static let softOpacity: Double = Colors.Opacity.softOpacity
    public static let ghostOpacity: Double = Colors.Opacity.ghostOpacity
    
    public static let dividerOpacity: Double = Colors.Opacity.dividerOpacity
    public static let accentStrokeOpacity: Double = Colors.Opacity.accentStrokeOpacity
    
    // MARK: - 20. 容器颜色 (Container Colors)
    public static var containerBackground: Color { Color.appCard }
    public static var containerBorder: Color { Color.appBorder }
    public static var containerMaterial: Color { Color.appCard } 

    // MARK: - 21. 动效常数 (Legacy Animation Bridge)
    public static var standardAnimation: SwiftUI.Animation { Animations.Interaction.standardAnimation }
    public static var fastAnimation: SwiftUI.Animation { Animations.Interaction.fastAnimation }
    
    // MARK: - 21. 组件兼容性别名 (Component Aliases)
    public typealias AppSection<Content: View> = StandardSection<Content>
    public typealias Card<Content: View> = AppCard<Content>
    public typealias BorderedCard<Content: View> = AppBorderedCard<Content>
    public typealias GlassCard<Content: View> = AppGlassCard<Content>
    public typealias PrimaryButton = AppPrimaryButton
    public typealias CapsuleButton = AppCapsuleButton
    public typealias TextField = AppTextField
    public typealias TagField = AppTagField
    public typealias MonospacedEditor = AppMonospacedEditor
    public typealias IconChip = AppIconChip
    public typealias Badge = AppBadge
    public typealias ScrollableChips<Data: RandomAccessCollection, Content: View> = AppScrollableChips<Data, Content> where Data.Element: Hashable
    public typealias SectionHeader = AppSectionHeader
    public typealias LabeledRow = AppLabeledRow
    public typealias StepRow = AppStepRow
    public typealias Divider = AppDivider
    public typealias AccentLine = AppAccentLine
    public typealias PulseDot = AppPulseDot
    public typealias Glow = AppGlow
    public typealias Skeleton = AppSkeleton
    public typealias SkeletonBox = AppSkeleton
    public typealias DotPattern = AppDotPattern
    public typealias IconBox = AppIconBox
    
    public typealias EmptyState = AppEmptyState
    public typealias LoadingOverlay = AppLoadingOverlay
    public typealias Toast = AppToast
    public typealias Tooltip = AppTooltip
}
