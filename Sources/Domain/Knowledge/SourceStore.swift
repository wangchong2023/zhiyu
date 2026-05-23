//
//  SourceStore.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：属于 Knowledge 模块，提供相关的结构体或工具支撑。
//
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
