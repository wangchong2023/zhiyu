//
//  SettingsStore.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：系统设置：LLM 配置、性能监控、插件管理、iCloud、备份。
//
import Foundation
import Observation
import Combine

/// 全局设置存储，管理隐私模式、安全验证及显示偏好。
@MainActor
@Observable
public final class SettingsStore {
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored @Inject var keyStore: any KeyStoreProtocol

    public init() {
        AppEventBus.shared.subscribe()
            .sink { [weak self] in if case .clearAllDataRequested = $0 { self?.reset() } }
            .store(in: &cancellables)
    }
    // ── 隐私与安全 ──
    @ObservationIgnored private var _isPrivacyModeEnabled: Bool = {
        // NOTE: Lazy initializer context — resolve directly since @Inject not yet available
        return ServiceContainer.shared.resolve((any KeyStoreProtocol).self).object(forKey: AppConstants.Keys.Storage.isPrivacyModeEnabled) as? Bool ?? true
    }()
    
    public var isPrivacyModeEnabled: Bool {
        get {
            access(keyPath: \.isPrivacyModeEnabled)
            return _isPrivacyModeEnabled
        }
        set {
            withMutation(keyPath: \.isPrivacyModeEnabled) {
                _isPrivacyModeEnabled = newValue
                keyStore.set(newValue, forKey: AppConstants.Keys.Storage.isPrivacyModeEnabled)
            }
        }
    }

    @ObservationIgnored private var _isBiometricEnabled: Bool = {
        return ServiceContainer.shared.resolve((any KeyStoreProtocol).self).object(forKey: AppConstants.Keys.Storage.isBiometricEnabled) as? Bool ?? true
    }()
    
    public var isBiometricEnabled: Bool {
        get {
            access(keyPath: \.isBiometricEnabled)
            return _isBiometricEnabled
        }
        set {
            withMutation(keyPath: \.isBiometricEnabled) {
                _isBiometricEnabled = newValue
                keyStore.set(newValue, forKey: AppConstants.Keys.Storage.isBiometricEnabled)
            }
        }
    }

    // ── 性能与调试 ──
    public var showPerfDashboard = false

    // ── 引导状态 ──
    public var hasShownGraphCoachMark: Bool {
        get {
            return keyStore.bool(forKey: AppConstants.Keys.Storage.hasShownGraphCoachMark)
        }
        set { keyStore.set(newValue, forKey: AppConstants.Keys.Storage.hasShownGraphCoachMark) }
    }

    // ── iCloud 同步偏好 ──
    public var iCloudConflictResolution: String {
        get {
            return keyStore.string(forKey: AppConstants.Keys.Storage.iCloudConflictResolution) ?? "merge"
        }
        set { keyStore.set(newValue, forKey: AppConstants.Keys.Storage.iCloudConflictResolution) }
    }

    public var iCloudAutoSync: Bool {
        get {
            return keyStore.bool(forKey: AppConstants.Keys.Storage.iCloudAutoSync)
        }
        set { keyStore.set(newValue, forKey: AppConstants.Keys.Storage.iCloudAutoSync) }
    }

    // ── 协作用户名 ──
    public var collabUsername: String {
        get {
            return keyStore.string(forKey: AppConstants.Keys.Storage.userName) ?? ""
        }
        set { keyStore.set(newValue, forKey: AppConstants.Keys.Storage.userName) }
    }

    /// 重置
    public func reset() {
        isPrivacyModeEnabled = true
        isBiometricEnabled = true
        showPerfDashboard = false
        hasShownGraphCoachMark = false
        keyStore.removeObject(forKey: AppConstants.Keys.Storage.iCloudConflictResolution)
        keyStore.removeObject(forKey: AppConstants.Keys.Storage.iCloudAutoSync)
        keyStore.removeObject(forKey: AppConstants.Keys.Storage.userName)
    }
}
