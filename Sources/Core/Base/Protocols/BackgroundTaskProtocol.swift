// BackgroundTaskProtocol.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：后台任务调度抽象协议。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 后台任务调度协议
@MainActor
public protocol BackgroundTaskProtocol: Sendable {
    /// 注册后台处理任务
    func register(handler: @escaping @Sendable @MainActor () -> Void)
    
    /// 调度后台任务
    func schedule()
}
