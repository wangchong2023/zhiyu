// AppEventBus.swift
//
// 作者: Wang Chong
// 功能说明: 系统级事件总线 (Architect 视角：解耦服务间通信)
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
//   - 2026-05-07: 系统性重构，从 WikiEventBus 重命名为 AppEventBus，术语统一为“应用事件总线”
// 日期: 2026-05-07
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
        case pagesCleared
        case clearAllDataRequested // 新增：全局数据清理请求
        case aiTaskStarted(type: String)
        case aiTaskCompleted(type: String, success: Bool)
        case securityStateChanged(isLocked: Bool)
        case vaultMounted(url: URL)
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
