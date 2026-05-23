//
//  AppEventBus.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0.5] 系统集成层
//  核心职责：属于 Events 模块，提供相关的结构体或工具支撑。
//
import Foundation
import Combine

/// 系统级事件总线 (Architect 视角：解耦服务间通信)
@MainActor
final class AppEventBus {
    static let shared = AppEventBus()
    private init() {}

    /// 定义系统关键事件
    enum AppEvent {
        case pageCreated(id: UUID, title: String, nodeCount: Int, linkCount: Int)
        case pageUpdated(id: UUID, nodeCount: Int, linkCount: Int)
        case pageDeleted(id: UUID)
        case pagesCleared
        case storeReloaded // 存储库已重新加载（如从备份恢复或初始化完成）
        case clearAllDataRequested // 新增：全局数据清理请求
        case aiTaskStarted(type: String)
        case aiTaskCompleted(type: String, success: Bool)
        case securityStateChanged(isLocked: Bool)
        case vaultMounted(url: URL)
        case graphRelayoutRequested
    }

    private let subject = PassthroughSubject<AppEvent, Never>()

    /// 发布事件
    func publish(_ event: AppEvent) {
        DispatchQueue.main.async {
            self.subject.send(event)
        }
    }

    /// 订阅事件
    func subscribe() -> AnyPublisher<AppEvent, Never> {
        subject.eraseToAnyPublisher()
    }
}

extension AppEventBus: @unchecked Sendable {}
