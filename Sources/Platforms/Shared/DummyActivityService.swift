// DummyActivityService.swift
//
// 作者: Wang Chong
// 功能说明: [Shared] [Platforms/Shared] 实时活动服务空实现。
// 用于非 iOS 平台或 iOS 模拟器环境，确保 DI 容器一致性。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 实时活动服务的空实现 (No-op)
final class DummyActivityService: LiveActivityProtocol, Sendable {
    func startActivity(id: UUID, name: String, target: String) {
        // 非支持平台不执行任何操作
    }
    
    func updateProgress(id: UUID, progress: Double, message: String) async {
        // 非支持平台不执行任何操作
    }
    
    func endActivity(id: UUID) async {
        // 非支持平台不执行任何操作
    }
}
