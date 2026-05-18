// SourceStore.swift
//
// 作者: Wang Chong
// 功能说明: [L1.5] 领域层：信源管理中心，维护当前 AI 正在参考的文档片段集合
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Observation

/// [L1.5] 信源状态存储器
@Observable
public final class SourceStore: @unchecked Sendable {
    public static let shared = SourceStore()
    
    /// 当前活跃的信源列表 (对标 NotebookLM 的 Sources 面板)
    public private(set) var activeSources: [KnowledgeSource] = []
    
    private init() {}
    
    /// 更新当前信源集合
    @MainActor
    public func updateSources(_ sources: [KnowledgeSource]) {
        self.activeSources = sources.sorted { $0.score > $1.score }
    }
    
    /// 清理信源
    @MainActor
    public func clear() {
        self.activeSources = []
    }
}
