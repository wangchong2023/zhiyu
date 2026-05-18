// LiveActivityProtocol.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：灵动岛与实时活动抽象协议。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// [Infra] 实时活动服务协议
/// 旨在抹平 iOS 灵动岛 (Live Activity) 与其他平台的差异，实现业务层无宏。
public protocol LiveActivityProtocol: Sendable {
    /// 开启一个新的实时活动
    /// - Parameters:
    ///   - id: 关联的任务 UUID
    ///   - name: 任务名称
    ///   - target: 目标对象名称
    func startActivity(id: UUID, name: String, target: String)
    
    /// 更新活动进度
    /// - Parameters:
    ///   - id: 任务 UUID
    ///   - progress: 进度值 (0.0 - 1.0)
    ///   - message: 状态描述文本
    func updateProgress(id: UUID, progress: Double, message: String) async
    
    /// 结束实时活动
    /// - Parameter id: 任务 UUID
    func endActivity(id: UUID) async
}
