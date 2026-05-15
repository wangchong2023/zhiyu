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
        // ── 基础状态图标 ──
        public static let trophy = "trophy.fill"
        public static let tag = "tag"
        public static let hashtag = "number"
        public static let link = "link"
        public static let sparkles = "sparkles"
        public static let more = "ellipsis.circle"
        public static let edit = "pencil"
        public static let pencilCircle = "pencil.circle.fill"
        public static let delete = "trash"
        public static let pin = "pin"
        public static let unpin = "pin.slash"
        public static let history = "clock.arrow.circlepath"
        public static let refresh = "arrow.clockwise"
        public static let reset = "arrow.triangle.2.circlepath"
        public static let plus = "plus"
        public static let plusCircle = "plus.circle.fill"
        public static let lock = "lock.fill"
        public static let lockOpen = "lock.open.fill"
        public static let info = "info.circle"
        public static let check = "checkmark"
        public static let checkCircle = "checkmark.circle.fill"
        public static let errorCircle = "xmark.circle.fill"
        public static let timer = "timer"
        public static let warning = "exclamationmark.triangle.fill"
        public static let star = "star.fill"
        public static let dotSeparator = "·"
        public static let bullet = "•"
        public static let undo = "arrow.uturn.backward"
        public static let copy = "doc.on.doc"
        public static let seal = "checkmark.seal.fill"
        public static let eyeSlash = "eye.slash.fill"
        public static let eye = "eye"
        public static let faceid = "faceid"
        public static let archive = "archivebox.fill"
        public static let box = "cube.box"
        public static let docRichtext = "doc.richtext.fill"
        public static let docBadgePlus = "doc.badge.plus"
        public static let pencilClipboard = "pencil.and.list.clipboard"
        public static let tray = "tray"
        public static let clock = "clock"
        public static let stop = "stop.circle.fill"
        public static let send = "arrow.up.circle.fill"
        public static let apple = "apple.logo"
        public static let message = "message.fill"
        
        // ── 导航与 UI 图标 ──
        public static let back = "chevron.left"
        public static let forward = "chevron.right"
        public static let forwardCircle = "arrow.right.circle.fill"
        public static let arrowUpRight = "arrow.up.right.circle.fill"
        public static let search = "magnifyingglass"
        public static let command = "command"
        public static let checklist = "checklist"
        public static let grid = "rectangle.grid.2x2.fill"
        public static let list = "list.bullet"
        public static let chevronUpDown = "chevron.up.chevron.down"
        
        // ── 硬件与系统 ──
        public static let person = "person.fill"
        public static let personCircle = "person.circle.fill"
        public static let personCheck = "person.fill.checkmark"
        public static let persons = "person.2.fill"
        public static let personsCircle = "person.2.circle.fill"
        public static let cpu = "cpu.fill"
        public static let cpuOutline = "cpu"
        public static let bolt = "bolt.horizontal.fill"
        public static let antenna = "antenna.radiowaves.left.and.right"
        
        // ── 业务/特性专用 ──
        public static let knowledge = "books.vertical.circle.fill"
        public static let dashboard = "gauge.with.needle.fill"
        public static let pageList = "tray.full.fill"
        public static let weeklyInsight = "doc.text.magnifyingglass"
        public static let healthCheck = "stethoscope"
        public static let plugins = "puzzlepiece.fill"
        public static let collaboration = "bubble.left.and.bubble.right.fill"
        public static let crown = "crown.fill"
        public static let synthesisIcon = "sparkles.rectangle.stack"
        public static let chatBubble = "text.bubble.fill"
        public static let trayArrowDown = "tray.and.arrow.down.fill"
        public static let ocr = "text.viewfinder"
        public static let mic = "mic.fill"
        
        // ── 统计与图表 ──
        public static let chartLine = "chart.line.uptrend.xyaxis"
        public static let chartPie = "chart.pie"
        public static let chartBar = "chart.bar.fill"
        public static let network = "point.3.connected.trianglepath.dotted"
        public static let database = "cylinder.split.1x2.fill"
        public static let log = "doc.text.below.ecg.fill"
        
        // ── 知识分类语义化图标 ──
        public static let entity = "person.text.rectangle.fill"
        public static let concept = "lightbulb.fill"
        public static let source = "doc.richtext.fill"
        public static let comparison = "arrow.left.and.right.righttriangle.left.righttriangle.right.fill"
    }
}
