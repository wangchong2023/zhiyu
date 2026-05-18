// WatchPlatformCapabilities.swift
//
// 作者: Wang Chong
// 功能说明: [Shared] watchOS 平台能力实现，提供降级与空实现。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import LocalAuthentication

// MARK: - 生物识别

/// watchOS 平台的鉴权提供者（使用设备密码）
struct WatchBiometricAuthProvider: BiometricAuthProviderProtocol {
    var authenticationPolicy: LAPolicy { .deviceOwnerAuthentication }
    
    func canEvaluatePolicy(context: LAContext) -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(authenticationPolicy, error: &error)
    }
    
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
    
    func compileModel(at url: URL) async throws -> URL {
        throw NSError(domain: "WatchModelCompiler", code: -1, userInfo: [NSLocalizedDescriptionKey: "watchOS does not support model compilation at runtime."])
    }
}

// MARK: - 安全存储

/// watchOS 无需或不支持书签持久化
struct WatchSecurityScopedStorage: SecurityScopedStorageProtocol {
    func storeBookmark(for url: URL) {}
    func restoreURL(from data: Data) -> URL? { nil }
}
