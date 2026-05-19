// DesignSystem.swift
//
// 作者: Wang Chong
// 功能说明: [Shared] 智宇 (ZhiYu) 设计系统核心入口。
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
        
        // ── 系统图标符号 (来自 Typography.Icons) ──
        public static let trophy = Typography.Icons.trophy
        public static let tag = Typography.Icons.tag
        public static let tagFill = Typography.Icons.tagFill
        public static let hashtag = Typography.Icons.hashtag
        public static let link = Typography.Icons.link
        public static let sparkles = Typography.Icons.sparkles
        public static let more = Typography.Icons.more
        public static let edit = Typography.Icons.edit
        public static let pencilCircle = Typography.Icons.pencilCircle
        public static let delete = Typography.Icons.delete
        public static let pin = Typography.Icons.pin
        public static let pinFill = "pin.fill"
        public static let unpin = Typography.Icons.unpin
        public static let history = Typography.Icons.history
        public static let refresh = Typography.Icons.refresh
        public static let reset = Typography.Icons.reset
        public static let plus = Typography.Icons.plus
        public static let plusCircle = Typography.Icons.plusCircle
        public static let lock = Typography.Icons.lock
        public static let lockOpen = Typography.Icons.lockOpen
        public static let logout = Typography.Icons.logout
        public static let info = Typography.Icons.info
        public static let check = Typography.Icons.check
        public static let checkCircle = Typography.Icons.checkCircle
        public static let emptyCircle = "circle"
        public static let errorCircle = Typography.Icons.errorCircle
        public static let timer = Typography.Icons.timer
        public static let warning = Typography.Icons.warning
        public static let star = Typography.Icons.star
        public static let dotSeparator = Typography.Icons.dotSeparator
        public static let bullet = Typography.Icons.bullet
        public static let undo = Typography.Icons.undo
        public static let copy = Typography.Icons.copy
        public static let seal = Typography.Icons.seal
        public static let eyeSlash = Typography.Icons.eyeSlash
        public static let eyeSlashOutline = Typography.Icons.eyeSlashOutline
        public static let eye = Typography.Icons.eye
        public static let faceid = Typography.Icons.faceid
        public static let archive = Typography.Icons.archive
        public static let box = Typography.Icons.box
        public static let docRichtext = Typography.Icons.docRichtext
        public static let docBadgePlus = Typography.Icons.docBadgePlus
        public static let pencilClipboard = Typography.Icons.pencilClipboard
        public static let tray = Typography.Icons.tray
        public static let clock = Typography.Icons.clock
        public static let stop = Typography.Icons.stop
        public static let stopRequest = "stop.circle.fill"
        public static let send = Typography.Icons.send
        public static let sendRequest = "paperplane.fill"
        public static let apple = Typography.Icons.apple
        public static let message = Typography.Icons.message
        public static let sidebarToggle = Typography.Icons.sidebarLeft
        public static let settings = Typography.Icons.gearshape
        public static let promptLibrary = "sparkles.rectangle.stack"
        public static let thinking = Typography.Icons.sparkles
        public static let library = "books.vertical.fill"
        public static let arrowRight = Typography.Icons.arrowRight
        public static let arrowLeft = Typography.Icons.arrowLeft
        public static let arrowUpRightSimple = Typography.Icons.arrowUpRightSimple
        public static let arrowUpRightSquare = Typography.Icons.arrowUpRightSquare
        public static let arrowUpRightCircle = Typography.Icons.arrowUpRightCircle
        public static let arrowDownDoc = Typography.Icons.arrowDownDoc
        public static let arrowDownCircle = Typography.Icons.arrowDownCircle
        public static let arrowBranch = Typography.Icons.arrowBranch
        public static let micFill = Typography.Icons.micFill
        public static let micSlashFill = Typography.Icons.micSlashFill
        public static let libraryCircle = "books.vertical.circle.fill"
        public static let booksVerticalFill = Typography.Icons.booksVerticalFill
        public static let stackFill = Typography.Icons.stackFill
        public static let sortUpDown = Typography.Icons.sortUpDown
        public static let gridOutline = Typography.Icons.gridOutline
        public static let xmarkCircle = Typography.Icons.xmarkCircle
        public static let lockShieldFill = Typography.Icons.lockShieldFill
        public static let shieldFill = Typography.Icons.shieldFill
        public static let shieldSlash = Typography.Icons.shieldSlash
        public static let puzzlepieceExtension = Typography.Icons.puzzlepieceExtension
        public static let pluginOutline = Typography.Icons.pluginOutline
        public static let storefront = Typography.Icons.storefront
        public static let brain = Typography.Icons.brain
        public static let keyFill = Typography.Icons.keyFill
        public static let trayFill = Typography.Icons.trayFill
        public static let scope = Typography.Icons.scope
        public static let plusMagnifyingglass = Typography.Icons.plusMagnifyingglass
        public static let minusMagnifyingglass = Typography.Icons.minusMagnifyingglass
        public static let viewfinder = Typography.Icons.viewfinder
        public static let view3d = Typography.Icons.view3d
        public static let fullscreenEnter = Typography.Icons.fullscreenEnter
        public static let fullscreenExit = Typography.Icons.fullscreenExit
        public static let refreshCircle = Typography.Icons.refreshCircle
        public static let refreshCircleFill = Typography.Icons.refreshCircleFill
        public static let chartBarXaxis = Typography.Icons.chartBarXaxis
        public static let arrowTriangleBranch = Typography.Icons.arrowTriangleBranch
        public static let cellularbars = Typography.Icons.cellularbars
        public static let flag = Typography.Icons.flag
        public static let docOnClipboardFill = Typography.Icons.docOnClipboardFill
        public static let boltShieldFill = Typography.Icons.boltShieldFill
        public static let loop = Typography.Icons.arrowTriangle2Circlepath
        public static let exclamationCircleFill = Typography.Icons.exclamationmarkCircleFill
        public static let circle = Typography.Icons.circle
        public static let emptySquare = Typography.Icons.square
        public static let checkSquareFill = Typography.Icons.checkSquareFill
        public static let safari = Typography.Icons.safari
        public static let visionpro = Typography.Icons.visionpro
        public static let cubeTransparent = Typography.Icons.cubeTransparentFill
        public static let handTap = Typography.Icons.handTapFill
        public static let eyeFill = Typography.Icons.eyeFill
        public static let personCropPlus = Typography.Icons.personCropCircleBadgePlus
        public static let filterCircle = Typography.Icons.filterCircle
        public static let line3Horizontal = Typography.Icons.line3Horizontal
        public static let waveform = Typography.Icons.waveform
        public static let waveformCircleFill = Typography.Icons.waveformCircleFill
        public static let documentFill = Typography.Icons.documentFill
        public static let document = Typography.Icons.document
        public static let photoOnRectangle = Typography.Icons.photoOnRectangle
        public static let highlighterFill = Typography.Icons.highlighterFill
        public static let starSquareFill = Typography.Icons.starSquareFill
        public static let docOnClipboard = Typography.Icons.docOnClipboard
        public static let listBulletRectangle = Typography.Icons.listBulletRectangle
        public static let listBulletRectanglePortrait = Typography.Icons.listBulletRectanglePortrait
        public static let trashSlashOutline = Typography.Icons.trashSlashOutline
        public static let trashSlash = Typography.Icons.trashSlash
        public static let pencilLine = Typography.Icons.pencilLine
        public static let pencilOutline = Typography.Icons.pencilOutline
        public static let squareAndPencil = Typography.Icons.squareAndPencil
        public static let quoteOpening = Typography.Icons.quoteOpening
        public static let quoteClosing = Typography.Icons.quoteClosing
        public static let docOnDocFill = Typography.Icons.docOnDocFill
        public static let circleGrid3x3Fill = Typography.Icons.circleGrid3x3Fill
        public static let hexagonGridFill = Typography.Icons.hexagonGridFill

        public static let quoteBubble = Typography.Icons.quoteBubbleFill
        public static let bold = Typography.Icons.bold
        public static let italic = Typography.Icons.italic
        public static let xmark = Typography.Icons.xmark
        public static let personCrop = Typography.Icons.personCropCircle
        public static let personCropFill = Typography.Icons.personCropCircleFill
        public static let back = Typography.Icons.back
        public static let backToHub = Typography.Icons.backCircle
        public static let forward = Typography.Icons.forward
        public static let forwardCircle = Typography.Icons.forwardCircle
        public static let arrowUpRight = Typography.Icons.arrowUpRight
        public static let search = Typography.Icons.search
        public static let command = Typography.Icons.command
        public static let checklist = Typography.Icons.checklist
        public static let up = Typography.Icons.chevronUp
        public static let down = Typography.Icons.chevronDown
        public static let grid = Typography.Icons.grid
        public static let list = Typography.Icons.list
        public static let chevronUpDown = Typography.Icons.chevronUpDown
        
        // ── 硬件与系统 ──
        public static let person = Typography.Icons.person
        public static let personCircle = Typography.Icons.personCircle
        public static let personCheck = Typography.Icons.personCheck
        public static let persons = Typography.Icons.persons
        public static let personsCircle = Typography.Icons.personsCircle
        public static let cpu = Typography.Icons.cpu
        public static let cpuOutline = Typography.Icons.cpuOutline
        public static let bolt = Typography.Icons.bolt
        public static let antenna = Typography.Icons.antenna
        
        // ── 业务/特性专用 ──
        public static let knowledge = Typography.Icons.knowledge
        public static let dashboard = Typography.Icons.dashboard
        public static let pageList = Typography.Icons.pageList
        public static let weeklyInsight = Typography.Icons.weeklyInsight
        public static let healthCheck = Typography.Icons.healthCheck
        public static let plugins = Typography.Icons.plugins
        public static let collaboration = Typography.Icons.collaboration
        public static let collaborationPeers = Typography.Icons.persons // 兼容别名
        public static let broadcast = Typography.Icons.antenna // 兼容别名
        public static let crown = Typography.Icons.crown
        public static let synthesisIcon = Typography.Icons.synthesisIcon
        public static let chatBubble = Typography.Icons.chatBubble
        public static let trayArrowDown = Typography.Icons.trayArrowDown
        public static let importIcon = Typography.Icons.trayArrowDown // 兼容别名
        public static let export = "square.and.arrow.up" // 兼容别名
        public static let ocr = Typography.Icons.ocr
        public static let mic = Typography.Icons.mic
        
        // ── 统计与图表 ──
        public static let chartLine = Typography.Icons.chartLine
        public static let chartPie = Typography.Icons.chartPie
        public static let chartBar = Typography.Icons.chartBar
        public static let network = Typography.Icons.network
        public static let database = Typography.Icons.database
        public static let log = Typography.Icons.log
        
        // ── 知识分类语义化图标 ──
        public static let entity = Typography.Icons.entity
        public static let concept = Typography.Icons.concept
        public static let source = Typography.Icons.source
        public static let comparison = Typography.Icons.comparison
        
        // ── 扩展映射 ──
        public static let photoAlbum = Typography.Icons.photoAlbum
        public static let highlighter = Typography.Icons.highlighter
        public static let wand = Typography.Icons.wand
        public static let aiSummary = Typography.Icons.wand
        public static let aiExtract = Typography.Icons.sealCheck
        public static let mindmap = Typography.Icons.mindmap
        public static let quiz = Typography.Icons.questionCircle
        public static let questionCircle = Typography.Icons.questionCircle
        public static let slides = Typography.Icons.playRectangle
        public static let report = Typography.Icons.weeklyInsight
        public static let infographic = Typography.Icons.chartBarDoc
        public static let lab = Typography.Icons.flask
        public static let expandStub = Typography.Icons.textBadgePlus
        public static let findLinks = Typography.Icons.linkBadgePlus
        public static let sortName = Typography.Icons.sortName
        public static let sortDate = Typography.Icons.calendar
        public static let wordCount = Typography.Icons.textformat
        public static let pushToCloud = Typography.Icons.icloudArrowUp
        public static let pullFromCloud = Typography.Icons.pullFromCloud
        public static let bidirectionalSync = Typography.Icons.icloudSync
        public static let clearCloudData = Typography.Icons.trashICloud
        public static let injectDemoData = Typography.Icons.testtube
        public static let stressTest = Typography.Icons.gauge100
        public static let llmConfig = Typography.Icons.sliderHorizontal
        public static let theme = Typography.Icons.paintbrush
        public static let language = Typography.Icons.globe
        public static let llmSettings = Typography.Icons.brainProfile
        public static let promptLab = Typography.Icons.terminal
        public static let iCloudSync = Typography.Icons.icloud
        public static let operationLog = Typography.Icons.listBulletRectangle
        public static let privacyMode = Typography.Icons.eyeSlash
        public static let developer = Typography.Icons.hammer
        public static let promptWorkshop = Typography.Icons.flaskFill
        public static let macwindowBadgePlus = Typography.Icons.macwindowBadgePlus
        public static let photo = Typography.Icons.photo
        public static let externaldrive = Typography.Icons.externaldrive
        
        // ── 未归类补充 ──
        /// 孤立页面图标 (用于 Lint 孤儿节点)
        public static let orphanPage = "person.fill.questionmark"
        /// 合并操作图标
        public static let merge = "arrow.merge"
        /// 分支操作图标
        public static let branch = "arrow.branch"
        /// 重命名/光标图标
        public static let cursorIbeam = "character.cursor.ibeam"
        /// 空白虚线框 (OnDevice 下载前占位)
        public static let squareDashed = "square.dashed"
        /// 文字气泡
        public static let textBubble = "text.bubble.fill"
        /// 柱状图统计
        public static let chartBarFill = "chart.bar.fill"
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
        public static let welcomeHeaderTopPadding: CGFloat = Spacing.Layout.welcomeHeaderTopPadding
        public static let sidebarOverlayVerticalPadding: CGFloat = Spacing.Layout.sidebarOverlayVerticalPadding
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

    // MARK: - 6. 视觉令牌 (Visual Tokens)
    public enum Opacity {
        public static let ghost: Double = 0.05
        public static let glass: Double = 0.15
        public static let soft: Double = 0.5
        public static let prominent: Double = 0.8
        public static let disabled: Double = 0.4
    }

    public enum Shadow {
        public static let light = (color: Color.black.opacity(0.1), radius: 5.0, x: 0.0, y: 2.0)
        public static let standard = (color: Color.black.opacity(0.15), radius: 10.0, x: 0.0, y: 4.0)
        public static let prominent = (color: Color.appAccent.opacity(0.3), radius: 10.0, x: 0.0, y: 5.0)
    }

    // MARK: - 7. 展示模式 (Gallery)
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
        /// 笔记本名称最大长度限制 (24字符)
        public static let maxNotebookNameLength: Int = 24
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
        
        /// 标准交错动画延迟 (0.2s)
        public static let staggerDelay: Double = Animations.staggerDelay
        
        public static var standard: SwiftUI.Animation { Animations.Interaction.standardAnimation }
        public static var prominent: SwiftUI.Animation { Animations.Interaction.prominentAnimation }
        public static var fast: SwiftUI.Animation { Animations.Interaction.fastAnimation }
        
        /// 启动页动画序列 (Splash)
        public enum Splash {
            public static let quoteDelay: Double = Animations.Splash.quoteDelay
            public static let authorDelay: Double = Animations.Splash.authorDelay
            public static let shimmerDelay: Double = Animations.Splash.shimmerDelay
            public static let welcomeDisplayDelay: Double = Animations.Splash.welcomeDisplayDelay
            public static let autoDismissDelay: Double = Animations.Splash.autoDismissDelay
        }
        
        /// AI 交互节奏
        public enum AI {
            public static let pulseInterval: Double = Animations.AI.pulseInterval
        }
        
        public struct Config {
            public static var prominentSpring: SwiftUI.Animation { Animations.Interaction.prominentAnimation }
        }
    }

    // MARK: - 13.5 全局层级 (ZIndex)
    public enum ZIndex {
        public static let lockOverlay: Double = ZIndexTokens.lockOverlay
        public static let medalPopup: Double = ZIndexTokens.medalPopup
        public static let coachMark: Double = ZIndexTokens.coachMark
        public static let sidebarOverlay: Double = ZIndexTokens.sidebarOverlay
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
    public static let subtleOpacity: Double = Colors.subtleOpacity
    public static let subtleFillOpacity: Double = Colors.subtleFillOpacity
    public static let halfOpacity: Double = Colors.halfOpacity
    public static let fullOpacity: Double = Colors.Opacity.fullOpacity
    public static let disabledOpacity: Double = Colors.Opacity.disabledOpacity
    public static let pressedOpacity: Double = Colors.Opacity.pressedOpacity
    public static let dimmedOpacity: Double = Colors.Opacity.dimmedOpacity
    public static let secondaryOpacity: Double = Colors.Opacity.secondaryOpacity
    public static let coachMarkBackgroundOpacity: Double = Colors.Opacity.coachMarkBackgroundOpacity
    
    public static let surfaceOpacity: Double = Colors.Opacity.surfaceOpacity
    public static let cardOpacity: Double = Colors.Opacity.cardOpacity
    public static let translucentOpacity: Double = Colors.Opacity.translucentOpacity
    public static let softOpacity: Double = Colors.Opacity.softOpacity
    public static let ghostOpacity: Double = Colors.Opacity.ghostOpacity
    
    public static let dividerOpacity: Double = Colors.Opacity.dividerOpacity
    public static let accentStrokeOpacity: Double = Colors.Opacity.accentStrokeOpacity
    
    // MARK: - 19.5 标准阴影令牌 (Shadows)
    public enum Shadows {
        /// 玻璃拟态卡片阴影 (轻微，黑色 5%)
        public static let glass = (color: Colors.Opacity.glassShadowColor, radius: CGFloat(10), x: CGFloat(0), y: CGFloat(5))
        /// 标准浮动卡片阴影 (中等，黑色 6%)
        public static let standard = (color: Colors.shadowColor, radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        /// 深度悬浮阴影 (强烈，用于弹出层或深色背景，黑色 12%)
        public static let deep = (color: Colors.Opacity.deepShadowColor, radius: CGFloat(15), x: CGFloat(0), y: CGFloat(8))
    }
    
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
    #if !os(watchOS)
    public typealias Tooltip = AppTooltip
    #endif
    
    // MARK: - Domain Specific Layout Constants
    public enum Domain {
        public struct About {
            public static let logoSize: CGFloat = 100
        }
        public struct Voice {
            public static let recordButtonSize: CGFloat = 80
            public static let waveScale: CGFloat = 40
        }
        public struct Lint {
            /// 巡检健康圆环图直径
            public static let chartSize: CGFloat = 110
            /// 健康分数超大展示字号 (仅用于分数数字)
            public static let scoreFontSize: CGFloat = 38
            /// 健康检查空状态图标尺寸
            public static let emptyIconSize: CGFloat = 56
        }
        public struct AI {
            public struct Chat {
                public static let pulsingDotSize: CGFloat = 6
                public static let bubbleIconScale: CGFloat = 1.2
                public static let avatarSize: CGFloat = 22
                public static let bubbleCornerRadius: CGFloat = 18
                public static let referencePanelCornerRadius: CGFloat = 6
                /// 气泡区块右侧最小留白 (防止遮挡头像)
                public static let bubbleTrailingPadding: CGFloat = 48
            }
        }
    }
}
