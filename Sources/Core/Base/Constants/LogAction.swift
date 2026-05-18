// LogAction.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：操作日志动作类型 (标准化的动作分类，驱动 UI 表现与系统审计)
// 版本: 1.1
// 修改记录:
//   - 2026-05-16: 架构对齐：物理下沉至 Core Base 层，解除反向依赖。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 操作日志动作类型
public enum LogAction: String, Codable, CaseIterable, Sendable {
    // 核心创作
    case create = "logAction.create"
    case update = "logAction.update"
    case delete = "logAction.delete"
    
    // 数据管理
    case ingest = "logAction.ingest"
    case smartIngest = "logAction.smartIngest"
    case export = "action.export"
    
    // PDF 增强
    case importPDF = "logAction.importPDF"
    case importPDFFailed = "logAction.importPDFFailed"
    case deletePDF = "logAction.deletePDF"
    case highlight = "logAction.highlight"
    
    // 系统与 AI
    case lint = "logAction.lint"
    case healthCheck = "logAction.healthCheck"
    case systemInit = "logAction.systemInit"
    case aiscanFailed = "log.action.aiscan.failed"
    case aiscanSkipped = "log.action.aiscan.skipped"
    case sync = "logAction.sync"
    
    // 系统级
    case error = "ERROR"
    case unknown = "unknown"

    /// 本地化显示名称
    public var localizedName: String {
        L10n.Common.tr(self.rawValue)
    }
    
    /// 动作对应的颜色名称
    public var colorName: String {
        switch self {
        case .create: return "green"
        case .update: return "blue"
        case .delete, .deletePDF: return "red"
        case .lint, .healthCheck: return "orange"
        case .ingest, .importPDF, .export: return "teal"
        case .smartIngest: return "purple"
        case .highlight: return "yellow"
        case .systemInit: return "indigo"
        case .aiscanFailed, .importPDFFailed: return "red"
        case .aiscanSkipped, .sync: return "gray"
        default: return "gray"
        }
    }

    /// 动作对应的 SF Symbol 图标
    public var icon: String {
        switch self {
        case .create: return "plus"
        case .update: return "pencil"
        case .delete, .deletePDF: return "trash"
        case .lint, .healthCheck: return "stethoscope"
        case .ingest, .importPDF, .export: return "arrow.down.doc"
        case .smartIngest: return "sparkles"
        case .highlight: return "highlighter"
        case .systemInit: return "sparkles"
        case .aiscanFailed, .importPDFFailed: return "exclamationmark.triangle"
        case .aiscanSkipped: return "forward.end"
        case .sync: return "arrow.triangle.2.circlepath"
        default: return "circle"
        }
    }
}
