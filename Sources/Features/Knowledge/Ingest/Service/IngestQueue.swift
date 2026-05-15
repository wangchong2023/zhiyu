// IngestQueue.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：离线处理队列，负责在大规模导入文档时，将向量化与 AI 编译任务压入后台队列，不阻塞前台 UI。
// 该类作为逻辑编排层，通过注入的 BackgroundTaskProtocol 实现跨平台的后台调度能力。
// 版本: 1.2
// 修改记录:
//   - 2026-05-13: 彻底重构，实现 BackgroundTasks 框架的物理隔离与协议化。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Combine

/// 离线处理队列
@MainActor
final class IngestQueue: ObservableObject {
    static let shared = IngestQueue()

    @Published var pendingCount: Int = 0
    @Published var isProcessing: Bool = false

    /// 注入的后台任务调度器
    @Inject private var taskProvider: any BackgroundTaskProtocol

    private let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 2 
        queue.qualityOfService = .utility
        return queue
    }()

    private init() {}

    /// 注册后台处理任务
    func registerBackgroundTasks() {
        taskProvider.register { [weak self] in
            guard let self = self else { return }
            if self.pendingCount == 0 {
                // 如果没有待处理任务，可以执行一些清理工作
            }
        }
    }

    /// 将导入任务加入队列
    func enqueue(title: String, content: String, llmService: any LLMServiceProtocol, pages: [KnowledgePage], onResult: @escaping @Sendable @MainActor (KnowledgePage) -> Void) {
        let operation = BlockOperation { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async { self.isProcessing = true }

            Task {
                do {
                    Logger.shared.debug("📦 [IngestQueue] 正在处理任务：\(title)")
                    let result = try await llmService.smartIngest(title: title, rawContent: content, pages: pages)
                    let page = KnowledgePage(title: title, content: result.compiledContent, tags: result.suggestedTags)

                    await MainActor.run {
                        onResult(page)
                        self.decrementCount()
                    }
                } catch {
                    Logger.shared.error("❌ [IngestQueue] 任务失败：\(title), Error: \(error)")
                    await MainActor.run { self.decrementCount() }
                }
            }
        }

        pendingCount += 1
        operationQueue.addOperation(operation)
    }

    private func decrementCount() {
        pendingCount = max(0, pendingCount - 1)
        if pendingCount == 0 {
            isProcessing = false
        }
    }

    func scheduleAppRefresh() {
        guard pendingCount > 0 else { return }
        taskProvider.schedule()
    }
}

// MARK: - Sendable 合规声明
extension IngestQueue: @unchecked Sendable {}
