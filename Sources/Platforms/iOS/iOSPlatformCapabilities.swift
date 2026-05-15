// iOSPlatformCapabilities.swift
//
// 作者: Wang Chong
// 功能说明: iOS 平台能力实现，解耦核心业务逻辑。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import LocalAuthentication
import CoreML

// MARK: - 生物识别

/// iOS 平台的生物识别提供者
struct iOSBiometricAuthProvider: BiometricAuthProviderProtocol {
    var authenticationPolicy: LAPolicy { .deviceOwnerAuthenticationWithBiometrics }
    
    func canEvaluatePolicy(context: LAContext) -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(authenticationPolicy, error: &error)
    }
}

// MARK: - 模型编译

/// 基于 Core ML 的通用模型编译器 (支持 iOS/macOS)
struct CoreMLModelCompiler: MLModelCompilerProtocol {
    var supportsCompilation: Bool { true }
    
    func compileModel(at url: URL) async throws -> URL {
        return try await MLModel.compileModel(at: url)
    }
}

// MARK: - 安全存储

/// iOS 的通用安全存储（主要由 UIDocumentPicker 自动处理上下文）
struct iOSSecurityScopedStorage: SecurityScopedStorageProtocol {
    func storeBookmark(for url: URL) {
        // iOS 侧通常由外部选择器直接返回权限，此处作为扩展预留
    }
    
    func restoreURL(from data: Data) -> URL? {
        return nil
    }
}
