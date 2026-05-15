// SettingsStore.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：全局设置存储，管理隐私模式、安全验证及显示偏好。
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-04
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。
import Foundation
import Observation
import Combine

/// 全局设置存储，管理隐私模式、安全验证及显示偏好。
@MainActor
@Observable
final class SettingsStore {
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    init() {
        AppEventBus.shared.subscribe()
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                if case .clearAllDataRequested = event {
                    self?.reset()
                }
            }
            .store(in: &cancellables)
    }
    // ── 隐私与安全 ──
    @ObservationIgnored private var _isPrivacyModeEnabled: Bool = {
        // 迁移逻辑
        if let old = UserDefaults.standard.object(forKey: "isPrivacyModeEnabled") as? Bool {
            UserDefaults.standard.set(old, forKey: AppConstants.Keys.Storage.isPrivacyModeEnabled)
            UserDefaults.standard.removeObject(forKey: "isPrivacyModeEnabled")
            return old
        }
        return UserDefaults.standard.object(forKey: AppConstants.Keys.Storage.isPrivacyModeEnabled) as? Bool ?? true
    }()
    
    var isPrivacyModeEnabled: Bool {
        get {
            access(keyPath: \.isPrivacyModeEnabled)
            return _isPrivacyModeEnabled
        }
        set {
            withMutation(keyPath: \.isPrivacyModeEnabled) {
                _isPrivacyModeEnabled = newValue
                UserDefaults.standard.set(newValue, forKey: AppConstants.Keys.Storage.isPrivacyModeEnabled)
            }
        }
    }

    @ObservationIgnored private var _isBiometricEnabled: Bool = {
        // 迁移逻辑
        if let old = UserDefaults.standard.object(forKey: "isBiometricEnabled") as? Bool {
            UserDefaults.standard.set(old, forKey: AppConstants.Keys.Storage.isBiometricEnabled)
            UserDefaults.standard.removeObject(forKey: "isBiometricEnabled")
            return old
        }
        return UserDefaults.standard.object(forKey: AppConstants.Keys.Storage.isBiometricEnabled) as? Bool ?? true
    }()
    
    var isBiometricEnabled: Bool {
        get {
            access(keyPath: \.isBiometricEnabled)
            return _isBiometricEnabled
        }
        set {
            withMutation(keyPath: \.isBiometricEnabled) {
                _isBiometricEnabled = newValue
                UserDefaults.standard.set(newValue, forKey: AppConstants.Keys.Storage.isBiometricEnabled)
            }
        }
    }

    // ── 性能与调试 ──
    var showPerfDashboard = false

    // ── 引导状态 ──
    var hasShownGraphCoachMark: Bool {
        get {
            // 迁移逻辑
            if UserDefaults.standard.object(forKey: "hasShownGraphCoachMark") != nil {
                let old = UserDefaults.standard.bool(forKey: "hasShownGraphCoachMark")
                UserDefaults.standard.set(old, forKey: AppConstants.Keys.Storage.hasShownGraphCoachMark)
                UserDefaults.standard.removeObject(forKey: "hasShownGraphCoachMark")
                return old
            }
            return UserDefaults.standard.bool(forKey: AppConstants.Keys.Storage.hasShownGraphCoachMark)
        }
        set { UserDefaults.standard.set(newValue, forKey: AppConstants.Keys.Storage.hasShownGraphCoachMark) }
    }

    // ── iCloud 同步偏好 ──
    var iCloudConflictResolution: String {
        get {
            // 迁移逻辑
            let oldKey = "knowledge-management_conflict_resolution"
            if let old = UserDefaults.standard.string(forKey: oldKey) {
                UserDefaults.standard.set(old, forKey: AppConstants.Keys.Storage.iCloudConflictResolution)
                UserDefaults.standard.removeObject(forKey: oldKey)
                return old
            }
            return UserDefaults.standard.string(forKey: AppConstants.Keys.Storage.iCloudConflictResolution) ?? "merge"
        }
        set { UserDefaults.standard.set(newValue, forKey: AppConstants.Keys.Storage.iCloudConflictResolution) }
    }

    var iCloudAutoSync: Bool {
        get {
            // 迁移逻辑
            let oldKey = "knowledge-management_auto_sync"
            if UserDefaults.standard.object(forKey: oldKey) != nil {
                let old = UserDefaults.standard.bool(forKey: oldKey)
                UserDefaults.standard.set(old, forKey: AppConstants.Keys.Storage.iCloudAutoSync)
                UserDefaults.standard.removeObject(forKey: oldKey)
                return old
            }
            return UserDefaults.standard.bool(forKey: AppConstants.Keys.Storage.iCloudAutoSync)
        }
        set { UserDefaults.standard.set(newValue, forKey: AppConstants.Keys.Storage.iCloudAutoSync) }
    }

    // ── 协作用户名 ──
    var collabUsername: String {
        get {
            // 迁移逻辑 (优先从统一的 userName 键读取)
            let legacyKey = "knowledge-management_username"
            if let legacy = UserDefaults.standard.string(forKey: legacyKey) {
                UserDefaults.standard.set(legacy, forKey: AppConstants.Keys.Storage.userName)
                UserDefaults.standard.removeObject(forKey: legacyKey)
                return legacy
            }
            return UserDefaults.standard.string(forKey: AppConstants.Keys.Storage.userName) ?? ""
        }
        set { UserDefaults.standard.set(newValue, forKey: AppConstants.Keys.Storage.userName) }
    }

    func reset() {
        isPrivacyModeEnabled = true
        isBiometricEnabled = true
        showPerfDashboard = false
        hasShownGraphCoachMark = false
        UserDefaults.standard.removeObject(forKey: AppConstants.Keys.Storage.iCloudConflictResolution)
        UserDefaults.standard.removeObject(forKey: AppConstants.Keys.Storage.iCloudAutoSync)
        UserDefaults.standard.removeObject(forKey: AppConstants.Keys.Storage.userName)
    }
}
