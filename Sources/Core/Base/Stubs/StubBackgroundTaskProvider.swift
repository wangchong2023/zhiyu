//
//  StubBackgroundTaskProvider.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：平台不支持功能的安全桩实现，遵循协议提供空操作或未实现提示。
//
import Foundation

final class StubBackgroundTaskProvider: BackgroundTaskProtocol {

    /// 注册
    /// - Parameter handler: handler
    /// - Returns: 返回值
    func register(handler: @escaping @Sendable @MainActor () -> Void) {}

    /// 调度
    func schedule() {}
}