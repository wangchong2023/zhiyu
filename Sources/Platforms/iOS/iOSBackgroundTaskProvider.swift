//
//  iOSBackgroundTaskProvider.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：属于 iOS 模块，提供相关的结构体或工具支撑。
//
#if os(iOS) && !os(watchOS)
import Foundation
import BackgroundTasks

final class iOSBackgroundTaskProvider: BackgroundTaskProtocol {
    private let taskIdentifier = "com.zhimind.ingest.process"
    
    /// 注册
    /// - Parameter handler: handler
    /// - Returns: 返回值
    func register(handler: @escaping @Sendable @MainActor () -> Void) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            Task { @MainActor in
                handler()
                task.setTaskCompleted(success: true)
            }
        }
    }
    
    /// 调度
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
