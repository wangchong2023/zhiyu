// AppUI.swift
//
// 作者: Wang Chong
// 功能说明: 本文件定义了智宇 (ZhiYu) 工业级 UI 统一布局规范系统。
// 版本: 1.31 (增加视觉装饰模式与原子常数)

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 智宇视觉模式系统
enum AppUI {
    
    // MARK: - 1. 原子间距 (Atomic Spacing)
    static let atomic: CGFloat = 2
    static let tiny: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let standardPadding: CGFloat = 16
    static let large: CGFloat = 16
    static let wide: CGFloat = 20
    static let giant: CGFloat = 24
    static let huge: CGFloat = 32
    static let inputBarHeight: CGFloat = 54
    static let loosePadding: CGFloat = 24
    static let widePadding: CGFloat = 20
    static let tightPadding: CGFloat = 8
    
    // MARK: - 2. 原子圆角 (Atomic Radius)
    static let microRadius: CGFloat = 4
    static let smallRadius: CGFloat = 8
    static let mediumRadius: CGFloat = 10
    static let cardRadius: CGFloat = 12
    static let standardRadius: CGFloat = 12
    static let largeRadius: CGFloat = 16
    static let chipRadius: CGFloat = 20
    
    // MARK: - 3. 图标体系 (Iconography)
    static let iconTiny: CGFloat = 12
    static let iconSmall: CGFloat = 16
    static let iconMedium: CGFloat = 20
    static let iconLarge: CGFloat = 24
    static let iconHuge: CGFloat = 32
    static let iconDisplay: CGFloat = 48
    static let titleIconSize: CGFloat = 24
    
    // Legacy Aliases
    static let largeIconSize: CGFloat = 24
    static let microIconSize: CGFloat = 12
    static let captionIconSize: CGFloat = 14
    
    // MARK: - 4. 交互模式 (Interaction Patterns)
    struct Action {
        static let buttonHeight: CGFloat = 44
        static let compactButtonHeight: CGFloat = 32
        static let capsuleHeight: CGFloat = 28
        static let inputFieldHeight: CGFloat = 50
        static let minTouchTarget: CGFloat = 44
        static let inputBarHeight: CGFloat = 44
        
        static let pressScale: CGFloat = 0.96
        static let animationDuration: Double = 0.2
        
        static let buttonSpacing: CGFloat = 12
        static let iconSize: CGFloat = 16
        static let smallIconSize: CGFloat = 14
        static let largeIconSize: CGFloat = 24
        static let backButtonWidth: CGFloat = 40
    }

    // MARK: - 5. 展示模式 (Gallery Pattern)
    struct Gallery {
        static let itemSize: CGFloat = 100
        static let iconSize: CGFloat = 40
        static let badgeOffset: CGFloat = 28
        static let itemRadius: CGFloat = 16
        static let displayIconSize: CGFloat = 120
        static let splashIconSize: CGFloat = 80
        static let blurRadius: CGFloat = 40
        static let mainIconSize: CGFloat = 64
        static let callToActionWidth: CGFloat = 160
        static let callToActionHeight: CGFloat = 50
        static let containerRadius: CGFloat = 24
        static let containerPadding: CGFloat = 32
        static let showcaseRadius: CGFloat = 20
        static let hoverScale: CGFloat = 1.05
    }

    // MARK: - 6. 轴线模式 (Timeline Pattern)
    struct Timeline {
        static let emptyIconSize: CGFloat = 64
        static let indicatorSize: CGFloat = 36
        static let detailHorizontalPadding: CGFloat = 12
        static let detailVerticalPadding: CGFloat = 8
        static let indentPadding: CGFloat = 48
        static let rowVerticalPadding: CGFloat = 12
        static let iconCircleSize: CGFloat = 36
    }

    // MARK: - 7. 网格模式 (Grid Pattern)
    struct Grid {
        static let standardSpacing: CGFloat = 16
        static let tightSpacing: CGFloat = 8
        static let flowSpacing: CGFloat = 10
        static let emptyStateHeight: CGFloat = 220
    }

    // MARK: - 8. 图谱模式 (Graph Pattern)
    struct Graph {
        static let nodeSize: CGFloat = 40
        static let selectedNodeSize: CGFloat = 48
        static let nodeSizeReference: CGFloat = 20
        static let centralNodeSize: CGFloat = 60
        static let linkWidth: CGFloat = 1.5
        static let forceStrength: CGFloat = -200
        static let minScale: CGFloat = 0.5
        static let maxScale: CGFloat = 2.0
        static let tightPadding: CGFloat = 8
        
        // 布局与交互增强
        static let toolbarPaddingTrailing: CGFloat = 20
        static let toolbarPaddingBottomExpanded: CGFloat = 100
        static let toolbarPaddingBottomDefault: CGFloat = 20
        static let layoutPadding: CGFloat = 40
        static let minLayoutDimension: CGFloat = 100
        static let highlightedLineWidth: CGFloat = 3.0
        static let emptyIconSize: CGFloat = 60
    }

    // MARK: - 9. 复合行模式 (CompositeRow Pattern)
    struct CompositeRow {
        static let spacing: CGFloat = 10
        static let cornerRadius: CGFloat = 12
        static let iconBoxSize: CGFloat = 32
        static let actionAreaWidth: CGFloat = 60
        static let indicatorWidth: CGFloat = 30
    }

    struct Metrics {
        static let heroValueSize: CGFloat = 32
        static let subValueSize: CGFloat = 14
        static let chartHeight: CGFloat = 200
        static let boxHeight: CGFloat = 120
        static let indicatorSize: CGFloat = 12
        static let progressHeight: CGFloat = 6
        static let boxAspectRatio: CGFloat = 1.0
        static let dashboardValueSize: CGFloat = 22
        static let dashboardLabelSize: CGFloat = 12
    }

    struct Task {
        static let rowSpacing: CGFloat = 16
        static let rowVerticalPadding: CGFloat = 4
        static let iconBoxSize: CGFloat = 44
        static let statusIndicatorSize: CGFloat = 10
        static let badgeSize: CGFloat = 32
        static let progressWidth: CGFloat = 40
        static let dashboardSpacing: CGFloat = 12
        static let dashboardPadding: CGFloat = 20
        static let dashboardRadius: CGFloat = 20
    }

    // MARK: - 11. 列表模式 (List Pattern)
    struct List {
        static let rowVerticalPadding: CGFloat = 8
        static let rowHorizontalPadding: CGFloat = 16
        static let rowSpacing: CGFloat = 12
        static let rowRadius: CGFloat = 12
    }

    // MARK: - 12. 碎片模式 (Chip Pattern)
    struct Chip {
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 4
        static let spacing: CGFloat = 8
        static let iconSpacing: CGFloat = 4
        static let cornerRadius: CGFloat = 6
    }

    // MARK: - 12. 侧边栏模式 (Sidebar Pattern)
    struct Sidebar {
        static let rowSpacing: CGFloat = 12
        static let rowRadius: CGFloat = 8
        static let rowVerticalPadding: CGFloat = 4
        static let iconBoxSize: CGFloat = 28
        static let iconFrameWidth: CGFloat = 24
        static let badgePadding: CGFloat = 6
    }

    // MARK: - 12. 视觉装饰模式 (Decorator Pattern)
    struct Decorator {
        static let shadowRadiusSmall: CGFloat = 8
        static let shadowRadiusLarge: CGFloat = 12
        static let shadowOffsetYSmall: CGFloat = 4
        static let shadowOffsetYLarge: CGFloat = 6
        
        static let shimmerPhaseShift: CGFloat = 400
        static let shimmerDuration: Double = 1.5
        static let shimmerWidthRatio: CGFloat = 0.6
        static let shimmerEndRatio: CGFloat = 1.6
        
        static let glowScaleMedium: CGFloat = 1.3
        static let glowScaleLarge: CGFloat = 1.8
        static let glowBlurSmall: CGFloat = 4
        static let glowBlurMedium: CGFloat = 8
        
        static let pulseScale: CGFloat = 1.4
        static let pulseDuration: Double = 1.2
        
        static let accentLineWidth: CGFloat = 3
        static let badgeMinSize: CGFloat = 20
        
        static let desktopSheetMinWidth: CGFloat = 500
        static let desktopSheetMinHeight: CGFloat = 600
    }

    // MARK: - 13. 排版规范 (Typography)
    enum HeadingLevel: Int {
        case h1 = 1, h2, h3, h4, h5, h6
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
        
        var weight: Font.Weight {
            switch self {
            case .h1, .h2, .h3: return .bold
            case .h4, .h5: return .semibold
            case .h6: return .medium
            }
        }
        
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

    static let microFontSize: CGFloat = 10
    static let captionFontSize: CGFloat = 12
    static let subheadlineFontSize: CGFloat = 14
    static let bodyFontSize: CGFloat = 16
    static let headlineFontSize: CGFloat = 18
    static let titleFontSize: CGFloat = 24
    static let displayFontSize: CGFloat = 32
    
    static var captionFont: Font { .system(size: captionFontSize) }
    static var secondaryFont: Font { .system(size: subheadlineFontSize) }
    static var titleFont: Font { .system(size: titleFontSize, weight: .bold) }
    
    // MARK: - 14. 图标库 (Icons)
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

    // MARK: - 15. 视觉风格 (Styling)
    static let borderWidth: CGFloat = 0.8
    static let shadowRadius: CGFloat = 10
    static let shadowY: CGFloat = 4
    static let shadowColor = Color.black.opacity(0.06)
    static let glassOpacity: Double = 0.15
    static let fullOpacity: Double = 1.0
    static let disabledOpacity: Double = 0.3
    
    static var containerBackground: Color { Color.appCard }
    static var containerBorder: Color { Color.appBorder }
    static var containerMaterial: Color { Color.appCard } 
    
    // MARK: - 16. 动效常数 (Animation)
    static var standardAnimation: Animation { .spring(response: 0.35, dampingFraction: 0.8) }
    static var fastAnimation: Animation { .easeOut(duration: 0.2) }
    
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

// MARK: - 语义化颜色与扩展
extension Color {
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #else
        self.init(light) 
        #endif
    }
    static var appBackground: Color { Color(light: Color(hex: "f5f5fa"), dark: Color(hex: "1a1b2e")) }
    static var appCard: Color { Color(light: Color(hex: "ffffff"), dark: Color(hex: "252640")) }
    static var appText: Color { Color(light: Color(hex: "1a1a2e"), dark: Color(hex: "e8e8f0")) }
    static var appSecondary: Color { Color(light: Color(hex: "6b6b87"), dark: Color(hex: "8b8ba7")) }
    static var appBorder: Color { Color(light: Color(hex: "ebebf2"), dark: Color(hex: "303142")) }
    static var appAccent: Color { MainActor.assumeIsolated { ThemeManager.shared.accentColor } }
    
    static var appSource: Color { .blue }
    static var appConcept: Color { .purple }
    static var appEntity: Color { .orange }
    static var appMap: Color { .indigo }
    static var appComparison: Color { .teal }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        let mask: UInt64 = 0xFF
        let maxRGB: Double = 255.0
        
        // 位移常量
        let shift24: UInt64 = 24
        let shift16: UInt64 = 16
        let shift8: UInt64 = 8
        
        switch hex.count {
        case 6: // RGB (24-bit)
            (a, r, g, b) = (UInt64(maxRGB), int >> shift16, int >> shift8 & mask, int & mask)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> shift24, int >> shift16 & mask, int >> shift8 & mask, int & mask)
        default:
            // 默认蓝色: com.apple.SwiftUI.Color.blue 风格
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

// MARK: - View 容器扩展
extension View {
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
    
    func appContainer(background: Color = .appCard, borderColor: Color = .appBorder, cornerRadius: CGFloat = AppUI.cardRadius, padding: Bool = true) -> some View {
        self.padding(padding ? AppUI.standardPadding : 0)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: AppUI.borderWidth)
            )
    }
    
    func appContainer(background: AnyView, borderColor: Color = .appBorder, cornerRadius: CGFloat = AppUI.cardRadius, padding: Bool = true) -> some View {
        self.padding(padding ? AppUI.standardPadding : 0)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: AppUI.borderWidth)
            )
    }
}

// MARK: - Environment Extensions
struct AppAccentColorKey: EnvironmentKey {
    static let defaultValue: Color = .blue
}

extension EnvironmentValues {
    var appAccentColor: Color {
        get { self[AppAccentColorKey.self] }
        set { self[AppAccentColorKey.self] = newValue }
    }
}

// MARK: - ShapeStyle Extensions
// 使 .foregroundStyle(.appAccent) 等调用能够在所有视图中被正确推断
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
