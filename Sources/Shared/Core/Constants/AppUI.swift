// AppUI.swift
//
// 作者: Wang Chong
// 功能说明: 本文件定义了智宇 (ZhiYu) 工业级 UI 统一布局规范系统。
// 版本: 1.32 (补全中文注释与文档说明)
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// 智宇视觉模式系统 (ZhiYu Design System)
/// 集成了原子常数、间距规范、图标体系、组件指标及视觉装饰等核心 UI 令牌。
enum AppUI {
    
    // MARK: - 1. 原子间距 (Atomic Spacing)
    /// 最小步进常数 (2px)
    static let atomic: CGFloat = 2
    /// 极小间距 (4px)
    static let tiny: CGFloat = 4
    /// 小型间距 (8px)
    static let small: CGFloat = 8
    /// 中型间距 (12px)
    static let medium: CGFloat = 12
    /// 标准页面内边距 (16px)
    static let standardPadding: CGFloat = 16
    /// 大型间距 (16px)
    static let large: CGFloat = 16
    /// 宽型间距 (20px)
    static let wide: CGFloat = 20
    /// 巨型间距 (24px)
    static let giant: CGFloat = 24
    /// 极大型间距 (32px)
    static let huge: CGFloat = 32
    /// 底部输入栏基准高度 (54px)
    static let inputBarHeight: CGFloat = 54
    /// 宽松内边距 (24px)
    static let loosePadding: CGFloat = 24
    /// 宽幅内边距 (20px)
    static let widePadding: CGFloat = 20
    /// 紧凑内边距 (8px)
    static let tightPadding: CGFloat = 8
    
    // MARK: - 2. 原子圆角 (Atomic Radius)
    /// 微型圆角 (4px)
    static let microRadius: CGFloat = 4
    /// 小型圆角 (8px)
    static let smallRadius: CGFloat = 8
    /// 中型圆角 (10px)
    static let mediumRadius: CGFloat = 10
    /// 卡片通用圆角 (12px)
    static let cardRadius: CGFloat = 12
    /// 标准圆角 (12px)
    static let standardRadius: CGFloat = 12
    /// 大型圆角 (16px)
    static let largeRadius: CGFloat = 16
    /// 胶囊型圆角 (20px)
    static let chipRadius: CGFloat = 20
    
    // MARK: - 3. 图标体系 (Iconography)
    /// 极小图标尺寸 (12px)
    static let iconTiny: CGFloat = 12
    /// 小型图标尺寸 (16px)
    static let iconSmall: CGFloat = 16
    /// 中型图标尺寸 (20px)
    static let iconMedium: CGFloat = 20
    /// 大型图标尺寸 (24px)
    static let iconLarge: CGFloat = 24
    /// 巨大图标尺寸 (32px)
    static let iconHuge: CGFloat = 32
    /// 展示型图标尺寸 (48px)
    static let iconDisplay: CGFloat = 48
    /// 标题栏图标尺寸 (24px)
    static let titleIconSize: CGFloat = 24
    
    // Legacy Aliases (遗留兼容别名)
    static let largeIconSize: CGFloat = 24
    static let microIconSize: CGFloat = 12
    static let captionIconSize: CGFloat = 14
    
    // MARK: - 4. 交互模式 (Interaction Patterns)
    /// 按钮与输入控件的交互规范
    struct Action {
        /// 标准按钮高度
        static let buttonHeight: CGFloat = 44
        /// 紧凑型按钮高度
        static let compactButtonHeight: CGFloat = 32
        /// 胶囊标签高度
        static let capsuleHeight: CGFloat = 28
        /// 标准输入框高度
        static let inputFieldHeight: CGFloat = 50
        /// 最小可点击目标尺寸 (Apple 建议 44pt)
        static let minTouchTarget: CGFloat = 44
        /// 输入栏标准高度
        static let inputBarHeight: CGFloat = 44
        
        /// 交互缩放比例 (按下时)
        static let pressScale: CGFloat = 0.96
        /// 标准动画时长 (s)
        static let animationDuration: Double = 0.2
        
        /// 按钮组间距
        static let buttonSpacing: CGFloat = 12
        /// 按钮内部图标尺寸
        static let iconSize: CGFloat = 16
        /// 小型按钮图标尺寸
        static let smallIconSize: CGFloat = 14
        /// 大型操作图标尺寸
        static let largeIconSize: CGFloat = 24
        /// 返回按钮点击区域宽度
        static let backButtonWidth: CGFloat = 40
    }

    // MARK: - 5. 展示模式 (Gallery Pattern)
    /// 图片、视频或卡片流展示规范
    struct Gallery {
        /// 网格项基础尺寸
        static let itemSize: CGFloat = 100
        /// 网格项图标尺寸
        static let iconSize: CGFloat = 40
        /// 徽章角标偏移量
        static let badgeOffset: CGFloat = 28
        /// 网格项圆角
        static let itemRadius: CGFloat = 16
        /// 全屏展示图标尺寸
        static let displayIconSize: CGFloat = 120
        /// 闪屏页图标尺寸
        static let splashIconSize: CGFloat = 80
        /// 高斯模糊半径
        static let blurRadius: CGFloat = 40
        /// 主引导图标尺寸
        static let mainIconSize: CGFloat = 64
        /// 引导动作按钮宽度
        static let callToActionWidth: CGFloat = 160
        /// 引导动作按钮高度
        static let callToActionHeight: CGFloat = 50
        /// 大容器圆角
        static let containerRadius: CGFloat = 24
        /// 大容器内边距
        static let containerPadding: CGFloat = 32
        /// 展位图圆角
        static let showcaseRadius: CGFloat = 20
        /// 悬停缩放比例
        static let hoverScale: CGFloat = 1.05
    }

    // MARK: - 6. 轴线模式 (Timeline Pattern)
    /// 任务历史、操作日志及时间轴展示规范
    struct Timeline {
        /// 空状态图标尺寸
        static let emptyIconSize: CGFloat = 64
        /// 节点指示器尺寸
        static let indicatorSize: CGFloat = 36
        /// 详情行水平边距
        static let detailHorizontalPadding: CGFloat = 12
        /// 详情行垂直边距
        static let detailVerticalPadding: CGFloat = 8
        /// 缩进宽度
        static let indentPadding: CGFloat = 48
        /// 行垂直间距
        static let rowVerticalPadding: CGFloat = 12
        /// 图标圆圈容器尺寸
        static let iconCircleSize: CGFloat = 36
    }

    // MARK: - 7. 网格模式 (Grid Pattern)
    /// 通用网格布局规范
    struct Grid {
        /// 标准网格间距
        static let standardSpacing: CGFloat = 16
        /// 紧凑网格间距
        static let tightSpacing: CGFloat = 8
        /// 流式布局间距
        static let flowSpacing: CGFloat = 10
        /// 网格空状态高度预留
        static let emptyStateHeight: CGFloat = 220
    }

    // MARK: - 8. 图谱模式 (Graph Pattern)
    /// 知识图谱、关联分析及 3D 节点展示规范
    struct Graph {
        /// 基础节点尺寸 (2D)
        static let nodeSize: CGFloat = 40
        /// 选中状态节点尺寸
        static let selectedNodeSize: CGFloat = 48
        /// 节点引用尺寸
        static let nodeSizeReference: CGFloat = 20
        /// 中心权重节点尺寸
        static let centralNodeSize: CGFloat = 60
        /// 连线宽度
        static let linkWidth: CGFloat = 1.5
        /// 力导向强度
        static let forceStrength: CGFloat = -200
        /// 最小缩放倍率
        static let minScale: CGFloat = 0.5
        /// 最大缩放倍率
        static let maxScale: CGFloat = 2.0
        /// 局部紧凑内边距
        static let tightPadding: CGFloat = 8
        
        /// 工具栏右边距
        static let toolbarPaddingTrailing: CGFloat = 20
        /// 展开状态工具栏底部边距
        static let toolbarPaddingBottomExpanded: CGFloat = 150
        /// 默认工具栏底部边距
        static let toolbarPaddingBottomDefault: CGFloat = 20
        /// 布局整体内边距
        static let layoutPadding: CGFloat = 40
        /// 最小布局维度
        static let minLayoutDimension: CGFloat = 100
        /// 高亮连线宽度
        static let highlightedLineWidth: CGFloat = 3.0
        /// 空状态展示图标尺寸
        static let emptyIconSize: CGFloat = 60
        
        /// 3D 模式专属视觉规范
        struct ThreeD {
            /// 3D 节点基础尺寸
            static let baseNodeSize: CGFloat = 3.5
            /// 3D 节点最小尺寸
            static let minNodeSize: CGFloat = 3.0
            /// 3D 节点最大尺寸
            static let maxNodeSize: CGFloat = 10.0
            /// 节点连线权重
            static let nodeLinkWeight: Double = 0.8
            
            /// 标签位移距离
            static let labelOffset: Float = 1.2
            /// 标签缩放比例
            static let labelScale: Float = 0.5
            
            /// 边缘连线半径
            static let edgeRadius: CGFloat = 0.1
            /// 高亮状态边缘连线半径
            static let edgeRadiusHighlighted: CGFloat = 0.3
            
            /// 星球/背景粒子半径
            static let starRadius: CGFloat = 0.1
            /// 星球场分布半径
            static let starFieldRadius: Float = 150.0
        }
    }

    // MARK: - 9. 复合行模式 (CompositeRow Pattern)
    /// 包含图标、标题、详情及操作位的标准列表行规范
    struct CompositeRow {
        /// 元素间距
        static let spacing: CGFloat = 10
        /// 行圆角
        static let cornerRadius: CGFloat = 12
        /// 图标背景框尺寸
        static let iconBoxSize: CGFloat = 32
        /// 右侧操作区宽度
        static let actionAreaWidth: CGFloat = 60
        /// 展开/折叠指示器宽度
        static let indicatorWidth: CGFloat = 30
    }

    // MARK: - 10. 指标与仪表盘 (Metrics & Dashboard)
    /// 仪表盘卡片、统计指标及卡片视觉指标
    struct Metrics {
        /// 核心数值字号
        static let heroValueSize: CGFloat = 32
        /// 辅助数值字号
        static let subValueSize: CGFloat = 14
        /// 图表预设高度
        static let chartHeight: CGFloat = 220
        /// 统计盒基础高度
        static let boxHeight: CGFloat = 100
        /// 指示点尺寸
        static let indicatorSize: CGFloat = 12
        /// 进度条粗度
        static let progressHeight: CGFloat = 6
        /// 统计盒宽高比
        static let boxAspectRatio: CGFloat = 1.0
        /// 仪表盘数值尺寸
        static let dashboardValueSize: CGFloat = 32
        /// 仪表盘标签尺寸
        static let dashboardLabelSize: CGFloat = 13
        /// 仪表盘卡片圆角
        static let dashboardRadius: CGFloat = 20
        
        /// 现代化卡片图标背景尺寸
        static let iconBoxSize: CGFloat = 40
        /// 现代化卡片小型图标背景尺寸
        static let smallIconBoxSize: CGFloat = 28
        /// 现代化卡片大型图标背景尺寸
        static let largeIconBoxSize: CGFloat = 44
        
        /// 知识来源卡片宽度
        static let sourceCardWidth: CGFloat = 135
        /// 知识来源卡片高度
        static let sourceCardHeight: CGFloat = 115
        
        /// 小型标题字号
        static let titleSmallFontSize: CGFloat = 15
        
        /// 导航历史面包屑最大数量
        static let maxBreadcrumbCount: Int = 5
        
        /// 协作编辑历史显示上限
        static let maxCollabEditHistory: Int = 10
        /// 协作编辑预览字符上限
        static let maxCollabEditPreviewLength: Int = 50
        
        /// 标签云展示区域最大高度
        static let maxTagCloudHeight: CGFloat = 300
        
        /// 知识增长曲线统计天数
        static let knowledgeGrowthDaysLimit: Int = 30
        /// 图谱发现引导触发的页面阈值
        static let graphCoachMarkThreshold: Int = 3
        
        /// 报告导出最大页面数量
        static let maxReportPageExportCount: Int = 10
        /// 报告内容预览字符长度
        static let reportContentPreviewLength: Int = 300
        /// 报告内容最大行数限制
        static let maxReportContentLineLimit: Int = 5
        
        /// A4 纸张标准宽度 (72 DPI)
        static let A4Width: CGFloat = 595
        /// A4 纸张标准高度 (72 DPI)
        static let A4Height: CGFloat = 842
        
        /// 空状态垂直内边距
        static let emptyStateVerticalPadding: CGFloat = 24
        /// 空状态图标透明度
        static let emptyStateIconOpacity: CGFloat = 0.15
        
        /// 模块/卡片标准间距
        static let sectionSpacing: CGFloat = 24
    }

    // MARK: - 11. 任务规范 (Task Patterns)
    /// 任务管理中心、下载/导入进度及卡片流规范
    struct Task {
        /// 任务行间距
        static let rowSpacing: CGFloat = 16
        /// 任务行垂直内边距
        static let rowVerticalPadding: CGFloat = 4
        /// 任务图标背景框尺寸
        static let iconBoxSize: CGFloat = 44
        /// 状态点指示器尺寸
        static let statusIndicatorSize: CGFloat = 10
        /// 徽章尺寸
        static let badgeSize: CGFloat = 32
        /// 进度条宽度
        static let progressWidth: CGFloat = 40
        /// 仪表盘组件间距
        static let dashboardSpacing: CGFloat = 12
        /// 仪表盘页面水平外边距
        static let dashboardPadding: CGFloat = 20
        /// 仪表盘主容器圆角
        static let dashboardRadius: CGFloat = 20
    }

    // MARK: - 12. 动画令牌 (Animation Tokens)
    /// 统一的物理动效与过渡参数
    struct Animation {
        /// 弹性动效响应时长
        static let springResponse: Double = 0.3
        /// 弹性动效阻尼系数
        static let springDamping: Double = 0.8
        /// 点击按下的缩放比例
        static let pressScale: CGFloat = 0.97
        /// 悬停时的缩放比例
        static let hoverScale: CGFloat = 1.02
        /// 标准线性动画时长
        static let standardDuration: Double = 0.2
    }

    // MARK: - 13. 列表模式 (List Pattern)
    /// 设置页面、文件列表等传统垂直列表规范
    struct List {
        /// 行垂直边距
        static let rowVerticalPadding: CGFloat = 8
        /// 行水平外边距 (列表整体缩进)
        static let rowHorizontalPadding: CGFloat = 16
        /// 行间距
        static let rowSpacing: CGFloat = 12
        /// 行容器圆角
        static let rowRadius: CGFloat = 12
    }

    // MARK: - 14. 碎片模式 (Chip Pattern)
    /// 标签、类型标识及小型徽章规范
    struct Chip {
        /// 水平内边距
        static let horizontalPadding: CGFloat = 12
        /// 垂直内边距
        static let verticalPadding: CGFloat = 4
        /// 碎片间距
        static let spacing: CGFloat = 8
        /// 图标与文字间距
        static let iconSpacing: CGFloat = 4
        /// 碎片圆角
        static let cornerRadius: CGFloat = 6
    }

    // MARK: - 15. 侧边栏模式 (Sidebar Pattern)
    /// macOS / iPadOS 导航栏及侧边菜单规范
    struct Sidebar {
        /// 行间距
        static let rowSpacing: CGFloat = 12
        /// 行圆角
        static let rowRadius: CGFloat = 8
        /// 行垂直内边距
        static let rowVerticalPadding: CGFloat = 4
        /// 图标背景框尺寸
        static let iconBoxSize: CGFloat = 28
        /// 图标实际占用宽度
        static let iconFrameWidth: CGFloat = 24
        /// 徽章内边距
        static let badgePadding: CGFloat = 6
    }

    // MARK: - 16. 视觉装饰模式 (Decorator Pattern)
    /// 投影、发光、闪烁及特殊视觉增强效果规范
    struct Decorator {
        /// 小型投影半径
        static let shadowRadiusSmall: CGFloat = 8
        /// 大型投影半径
        static let shadowRadiusLarge: CGFloat = 12
        /// 小型投影 Y 轴偏移
        static let shadowOffsetYSmall: CGFloat = 4
        /// 大型投影 Y 轴偏移
        static let shadowOffsetYLarge: CGFloat = 6
        
        /// 闪烁动画相位偏移
        static let shimmerPhaseShift: CGFloat = 400
        /// 闪烁动画循环时长
        static let shimmerDuration: Double = 1.5
        /// 闪烁光带宽度比例
        static let shimmerWidthRatio: CGFloat = 0.6
        /// 闪烁动画终止比例
        static let shimmerEndRatio: CGFloat = 1.6
        
        /// 中型发光缩放倍率
        static let glowScaleMedium: CGFloat = 1.3
        /// 大型发光缩放倍率
        static let glowScaleLarge: CGFloat = 1.8
        /// 小型发光模糊半径
        static let glowBlurSmall: CGFloat = 4
        /// 中型发光模糊半径
        static let glowBlurMedium: CGFloat = 8
        
        /// 脉冲动效缩放倍率
        static let pulseScale: CGFloat = 1.4
        /// 脉冲动效循环时长
        static let pulseDuration: Double = 1.2
        
        /// 装饰性强调线线宽
        static let accentLineWidth: CGFloat = 3
        /// 徽章最小尺寸
        static let badgeMinSize: CGFloat = 20
        
        /// 桌面端弹窗最小宽度
        static let desktopSheetMinWidth: CGFloat = 500
        /// 桌面端弹窗最小高度
        static let desktopSheetMinHeight: CGFloat = 600
    }

    // MARK: - 17. 排版规范 (Typography)
    /// 统一的字号与字重分级系统
    enum HeadingLevel: Int {
        case h1 = 1, h2, h3, h4, h5, h6
        /// 字号映射
        var size: CGFloat {
            switch self {
            case .h1: return 28
            case .h2: return 22
            case .h3: return 20
            case .h4: return 18
            case .h5: return 16
            case .h6: return 14
            }
        }
        
        /// 字重映射
        var weight: Font.Weight {
            switch self {
            case .h1, .h2, .h3: return .bold
            case .h4, .h5: return .semibold
            case .h6: return .medium
            }
        }
        
        /// 标题顶部间距规范
        var topPadding: CGFloat {
            switch self {
            case .h1: return 24
            case .h2: return 20
            case .h3: return 16
            case .h4: return 12
            case .h5, .h6: return 8
            }
        }
    }

    /// 微型字号 (10px)
    static let microFontSize: CGFloat = 10
    /// 脚注字号 (12px)
    static let captionFontSize: CGFloat = 12
    /// 次级脚注字号 (11px)
    static let caption2FontSize: CGFloat = 11
    /// 副标题字号 (14px)
    static let subheadlineFontSize: CGFloat = 14
    /// 正文字号 (16px)
    static let bodyFontSize: CGFloat = 16
    /// 标题字号 (18px)
    static let headlineFontSize: CGFloat = 18
    /// 大标题字号 (24px)
    static let titleFontSize: CGFloat = 24
    /// 展示大字号 (32px)
    static let displayFontSize: CGFloat = 32
    
    /// 标准脚注字体
    static var captionFont: Font { .system(size: captionFontSize) }
    /// 次级脚注字体 (Medium 字重)
    static var caption2Font: Font { .system(size: caption2FontSize, weight: .medium) }
    /// 标准二级辅助字体
    static var secondaryFont: Font { .system(size: subheadlineFontSize) }
    /// 标准大标题粗体
    static var titleFont: Font { .system(size: titleFontSize, weight: .bold) }
    
    // MARK: - 18. 图标库映射 (Icons)
    /// 定义应用中常用的系统图标 (SF Symbols) 映射
    struct Icons {
        static let trophy = "trophy.fill"
        static let tag = "tag"
        static let hashtag = "number"
        static let link = "link"
        static let sparkles = "sparkles"
        static let more = "ellipsis.circle"
        static let edit = "pencil"
        static let delete = "trash"
        static let pin = "pin"
        static let unpin = "pin.slash"
        static let history = "clock.arrow.2.circlepath"
        static let refresh = "arrow.clockwise"
        static let person = "person.text.rectangle.fill"
        static let lightbulb = "lightbulb.fill"
        static let doc = "doc.richtext.fill"
        static let lock = "lock.fill"
        static let lockOpen = "lock.open.fill"
        static let compare = "arrow.left.and.right.righttriangle.left.righttriangle.right.fill"
        static let plus = "plus"
    }

    // MARK: - 19. 视觉风格常数 (Styling)
    /// 边框、阴影及透明度等风格令牌
    static let borderWidth: CGFloat = 0.8
    static let shadowRadius: CGFloat = 10
    static let shadowY: CGFloat = 4
    static let shadowColor = Color.black.opacity(0.06)
    
    /// 玻璃拟态透明度
    static let glassOpacity: Double = 0.15
    /// 完全不透明度
    static let fullOpacity: Double = 1.0
    /// 禁用状态透明度
    static let disabledOpacity: Double = 0.3
    /// 按下状态透明度
    static let pressedOpacity: Double = 0.9
    /// 暗淡/背景化状态透明度
    static let dimmedOpacity: Double = 0.2
    /// 次要状态透明度
    static let secondaryOpacity: Double = 0.8
    
    /// 标准容器背景色
    static var containerBackground: Color { Color.appCard }
    /// 标准容器边框色
    static var containerBorder: Color { Color.appBorder }
    /// 标准容器材质色 (兼容色)
    static var containerMaterial: Color { Color.appCard } 
    
    // MARK: - 20. 动效常数 (Legacy Animation)
    /// 标准弹性动画
    static var standardAnimation: Animation { .spring(response: 0.35, dampingFraction: 0.8) }
    /// 快速淡出动画
    static var fastAnimation: Animation { .easeOut(duration: 0.2) }
    
    // MARK: - 21. 背景模式 (Background Patterns)
    /// 动态背景与氛围光生成
    struct Background {
        /// 动态网格背景渲染器
        @ViewBuilder
        static func meshGradient() -> some View {
            ZStack {
                Color.appBackground
                
                Canvas { context, size in
                    let gridPadding: CGFloat = 40
                    let rows = Int(size.height / gridPadding)
                    let cols = Int(size.width / gridPadding)
                    
                    for row in 0...rows {
                        let y = CGFloat(row) * gridPadding
                        context.stroke(Path { p in
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: size.width, y: y))
                        }, with: .color(Color.appAccent.opacity(0.05)), lineWidth: 0.5)
                    }
                    
                    for col in 0...cols {
                        let x = CGFloat(col) * gridPadding
                        context.stroke(Path { p in
                            p.move(to: CGPoint(x: x, y: 0))
                            p.addLine(to: CGPoint(x: x, y: size.height))
                        }, with: .color(Color.appAccent.opacity(0.05)), lineWidth: 0.5)
                    }
                }
            }
        }
        
        /// 氛围光渐变背景
        @ViewBuilder
        static func ambientGlow(color: Color) -> some View {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.12), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .blur(radius: 60)
        }
    }
    
    /// 布局常数补充
    struct Layout {
        static let cardContentPadding: CGFloat = 16
        static let maxReadWidth: CGFloat = 800
        static let tightPadding: CGFloat = 8
        static let headerVerticalPadding: CGFloat = 12
        static let listRowSpacing: CGFloat = 10
        static let emptyStateHeight: CGFloat = 200
        static let columnSpacing: CGFloat = 20
    }
}

// MARK: - 语义化颜色与扩展 (Semantic Colors)
extension Color {
    /// 跨平台支持的亮暗模式适配初始化器
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #else
        self.init(light) 
        #endif
    }
    
    /// 核心语义颜色
    static var appBackground: Color { Color(light: Color(hex: "f5f5fa"), dark: Color(hex: "1a1b2e")) }
    static var appCard: Color { Color(light: Color(hex: "ffffff"), dark: Color(hex: "252640")) }
    static var appText: Color { Color(light: Color(hex: "1a1a2e"), dark: Color(hex: "e8e8f0")) }
    static var appSecondary: Color { Color(light: Color(hex: "6b6b87"), dark: Color(hex: "ababc7")) }
    static var appBorder: Color { Color(light: Color(hex: "ebebf2"), dark: Color(hex: "303142")) }
    /// 主题强调色 (通过 ThemeManager 获取)
    static var appAccent: Color { MainActor.assumeIsolated { ThemeManager.shared.accentColor } }
    
    /// 知识分类语义颜色
    static var appSource: Color { .blue }
    static var appConcept: Color { .purple }
    static var appEntity: Color { .orange }
    static var appMap: Color { .indigo }
    static var appComparison: Color { .teal }

    /// 十六进制颜色初始化
    init(hex: String) {
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

// MARK: - View 容器扩展 (Container Styles)
extension View {
    /// 标准卡片容器样式
    func appCardStyle(cornerRadius: CGFloat = AppUI.cardRadius) -> some View {
        self.padding(AppUI.large)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.appBorder, lineWidth: AppUI.borderWidth)
            )
            .shadow(color: AppUI.shadowColor, radius: AppUI.shadowRadius / 2, x: 0, y: 2)
    }
    
    /// 通用容器样式
    func appContainer(background: Color = .appCard, borderColor: Color = .appBorder, cornerRadius: CGFloat = AppUI.cardRadius, padding: Bool = true) -> some View {
        self.padding(padding ? AppUI.standardPadding : 0)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: AppUI.borderWidth)
            )
    }
    
    /// 自定义背景视图的容器样式
    func appContainer(background: AnyView, borderColor: Color = .appBorder, cornerRadius: CGFloat = AppUI.cardRadius, padding: Bool = true) -> some View {
        self.padding(padding ? AppUI.standardPadding : 0)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: AppUI.borderWidth)
            )
    }

    /// 仪表盘指标卡片风格 (Metric Card Style)
    func appMetricCardStyle(color: Color = .appAccent, cornerRadius: CGFloat = AppUI.Metrics.dashboardRadius) -> some View {
        self.background(
            ZStack {
                Color.appCard
                LinearGradient(
                    colors: [color.opacity(0.08), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [.appBorder.opacity(0.8), .appBorder.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Environment Extensions
struct AppAccentColorKey: EnvironmentKey {
    static let defaultValue: Color = .blue
}

extension EnvironmentValues {
    /// 全局强调色环境变量
    var appAccentColor: Color {
        get { self[AppAccentColorKey.self] }
        set { self[AppAccentColorKey.self] = newValue }
    }
}

// MARK: - ShapeStyle Extensions
extension ShapeStyle where Self == Color {
    static var appAccent: Color { .appAccent }
    static var appText: Color { .appText }
    static var appSecondary: Color { .appSecondary }
    static var appBorder: Color { .appBorder }
    static var appCard: Color { .appCard }
    static var appBackground: Color { .appBackground }
    static var appSource: Color { .appSource }
    static var appConcept: Color { .appConcept }
    static var appEntity: Color { .appEntity }
    static var appMap: Color { .appMap }
    static var appComparison: Color { .appComparison }
}
