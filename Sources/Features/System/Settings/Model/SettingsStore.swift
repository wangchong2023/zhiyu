//
//  SettingsStore.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：属于 Model 模块，提供相关的结构体或工具支撑。
//
import Foundation
import Observation
import Combine

/// 全局设置存储，管理隐私模式、安全验证及显示偏好。
@MainActor
@Observable
public final class SettingsStore {
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    public init() {}
    // ── 隐私与安全 ──
    @ObservationIgnored private var _isPrivacyModeEnabled: Bool = {
        return UserDefaults.standard.object(forKey: AppConstants.Keys.Storage.isPrivacyModeEnabled) as? Bool ?? true
    }()
    
    public var isPrivacyModeEnabled: Bool {
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
        return UserDefaults.standard.object(forKey: AppConstants.Keys.Storage.isBiometricEnabled) as? Bool ?? true
    }()
    
    public var isBiometricEnabled: Bool {
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
    public var showPerfDashboard = false

    // ── 引导状态 ──
    public var hasShownGraphCoachMark: Bool {
        get {
            return UserDefaults.standard.bool(forKey: AppConstants.Keys.Storage.hasShownGraphCoachMark)
        }
        set { UserDefaults.standard.set(newValue, forKey: AppConstants.Keys.Storage.hasShownGraphCoachMark) }
    }

    // ── iCloud 同步偏好 ──
    public var iCloudConflictResolution: String {
        get {
            return UserDefaults.standard.string(forKey: AppConstants.Keys.Storage.iCloudConflictResolution) ?? "merge"
        }
        set { UserDefaults.standard.set(newValue, forKey: AppConstants.Keys.Storage.iCloudConflictResolution) }
    }

    public var iCloudAutoSync: Bool {
        get {
            return UserDefaults.standard.bool(forKey: AppConstants.Keys.Storage.iCloudAutoSync)
        }
        set { UserDefaults.standard.set(newValue, forKey: AppConstants.Keys.Storage.iCloudAutoSync) }
    }

    // ── 协作用户名 ──
    public var collabUsername: String {
        get {
            return UserDefaults.standard.string(forKey: AppConstants.Keys.Storage.userName) ?? ""
        }
        set { UserDefaults.standard.set(newValue, forKey: AppConstants.Keys.Storage.userName) }
    }

    /// 重置
    public func reset() {
        isPrivacyModeEnabled = true
        isBiometricEnabled = true
        showPerfDashboard = false
        hasShownGraphCoachMark = false
        UserDefaults.standard.removeObject(forKey: AppConstants.Keys.Storage.iCloudConflictResolution)
        UserDefaults.standard.removeObject(forKey: AppConstants.Keys.Storage.iCloudAutoSync)
        UserDefaults.standard.removeObject(forKey: AppConstants.Keys.Storage.userName)
    }
}
