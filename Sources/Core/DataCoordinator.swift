// DataCoordinator.swift
//
// 作者: Wang Chong
// 功能说明: 数据协调器，负责编排存储与 AI 服务之间的异步同步任务。
// 版本: 1.0
// 修改记录:
//   - 2026-05-07: 初始版本，从 SQLiteStore 剥离同步逻辑。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Observation

/// 数据协调器：编排存储变更与 AI 增强任务（如向量化）的联动。
@MainActor
final class DataCoordinator {
    @ObservationIgnored @Inject private var sqliteStore: SQLiteStore
    @ObservationIgnored @Inject private var embeddingManager: EmbeddingManager
    @ObservationIgnored @Inject private var logger: any LoggerProtocol
    
    private var syncTask: Task<Void, Never>?
    
    init() {
        // 启动时初次同步
        sync()
    }
    
    /// 执行数据同步编排
    func sync() {
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            guard let self = self else { return }

            // 1. 监控存储层的页面变化
            // SQLiteStore 现在只负责通知数据已更新，由协调器决定后续动作
            self.logger.addLog(action: .sync, target: "DataCoordinator", details: "Starting background synchronization...")

            // 2. 触发向量化同步
            await self.embeddingManager.syncEmbeddings(pages: self.sqliteStore.pages)

            self.logger.addLog(action: .sync, target: "DataCoordinator", details: "Synchronization task completed.")
        }
    }
}
