//
//  TaskCenterProtocol.swift
//  ZhiYu
//
//  系统层级：[L1.5] 领域层
//  核心职责：Protocols。提供跨层依赖倒置的领域协议契约，消除基础设施/应用层类型对领域层的反向污染。
//

import Foundation

/// 任务中心协议 (L1.5-Domain)
/// 抽象任务进度追踪能力，使 Domain 层无需直接依赖 L2 TaskCenter
@MainActor
public protocol TaskCenterProtocol: Sendable {

    /// 添加Task
    /// /// - Parameter type: type
    /// /// - Parameter name: name
    /// /// - Parameter target: target
    func addTask(type: TaskType, name: String, target: String) -> UUID

    /// 更新Task
    /// /// - Parameter id: id
    /// /// - Parameter status: status
    func updateTask(_ id: UUID, status: TaskStatus)

    /// completeTask
    /// /// - Parameter id: id
    func completeTask(id: UUID)

    /// failTask
    /// /// - Parameter id: id
    /// /// - Parameter error: error
    func failTask(id: UUID, error: String)
}
