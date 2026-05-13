// AuthService.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了知识管理系统的身份认证服务 (AuthService)。
// 负责管理用户的登录状态、注册流程以及游客模式的切换。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Observation

/// 身份认证服务
/// 负责管理应用的访问权限，支持多种登录方式及游客模式。
@Observable
@MainActor
public final class AuthService {
    
    // MARK: - 状态属性
    
    /// 是否已通过身份认证 (登录成功)
    public var isAuthenticated: Bool = false
    
    /// 是否处于游客模式
    public var isGuest: Bool = false
    
    /// 当前登录用户 (可选)
    public var currentUser: User?
    
    // MARK: - 单例与初始化
    
    public static let shared = AuthService()
    
    private init() {
        // 从持久化存储加载状态 (例如 Keychain 或 UserDefaults)
        self.isAuthenticated = UserDefaults.standard.bool(forKey: "auth.isAuthenticated")
        self.isGuest = UserDefaults.standard.bool(forKey: "auth.isGuest")
    }
    
    // MARK: - 核心操作
    
    /// 以游客身份进入系统
    @MainActor
    public func continueAsGuest() {
        self.isGuest = true
        self.isAuthenticated = false
        saveState()
    }
    
    /// 模拟登录操作
    @MainActor
    public func login(identity: String, password: String) async -> Bool {
        // 模拟网络延迟
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        
        // 简单模拟校验
        if !identity.isEmpty && password.count >= 6 {
            self.isAuthenticated = true
            self.isGuest = false
            self.currentUser = User(id: UUID(), name: identity, avatar: "person.circle.fill")
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
            self.isAuthenticated = true
            self.isGuest = false
            self.currentUser = User(id: UUID(), name: phone, avatar: "person.circle.fill")
            saveState()
            return true
        }
        return false
    }
    
    /// 退出登录
    @MainActor
    public func logout() {
        self.isAuthenticated = false
        self.isGuest = false
        self.currentUser = nil
        saveState()
    }
    
    // MARK: - 私有方法
    
    private func saveState() {
        UserDefaults.standard.set(isAuthenticated, forKey: "auth.isAuthenticated")
        UserDefaults.standard.set(isGuest, forKey: "auth.isGuest")
    }
}

// MARK: - 数据模型

/// 用户信息模型
public struct User: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var avatar: String
}
