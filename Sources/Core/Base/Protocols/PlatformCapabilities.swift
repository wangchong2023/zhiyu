// PlatformCapabilities.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：定义平台差异化能力协议，用于消除核心逻辑中的 #if os 条件编译。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import LocalAuthentication

// MARK: - 生物识别能力

/// 平台生物识别策略提供者
@MainActor
public protocol BiometricAuthProviderProtocol: Sendable {
    /// 获取当前平台适用的鉴权策略 (LAPolicy)
    var authenticationPolicy: LAPolicy { get }
    
    /// 检查生物识别是否可用
    func canEvaluatePolicy(context: LAContext) -> Bool
    
    /// 执行生物识别鉴权
    func evaluatePolicy(context: LAContext, reason: String) async -> Bool
}


// MARK: - 模型编译能力

/// 机器学习模型编译器协议
public protocol MLModelCompilerProtocol: Sendable {
    /// 是否支持在当前平台执行编译
    var supportsCompilation: Bool { get }
    
    /// 编译指定路径的模型
    /// - Parameter url: 原始模型路径 (.mlmodel)
    /// - Returns: 编译后的模型路径 (.mlmodelc)
    func compileModel(at url: URL) async throws -> URL
}

// MARK: - 安全存储能力

/// 平台特定的安全存储提供者（如 Security-Scoped Bookmarks）
public protocol SecurityScopedStorageProtocol: Sendable {
    /// 为指定 URL 存储持久化访问书签
    func storeBookmark(for url: URL)
    
    /// 从书签数据恢复具有访问权限的 URL
    func restoreURL(from data: Data) -> URL?
}
