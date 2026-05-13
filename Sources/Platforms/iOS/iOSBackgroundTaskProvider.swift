// iOSBackgroundTaskProvider.swift
//
// 作者: Wang Chong
// 功能说明: 基于 BackgroundTasks 框架的 iOS 后台任务实现。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

#if os(iOS) && !os(watchOS)
import Foundation
import BackgroundTasks

final class iOSBackgroundTaskProvider: BackgroundTaskProtocol {
    private let taskIdentifier = "com.zhimind.ingest.process"
    
    func register(handler: @escaping @Sendable @MainActor () -> Void) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            Task { @MainActor in
                handler()
                task.setTaskCompleted(success: true)
            }
        }
    }
    
    func schedule() {
        let request = BGProcessingTaskRequest(identifier: taskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // 静默失败，后台调度非核心关键路径
        }
    }
}
#endif
