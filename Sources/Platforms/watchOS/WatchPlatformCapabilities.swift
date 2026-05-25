//
//  WatchPlatformCapabilities.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：属于 watchOS 模块，提供相关的结构体或工具支撑。
//
import Foundation
import LocalAuthentication

// MARK: - 生物识别

/// watchOS 平台的鉴权提供者（使用设备密码）
@MainActor
struct WatchBiometricAuthProvider: BiometricAuthProviderProtocol {
    var authenticationPolicy: LAPolicy { .deviceOwnerAuthentication }
    
    /// can评估Policy
    /// /// - Parameter context: context
    /// /// - Returns: 是否成功
    func canEvaluatePolicy(context: LAContext) -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(authenticationPolicy, error: &error)
    }
    
    /// 评估Policy
    /// /// - Parameter context: context
    /// /// - Parameter reason: reason
    /// /// - Returns: 是否成功
    func evaluatePolicy(context: LAContext, reason: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(authenticationPolicy, localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}

// MARK: - 模型编译

/// watchOS 不支持运行时模型编译，作为 Stub 处理
struct WatchModelCompiler: MLModelCompilerProtocol {
    var supportsCompilation: Bool { false }
    
    /// 编译Model
    /// /// - Returns: 链接
    func compileModel(at url: URL) async throws -> URL {
        throw NSError(domain: "WatchModelCompiler", code: -1, userInfo: [NSLocalizedDescriptionKey: "watchOS does not support model compilation at runtime."])
    }
}

// MARK: - 安全存储

/// watchOS 无需或不支持书签持久化
struct WatchSecurityScopedStorage: SecurityScopedStorageProtocol {

    /// 存储添加书签
    func storeBookmark(for url: URL) {}

    /// 恢复URL
    /// /// - Returns: 可选值
    func restoreURL(from data: Data) -> URL? { nil }
}
