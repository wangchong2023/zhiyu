//
//  PageType.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：核心领域模型定义（KnowledgePage、PageLink、PluginRecord 等）。
//
import Foundation

// MARK: - Page Type
public enum PageType: String, Codable, CaseIterable, Identifiable, Sendable {
    case entity
    case concept
    case source
    case comparison
    case map
    case raw
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .entity: return L10n.CoreModels.type.entity
        case .concept: return L10n.CoreModels.type.concept
        case .source: return L10n.CoreModels.type.source
        case .comparison: return L10n.CoreModels.type.comparison
        case .map: return L10n.CoreModels.type.map
        case .raw: return L10n.CoreModels.type.raw
        }
    }
    
    public var colorName: String {
        switch self {
        case .entity: return "entity"
        case .concept: return "concept"
        case .source: return "source"
        case .comparison: return "comparison"
        case .map: return "map"
        case .raw: return "gray"
        }
    }
}

// MARK: - Page Status
public enum PageStatus: String, Codable, CaseIterable, Sendable {
    case active = "active"
    case stub = "stub"
    case needsUpdate = "needs-update"
    case deprecated = "deprecated"
    
    public var displayName: String {
        switch self {
        case .active: return L10n.CoreModels.Status.active
        case .stub: return L10n.CoreModels.Status.stub
        case .needsUpdate: return L10n.CoreModels.Status.needsUpdate
        case .deprecated: return L10n.CoreModels.Status.deprecated
        }
    }
    
    public var colorName: String {
        switch self {
        case .active: return "green"
        case .stub: return "yellow"
        case .needsUpdate: return "orange"
        case .deprecated: return "red"
        }
    }
}

// MARK: - Confidence Level
public enum Confidence: String, Codable, CaseIterable, Sendable {
    case high
    case medium
    case low
    
    public var displayName: String {
        switch self {
        case .high: return L10n.CoreModels.confidence.high
        case .medium: return L10n.CoreModels.confidence.medium
        case .low: return L10n.CoreModels.confidence.low
        }
    }
    
    public var colorName: String {
        switch self {
        case .high: return "green"
        case .medium: return "yellow"
        case .low: return "red"
        }
    }
}
