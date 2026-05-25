//
//  StubBackgroundTaskProvider.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：属于 Stubs 模块，提供相关的结构体或工具支撑。
//
import Foundation

final class StubBackgroundTaskProvider: BackgroundTaskProtocol {

    /// 注册
    /// /// - Parameter handler: handler
    /// /// - Returns: 返回值
    func register(handler: @escaping @Sendable @MainActor () -> Void) {}

    /// 调度
    func schedule() {}
}
