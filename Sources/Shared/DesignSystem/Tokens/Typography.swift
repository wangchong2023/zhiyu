// Typography.swift
//
// 作者: Wang Chong
// 功能说明: 本文件定义了智宇 (ZhiYu) 设计系统的排版规范、字号及系统图标令牌。
// 遵循工业级 UI 规范，支持全平台一致的阅读体验。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 智宇排版令牌 (Typography Tokens)
/// 包含字号分级、标题等级枚举及常用系统图标映射。
public enum Typography {
    
    // MARK: - 1. 标题等级 (Heading Levels)
    // MARK: @PR-03: 层次化排版规范，优化文本渲染开销
    
    /// 标题等级枚举
    public enum HeadingLevel: Int {
        case h1 = 1, h2, h3, h4, h5, h6
        
        /// 字号映射
        public var size: CGFloat {
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
        public var weight: Font.Weight {
            switch self {
            case .h1, .h2, .h3: return .bold
            case .h4, .h5: return .semibold
            case .h6: return .medium
            }
        }
        
        /// 标题顶部间距规范
        public var topPadding: CGFloat {
            switch self {
            case .h1: return 24
            case .h2: return 20
            case .h3: return 16
            case .h4: return 12
            case .h5, .h6: return 8
            }
        }
    }
    
    // MARK: - 2. 原子字号 (Atomic Font Sizes)
    
    /// 微型字号 (10px)
    public static let microFontSize: CGFloat = 10
    /// 脚注字号 (12px)
    public static let captionFontSize: CGFloat = 12
    /// 次级脚注字号 (11px)
    public static let caption2FontSize: CGFloat = 11
    /// 副标题字号 (14px)
    public static let subheadlineFontSize: CGFloat = 14
    /// 正文字号 (16px)
    public static let bodyFontSize: CGFloat = 16
    /// 标准字号 (16px)
    public static let standardFontSize: CGFloat = 16
    /// 标题字号 (18px)
    public static let headlineFontSize: CGFloat = 18
    /// 大标题字号 (24px)
    public static let titleFontSize: CGFloat = 24
    /// 展示大字号 (32px)
    public static let displayFontSize: CGFloat = 32
    
    // MARK: - 3. 字体快捷访问 (Font Shortcuts)
    
    /// 标准脚注字体
    public static var captionFont: Font { .system(size: captionFontSize) }
    /// 次级脚注字体 (Medium 字重)
    public static var caption2Font: Font { .system(size: caption2FontSize, weight: .medium) }
    /// 标准二级辅助字体
    public static var secondaryFont: Font { .system(size: subheadlineFontSize) }
    /// 标准大标题粗体
    public static var titleFont: Font { .system(size: titleFontSize, weight: .bold) }
    
    // MARK: - 4. 系统图标映射 (Icons)
    
    /// 定义应用中常用的系统图标 (SF Symbols) 映射
    public struct Icons {
        public static let trophy = "trophy.fill"
        public static let tag = "tag"
        public static let hashtag = "number"
        public static let link = "link"
        public static let sparkles = "sparkles"
        public static let more = "ellipsis.circle"
        public static let edit = "pencil"
        public static let delete = "trash"
        public static let pin = "pin"
        public static let unpin = "pin.slash"
        public static let history = "clock.arrow.2.circlepath"
        public static let refresh = "arrow.clockwise"
        public static let reset = "arrow.triangle.2.circlepath"
        public static let plus = "plus"
        public static let lock = "lock.fill"
        public static let lockOpen = "lock.open.fill"
        
        // ── 知识分类语义化图标 ──
        public static let entity = "person.text.rectangle.fill"
        public static let concept = "lightbulb.fill"
        public static let source = "doc.richtext.fill"
        public static let comparison = "arrow.left.and.right.righttriangle.left.righttriangle.right.fill"
    }
}
