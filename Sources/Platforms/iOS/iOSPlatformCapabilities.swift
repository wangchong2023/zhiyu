//
//  iOSPlatformCapabilities.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：属于 iOS 模块，提供相关的结构体或工具支撑。
//
import Foundation
import LocalAuthentication
import CoreML

// MARK: - 生物识别

/// iOS 平台的生物识别提供者
@MainActor
struct iOSBiometricAuthProvider: BiometricAuthProviderProtocol {
    var authenticationPolicy: LAPolicy { .deviceOwnerAuthenticationWithBiometrics }
    
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
