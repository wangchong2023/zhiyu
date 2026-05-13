// AuthSession.swift
//
// 作者: Wang Chong
// 功能说明: 认证会话管理，负责维护当前登录状态与用户信息。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Observation

/// 认证会话中心
/// 驱动全局登录状态切换，作为 App 层的守门员。
@Observable
@MainActor
public final class AuthSession {
    /// 当前登录的用户
    public var currentUser: User?
    
    /// 是否已登录
    public var isLoggedIn: Bool {
        currentUser != nil
    }
    
    /// 全局单例
    public static let shared = AuthSession()
    
    private init() {
        // 后续可在此加载本地存储的持久化 Token
        #if DEBUG
        // 开发模式下默认注入一个模拟用户
        // self.currentUser = User(name: "Constantine", email: "constantine@zhiyu.ai")
        #endif
    }
    
    /// 模拟登录
    public func login(user: User) {
        self.currentUser = user
    }
    
    /// 登出
    public func logout() {
        self.currentUser = nil
    }
}
