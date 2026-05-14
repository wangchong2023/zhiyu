// AuthSession.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了全局身份认证会话模型，负责维护当前登录用户的状态。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Observation

/// 全局身份认证会话
/// 采用 Swift 6 @Observable 宏，提供响应式的登录状态追踪
@Observable
public final class AuthSession {
    // MARK: - 状态属性
    
    /// 当前登录用户
    public var currentUser: User?
    
    /// 是否已登录
    public var isLoggedIn: Bool {
        currentUser != nil
    }
    
    /// 是否为游客模式 (临时保留，适配现有逻辑)
    public var isGuest: Bool = false
    
    // MARK: - 单例
    
    /// 全局共享实例
    public static let shared = AuthSession()
    
    private init() {
        // 后续可在此处添加持久化状态恢复逻辑
    }
    
    // MARK: - 核心操作
    
    /// 更新当前用户
    /// - Parameter user: 新的用户对象
    public func update(user: User?) {
        self.currentUser = user
        self.isGuest = false
    }
    
    /// 退出登录
    public func logout() {
        self.currentUser = nil
        self.isGuest = false
    }
}
