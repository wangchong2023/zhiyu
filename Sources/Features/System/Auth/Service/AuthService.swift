// AuthService.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：本文件实现了知识管理系统的身份认证服务 (AuthService)。
// 负责管理用户的登录状态、注册流程以及游客模式的切换。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Observation

/// 身份认证服务
/// 负责管理应用的访问权限，支持多种登录方式及游客模式。
@Observable
@MainActor
public final class AuthService: AuthServiceProtocol {
    
    // MARK: - 状态属性
    
    /// 是否已通过身份认证 (登录成功)
    public var isAuthenticated: Bool {
        AuthSession.shared.isLoggedIn
    }
    
    /// 是否处于游客模式
    public var isGuest: Bool {
        AuthSession.shared.isGuest
    }
    
    /// 当前登录用户 (可选)
    public var currentUser: User? {
        AuthSession.shared.currentUser
    }
    
    // MARK: - 单例与初始化
    
    public static let shared = AuthService()
    
    private init() {
        // 从持久化存储加载状态 (例如 Keychain 或 UserDefaults)
        // 暂时禁用自动登录与游客模式恢复，遵循用户“进入程序进入登录页面”的要求
        /*
        let isAuthenticated = UserDefaults.standard.bool(forKey: "auth.isAuthenticated")
        if isAuthenticated {
            AuthSession.shared.update(user: User(name: "User", email: "user@example.com"))
        }
        let isGuest = UserDefaults.standard.bool(forKey: "auth.isGuest")
        AuthSession.shared.isGuest = isGuest
        */
    }
    
    // MARK: - 核心操作
    
    /// 以游客身份进入系统
    @MainActor
    public func continueAsGuest() {
        AuthSession.shared.update(user: nil)
        AuthSession.shared.isGuest = true
        saveState()
    }
    
    /// 模拟登录操作
    @MainActor
    public func login(identity: String, password: String) async -> Bool {
        // 模拟网络延迟
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        
        // 简单模拟校验
        if !identity.isEmpty && password.count >= 6 {
            let user = User(id: UUID(), name: identity, email: "\(identity.lowercased())@example.com")
            AuthSession.shared.update(user: user)
            saveState()
            return true
        }
        return false
    }
    
    /// 模拟注册操作
    @MainActor
    public func register(phone: String, code: String, password: String) async -> Bool {
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        
        if phone.count >= 11 && code == "123456" && password.count >= 6 {
            let user = User(id: UUID(), name: "User_\(phone.suffix(4))", email: "\(phone)@example.com")
            AuthSession.shared.update(user: user)
            saveState()
            return true
        }
        return false
    }
    
    /// 退出登录
    @MainActor
    public func logout() {
        AuthSession.shared.logout()
        // 登出时同时清除当前选中的笔记本，确保下次进入时从主页开始
        VaultService.shared.exitVault()
        saveState()
    }
    
    // MARK: - 私有方法
    
    private func saveState() {
        UserDefaults.standard.set(isAuthenticated, forKey: "auth.isAuthenticated")
        UserDefaults.standard.set(isGuest, forKey: "auth.isGuest")
    }
}

// MARK: - 数据模型
// User 已移动至 Sources/Features/Auth/Models/User.swift
