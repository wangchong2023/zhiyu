// MacOSPlatformCapabilities.swift
//
// 作者: Wang Chong
// 功能说明: [Shared] macOS 平台能力实现，包含安全书签持久化。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import LocalAuthentication

// MARK: - 生物识别

/// macOS 平台的生物识别提供者
struct MacOSBiometricAuthProvider: BiometricAuthProviderProtocol {
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

// MARK: - 安全存储

/// macOS 安全存储：实现真正的 Security-Scoped Bookmarks 持久化
struct MacOSSecurityScopedStorage: SecurityScopedStorageProtocol {
    func storeBookmark(for url: URL) {
        do {
            let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(data, forKey: AppConstants.Keys.Storage.vaultBookmarkPrefix + url.lastPathComponent)
        } catch {
            print("❌ [macOS] 无法创建书签: \(error.localizedDescription)")
        }
    }
    
    func restoreURL(from data: Data) -> URL? {
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale { return nil }
            return url
        } catch {
            print("❌ [macOS] 无法解析书签: \(error.localizedDescription)")
            return nil
        }
    }
}
