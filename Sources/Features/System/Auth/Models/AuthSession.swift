//
//  AuthSession.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：属于 Models 模块，提供相关的结构体或工具支撑。
//
import Foundation
import Observation

/// 全局身份认证会话
/// 采用 Swift 6 @Observable 宏，提供响应式的登录状态追踪
@Observable
@MainActor
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
        // 如果是 UI 测试环境，默认以游客身份直接进入系统，避开 Onboarding 玻璃拟态登录界面以供用例直接进入主界面
        #if DEBUG
        if ProcessInfo.processInfo.environment["UITesting"] == "true" ||
           ProcessInfo.processInfo.arguments.contains("--uitesting") {
            self.isGuest = true
        }
        #endif
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
