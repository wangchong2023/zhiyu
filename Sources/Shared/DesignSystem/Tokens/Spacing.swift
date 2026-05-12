// Spacing.swift
//
// 作者: Wang Chong
// 功能说明: 本文件定义了智宇 (ZhiYu) 设计系统的原子间距、圆角及布局常数。
// 遵循工业级 UI 规范，支持全平台统一布局。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import CoreGraphics

/// 智宇原子间距令牌 (Spacing Tokens)
/// 包含基础步进间距、圆角规范及各组件的布局指标。
public enum Spacing {
    
    // MARK: - 1. 原子间距 (Atomic Spacing)
    // MARK: @PR-03: 布局常数直接影响渲染管线的布局计算与滚动性能
    
    /// 最小步进常数 (2px)
    public static let atomic: CGFloat = 2
    /// 极小间距 (4px)
    public static let tiny: CGFloat = 4
    /// 小型间距 (8px)
    public static let small: CGFloat = 8
    /// 中型间距 (12px)
    public static let medium: CGFloat = 12
    /// 标准页面内边距 (16px)
    public static let standardPadding: CGFloat = 16
    /// 大型间距 (16px)
    public static let large: CGFloat = 16
    /// 宽型间距 (20px)
    public static let wide: CGFloat = 20
    /// 巨型间距 (24px)
    public static let giant: CGFloat = 24
    /// 极大型间距 (32px)
    public static let huge: CGFloat = 32
    
    /// 底部输入栏基准高度 (54px)
    public static let inputBarHeight: CGFloat = 54
    /// 宽松内边距 (24px)
    public static let loosePadding: CGFloat = 24
    /// 宽幅内边距 (20px)
    public static let widePadding: CGFloat = 20
    /// 紧凑内边距 (8px)
    public static let tightPadding: CGFloat = 8
    
    // MARK: - 2. 原子圆角 (Atomic Radius)
    // MARK: @PR-03: 圆角半径需遵循 GPU 优化准则以维持 60 FPS
    
    /// 微型圆角 (4px)
    public static let microRadius: CGFloat = 4
    /// 小型圆角 (8px)
    public static let smallRadius: CGFloat = 8
    /// 中型圆角 (10px)
    public static let mediumRadius: CGFloat = 10
    /// 卡片通用圆角 (12px)
    public static let cardRadius: CGFloat = 12
    /// 标准圆角 (12px)
    public static let standardRadius: CGFloat = 12
    /// 大型圆角 (16px)
    public static let largeRadius: CGFloat = 16
    /// 胶囊型圆角 (20px)
    public static let chipRadius: CGFloat = 20
    
    // MARK: - 3. 图标尺寸 (Icon Sizes)
    
    /// 极小图标尺寸 (12px)
    public static let iconTiny: CGFloat = 12
    /// 小型图标尺寸 (16px)
    public static let iconSmall: CGFloat = 16
    /// 中型图标尺寸 (20px)
    public static let iconMedium: CGFloat = 20
    /// 大型图标尺寸 (24px)
    public static let iconLarge: CGFloat = 24
    /// 巨大图标尺寸 (32px)
    public static let iconHuge: CGFloat = 32
    /// 展示型图标尺寸 (48px)
    public static let iconDisplay: CGFloat = 48
    
    // MARK: - 4. 布局模式 (Layout Patterns)
    
    /// 全局布局规范
    public struct Layout {
        /// 内容最大阅读宽度 (针对阅读体验优化的 800px)
        public static let maxReadWidth: CGFloat = 800
        /// 卡 cardContentPadding (16px)
        public static let cardContentPadding: CGFloat = 16
        /// 紧凑型边距 (8px)
        public static let tightPadding: CGFloat = 8
        /// 页面顶部标题栏纵向边距 (12px)
        public static let headerVerticalPadding: CGFloat = 12
        /// 栏目间距 (16px)
        public static let columnSpacing: CGFloat = 16
        /// 列表行间距 (8px)
        public static let listRowSpacing: CGFloat = 8
    }
    
    /// 按钮与输入控件的交互规范
    public struct Action {
        /// 标准按钮高度
        public static let buttonHeight: CGFloat = 44
        /// 紧凑型按钮高度
        public static let compactButtonHeight: CGFloat = 32
        /// 胶囊标签高度
        public static let capsuleHeight: CGFloat = 28
        /// 标准输入框高度
        public static let inputFieldHeight: CGFloat = 50
        /// 最小可点击目标尺寸 (Apple 建议 44pt)
        public static let minTouchTarget: CGFloat = 44
        /// 输入栏标准高度
        public static let inputBarHeight: CGFloat = 44
        /// 按钮组间距
        public static let buttonSpacing: CGFloat = 12
        /// 按钮内部图标尺寸
        public static let iconSize: CGFloat = 16
        /// 小型按钮图标尺寸
        public static let smallIconSize: CGFloat = 14
        /// 大型操作图标尺寸
        public static let largeIconSize: CGFloat = 24
        /// 返回按钮点击区域宽度
        public static let backButtonWidth: CGFloat = 40
    }
    
    /// 展示模式规范
    public struct Gallery {
        public static let itemSize: CGFloat = 100
        public static let iconSize: CGFloat = 40
        public static let badgeOffset: CGFloat = 28
        public static let itemRadius: CGFloat = 16
        public static let displayIconSize: CGFloat = 120
        public static let splashIconSize: CGFloat = 80
        public static let blurRadius: CGFloat = 40
        public static let mainIconSize: CGFloat = 64
        public static let callToActionWidth: CGFloat = 160
        public static let callToActionHeight: CGFloat = 50
        public static let containerRadius: CGFloat = 24
        public static let containerPadding: CGFloat = 32
        public static let showcaseRadius: CGFloat = 20
    }
    
    /// 时间轴展示规范
    public struct Timeline {
        public static let emptyIconSize: CGFloat = 64
        public static let indicatorSize: CGFloat = 36
        public static let detailHorizontalPadding: CGFloat = 12
        public static let detailVerticalPadding: CGFloat = 8
        public static let indentPadding: CGFloat = 48
        public static let rowVerticalPadding: CGFloat = 12
        public static let iconCircleSize: CGFloat = 36
    }
    
    /// 通用网格布局规范
    public struct Grid {
        public static let standardSpacing: CGFloat = 16
        public static let largeSpacing: CGFloat = 50
        public static let tightSpacing: CGFloat = 8
        public static let flowSpacing: CGFloat = 10
        public static let emptyStateHeight: CGFloat = 220
    }
    
    /// 知识图谱布局规范
    public struct Graph {
        public static let nodeSize: CGFloat = 40
        public static let selectedNodeSize: CGFloat = 48
        public static let nodeSizeReference: CGFloat = 20
        public static let centralNodeSize: CGFloat = 60
        public static let linkWidth: CGFloat = 1.5
        public static let forceStrength: CGFloat = -200
        public static let minScale: CGFloat = 0.5
        public static let maxScale: CGFloat = 2.0
        public static let tightPadding: CGFloat = 8
        public static let toolbarPaddingTrailing: CGFloat = 20
        public static let toolbarPaddingBottomExpanded: CGFloat = 150
        public static let toolbarPaddingBottomDefault: CGFloat = 20
        public static let layoutPadding: CGFloat = 40
        public static let minLayoutDimension: CGFloat = 100
        public static let highlightedLineWidth: CGFloat = 3.0
        public static let emptyIconSize: CGFloat = 60
        
        public struct ThreeD {
            public static let baseNodeSize: CGFloat = 3.5
            public static let minNodeSize: CGFloat = 3.0
            public static let maxNodeSize: CGFloat = 10.0
            public static let edgeRadius: CGFloat = 0.1
            public static let edgeRadiusHighlighted: CGFloat = 0.3
            public static let starRadius: CGFloat = 0.1
            public static let starFieldRadius: Float = 150.0
        }
    }
    
    /// 复合行模式规范
    public struct CompositeRow {
        public static let spacing: CGFloat = 10
        public static let cornerRadius: CGFloat = 12
        public static let iconBoxSize: CGFloat = 32
        public static let actionAreaWidth: CGFloat = 60
        public static let indicatorWidth: CGFloat = 30
    }
    
    /// 仪表盘与指标规范
    public struct Metrics {
        public static let heroValueSize: CGFloat = 32
        public static let subValueSize: CGFloat = 14
        public static let chartHeight: CGFloat = 220
        public static let boxHeight: CGFloat = 100
        public static let indicatorSize: CGFloat = 12
        public static let progressHeight: CGFloat = 6
        public static let boxAspectRatio: CGFloat = 1.0
        public static let dashboardValueSize: CGFloat = 32
        public static let dashboardLabelSize: CGFloat = 13
        public static let dashboardRadius: CGFloat = 20
        public static let iconBoxSize: CGFloat = 40
        public static let smallIconBoxSize: CGFloat = 28
        public static let largeIconBoxSize: CGFloat = 44
        public static let sourceCardWidth: CGFloat = 135
        public static let sourceCardHeight: CGFloat = 115
        public static let A4Width: CGFloat = 595
        public static let A4Height: CGFloat = 842
        public static let emptyStateVerticalPadding: CGFloat = 24
        public static let sectionSpacing: CGFloat = 24
        public static let maxTagCloudHeight: CGFloat = 300
    }
    
    /// 任务管理中心规范
    public struct Task {
        public static let rowSpacing: CGFloat = 16
        public static let rowVerticalPadding: CGFloat = 4
        public static let iconBoxSize: CGFloat = 44
        public static let statusIndicatorSize: CGFloat = 10
        public static let badgeSize: CGFloat = 32
        public static let progressWidth: CGFloat = 40
        public static let dashboardSpacing: CGFloat = 12
        public static let dashboardPadding: CGFloat = 20
        public static let dashboardRadius: CGFloat = 20
    }
    
    /// 传统垂直列表规范
    public struct List {
        public static let rowVerticalPadding: CGFloat = 8
        public static let rowHorizontalPadding: CGFloat = 16
        public static let rowSpacing: CGFloat = 12
        public static let rowRadius: CGFloat = 12
    }
    
    /// 小型徽章规范
    public struct Chip {
        public static let horizontalPadding: CGFloat = 12
        public static let verticalPadding: CGFloat = 4
        public static let spacing: CGFloat = 8
        public static let iconSpacing: CGFloat = 4
        public static let cornerRadius: CGFloat = 6
    }
    
    /// 侧边菜单规范
    public struct Sidebar {
        public static let rowSpacing: CGFloat = 12
        public static let rowRadius: CGFloat = 8
        public static let rowVerticalPadding: CGFloat = 4
        public static let iconBoxSize: CGFloat = 28
        public static let iconFrameWidth: CGFloat = 24
        public static let badgePadding: CGFloat = 6
    }
    
    /// 视觉装饰模式规范 (Decorator)
    public struct Decorator {
        public static let shadowRadiusSmall: CGFloat = 8
        public static let shadowRadiusLarge: CGFloat = 12
        public static let shadowOffsetYSmall: CGFloat = 4
        public static let shadowOffsetYLarge: CGFloat = 6
        public static let accentLineWidth: CGFloat = 3
        public static let badgeMinSize: CGFloat = 20
        public static let desktopSheetMinWidth: CGFloat = 500
        public static let desktopSheetMinHeight: CGFloat = 600
        public static let glowBlurSmall: CGFloat = 4
        public static let glowBlurMedium: CGFloat = 8
    }
    
    // MARK: - 5. 视觉风格常数 (Styling)
    
    /// 标准边框宽度
    public static let borderWidth: CGFloat = 0.8
    /// 标准阴影半径
    public static let shadowRadius: CGFloat = 10
    /// 标准阴影 Y 轴偏移
    public static let shadowY: CGFloat = 4
}
