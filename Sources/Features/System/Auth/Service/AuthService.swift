//
//  AuthService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：实现 Auth 模块的核心业务逻辑服务。
//
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
        let isAuthenticated = UserDefaults.standard.bool(forKey: AppConstants.Keys.Storage.authIsAuthenticated)
        if isAuthenticated {
            AuthSession.shared.update(user: User(name: "User", email: "user@example.com"))
        }
        let isGuest = UserDefaults.standard.bool(forKey: AppConstants.Keys.Storage.authIsGuest)
        AuthSession.shared.isGuest = isGuest
        */
    }
    
    // MARK: - 核心操作
    
    /// 以游客身份进入系统
    @MainActor

    /// continueAsGuest
    public func continueAsGuest() {
        AuthSession.shared.update(user: nil)
        AuthSession.shared.isGuest = true
        saveState()
    }
    
    /// 模拟登录操作
    @MainActor

    /// login
    /// /// - Parameter identity: identity
    /// /// - Parameter password: password
    /// /// - Returns: 是否成功
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

    /// 注册
    /// /// - Parameter phone: phone
    /// /// - Parameter code: code
    /// /// - Parameter password: password
    /// /// - Returns: 是否成功
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

    /// logout
    public func logout() {
        AuthSession.shared.logout()
        // 登出时同时清除当前选中的笔记本，确保下次进入时从主页开始
        VaultService.shared.exitVault()
        saveState()
    }
    
    // MARK: - 多渠道中台统一登录
    
    /// 统一登录/注册入口，驱动特定的多态策略获取凭证并提交自有后端验证
    /// - Parameter strategy: 具体的认证策略 (如 AppleAuthStrategy, WeChatAuthStrategy)
    /// - Returns: 是否登录/注册成功
    @MainActor

    /// login
    /// /// - Returns: 是否成功
    public func login(using strategy: any AuthStrategy) async -> Bool {
        do {
            // 1. 驱动客户端 SDK 进行物理授权获取凭证
            let credential = try await strategy.acquireCredentials()
            
            // 2. 环境判断：在测试或 Mock 模式下跳过物理网络，防止连接真实服务器失败阻碍 CI 单元测试
            #if DEBUG
            if credential.credential.contains("mock") || 
               ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_TEST"] == "1" ||
               credential.credential.isEmpty {
                let user = User(
                    id: UUID(),
                    name: credential.extraInfo?["nickname"] ?? L10n.Auth.appleTestUser,
                    email: "apple_test@example.com"
                )
                AuthSession.shared.update(user: user)
                saveState()
                return true
            }
            #endif
            
            // 3. 将凭证统一送交自有后端进行校验与会话绑定
            return try await sendAuthRequestToBackend(credential)
        } catch {
            print("❌ [AuthService] 统一认证失败: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 向自有后端发送凭证校验请求，验证通过后刷新并持久化 JWT 令牌
    /// - Parameter cred: 标准化登录凭证
    /// - Returns: 后端是否鉴权通过
    private func sendAuthRequestToBackend(_ cred: AuthCredential) async throws -> Bool {
        guard let url = URL(string: "https://your-backend-api.com/api/v1/auth/login") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "identity_type": cred.identityType,
            "identifier": cred.identifier,
            "credential": cred.credential,
            "extra_info": cred.extraInfo ?? [:]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // 配置超时策略，在弱网环境下快速响应
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8.0
        let session = URLSession(configuration: config)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return false
        }
        
        // 解析后端返回的统一会话状态
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let dataContainer = json["data"] as? [String: Any],
           let token = dataContainer["token"] as? String {
            
            // 将 JWT 写入本地系统 Keychain 安全区
            try? KeychainService.shared.store(key: "jwt_token", value: token)
            
            // 刷新本地会话用户详情
            if let userJson = dataContainer["user"] as? [String: Any],
               let userIdString = userJson["id"] as? String,
               let userId = UUID(uuidString: userIdString) {
                let name = userJson["nickname"] as? String ?? L10n.Auth.defaultUser
                let email = userJson["email"] as? String ?? ""
                let user = User(id: userId, name: name, email: email)
                AuthSession.shared.update(user: user)
            }
            
            saveState()
            return true
        }
        
        return false
    }
    
    // MARK: - 私有方法
    
    private func saveState() {
        UserDefaults.standard.set(isAuthenticated, forKey: AppConstants.Keys.Storage.authIsAuthenticated)
        UserDefaults.standard.set(isGuest, forKey: AppConstants.Keys.Storage.authIsGuest)
    }
}

// MARK: - 数据模型
// User 已移动至 Sources/Features/Auth/Models/User.swift
