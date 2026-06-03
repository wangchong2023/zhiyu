//
//  AppSyncOrchestrator.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/01.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：属于 Knowledge 模块，提供相关的结构体或工具支撑。
//

import Foundation
import Combine

/// 智宇全局同步引擎调度器 (AppSyncOrchestrator)
/// 负责编排地云同步链路，集成底层驱动与冲突解决算法。
@MainActor
public final class AppSyncOrchestrator: CloudSyncOrchestrator {
    
    @Published public private(set) var syncStatus: CloudSyncStatus = .idle
    @Published public private(set) var lastSyncDate: Date?
    
    private let provider: any CloudStorageProvider
    private let resolver: any SyncConflictResolver
    
    public init(provider: any CloudStorageProvider, resolver: any SyncConflictResolver) {
        self.provider = provider
        self.resolver = resolver
    }
    
    /// 执行核心同步逻辑
    public func performSync(localPages: [KnowledgePage], localLogs: [LogEntry]) async throws -> (pages: [KnowledgePage], logs: [LogEntry]) {
        self.syncStatus = .syncing
        
        // 1. 检查可用性
        let isAvailable = await provider.checkAvailability()
        guard isAvailable else {
            self.syncStatus = .error(L10n.ICloud.Status.notAvailable)
            return (localPages, localLogs)
        }
        
        // 2. 拉取云端（容错：云端不存在则视为本地主权）
        let remote: (pages: [KnowledgePage], logs: [LogEntry], lastModified: Date)
        do {
            remote = try await provider.pull()
        } catch {
            try await provider.push(pages: localPages, logs: localLogs)
            self.syncStatus = .synced
            self.lastSyncDate = Date()
            return (localPages, localLogs)
        }
        
        // 3. 冲突比对与合并
        let hasRemoteNewer = lastSyncDate.map { remote.lastModified > $0 } ?? true
        
        let finalPages: [KnowledgePage]
        let finalLogs: [LogEntry]
        
        if hasRemoteNewer {
            finalPages = resolver.mergePages(local: localPages, remote: remote.pages)
            finalLogs = resolver.mergeLogs(local: localLogs, remote: remote.logs)
        } else {
            finalPages = localPages
            finalLogs = localLogs
        }
        
        // 4. 推送黄金数据集
        try await provider.push(pages: finalPages, logs: finalLogs)
        
        self.syncStatus = .synced
        self.lastSyncDate = Date()
        
        return (finalPages, finalLogs)
    }
}
