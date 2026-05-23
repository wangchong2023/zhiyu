//
//  IngestQueue.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：属于 Service 模块，提供相关的结构体或工具支撑。
//
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
                    Logger.shared.debug("📦 [IngestQueue] Processing task: \(title)")
                    let result = try await llmService.smartIngest(title: title, rawContent: content, pages: pages)
                    let page = KnowledgePage(title: title, content: result.compiledContent, tags: result.suggestedTags)

                    await MainActor.run {
                        onResult(page)
                        self.decrementCount()
                    }
                } catch {
                    Logger.shared.error("❌ [IngestQueue] Task failed: \(title), Error: \(error)")
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
