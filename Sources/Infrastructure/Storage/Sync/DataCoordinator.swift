// DataCoordinator.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：数据协调器，负责编排存储与 AI 服务之间的异步同步任务。
// 版本: 1.1
// 修改记录:
//   - 2026-05-07: 初始版本，从 SQLiteStore 剥离同步逻辑。
//   - 2026-05-10: 标准化代码注释，增加 SRS 溯源标识。
// 版权: © 2026 Wang Chong。保留所有权利。

import Foundation
import Observation

/// 数据协调器：编排存储变更与 AI 增强任务（如向量化）的联动。
/// @SRS-7.1: 关键路径编排与日志记录
/// @SRS-7.2: 性能指标监控起点
@MainActor
final class DataCoordinator {
    @ObservationIgnored @Inject private var sqliteStore: SQLiteStore
    @ObservationIgnored @Inject private var embeddingManager: EmbeddingManager
    @ObservationIgnored @Inject private var logger: any LoggerProtocol
    
    /// 同步任务句柄
    private var syncTask: Task<Void, Never>?
    
    /// 构造函数：由于强依赖通过外部 DI 注入，不在此处直接同步触发 sync() 副作用以避免启动并发注册竞争
    init() {}
    
    /// 执行数据同步编排
    /// 负责监控存储层的页面变化，并触发向量化同步任务 (@PR-02, @PR-05)
    func sync() {
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            guard let self = self else { return }

            // 1. 监控存储层的页面变化
            // SQLiteStore 现在只负责通知数据已更新，由协调器决定后续动作
            self.logger.addLog(
                action: .sync,
                target: "DataCoordinator",
                details: "Starting background synchronization...",
                module: "Core"
            )

            // 2. 触发向量化同步 (@RR-01: 确保向量存储与主库最终一致性)
            let currentPages = await self.sqliteStore.pages
            await self.embeddingManager.syncEmbeddings(pages: currentPages)
            
            // 3. 触发 Spotlight 索引同步
            SpotlightService.shared.indexPages(currentPages)

            self.logger.addLog(
                action: .sync,
                target: "DataCoordinator",
                details: "Synchronization task completed.",
                module: "Core"
            )
        }
    }
}
