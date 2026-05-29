//
//  AuthService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：实现 Auth 模块的核心业务逻辑服务，通过 NetworkClient 与后端真实交互。
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
    
    private init() {}

    // MARK: - 测试辅助

    #if DEBUG
    /// 单元测试用：强制启用 mock backend 模式，无需设置 ProcessInfo 启动参数
    public static var forceMockBackend = false
    #endif

    private var isMockBackend: Bool { return false }

    // MARK: - 核心操作
    
    /// 以游客身份进入系统
    public func continueAsGuest() {
        AuthSession.shared.update(user: nil)
        AuthSession.shared.isGuest = true
        saveState()
    }
    
    /// 统一密码登录操作
    @MainActor

    /// login
    /// /// - Parameter identity: identity
    /// /// - Parameter password: password
    /// /// - Returns: 是否成功
    public func login(identity: String, password: String) async -> Bool {
        #if DEBUG
        if isMockBackend {
            let response = LoginResponse(
                user: UserDTO(id: UUID().uuidString, name: identity, phone: identity, email: nil, avatar: nil),
                tokens: TokenDTO(accessToken: "mock_jwt_access_token", refreshToken: "mock_jwt_refresh_token", accessExpireAt: 0, refreshExpireAt: 0),
                isNewUser: false,
                totpRequired: false
            )
            return await handleSuccessfulLogin(response: response, identity: identity)
        }
        #endif
        let req = LoginRequest.password(username: identity, password: password)
        do {
            let response: LoginResponse = try await NetworkClient.shared.request(
                path: "/api/v1/auth/login",
                method: "POST",
                body: req,
                requiresAuth: false
            )
            
            return await handleSuccessfulLogin(response: response, identity: identity)
        } catch {
            print("❌ [AuthService] 密码登录失败: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 发送注册/登录验证码
    @MainActor

    /// 发送SmsCode
    /// /// - Parameter phone: phone
    /// /// - Parameter scene: scene
    /// /// - Returns: 是否成功
    public func sendSmsCode(phone: String, scene: String) async -> Bool {
        let req = SendSmsRequest(phone: phone, scene: scene)
        do {
            let _: EmptyData = try await NetworkClient.shared.request(
                path: "/api/v1/auth/sms/send",
                method: "POST",
                body: req,
                requiresAuth: false
            )
            return true
        } catch {
            print("❌ [AuthService] 发送验证码失败: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 手机号+验证码登录/注册操作
    @MainActor

    /// 注册
    /// /// - Parameter phone: phone
    /// /// - Parameter code: code
    /// /// - Parameter password: password
    /// /// - Returns: 是否成功
    public func register(phone: String, code: String, password: String) async -> Bool {
        let req = LoginRequest.sms(phone: phone, code: code)
        do {
            let response: LoginResponse = try await NetworkClient.shared.request(
                path: "/api/v1/auth/login",
                method: "POST",
                body: req,
                requiresAuth: false
            )
            
            return await handleSuccessfulLogin(response: response, identity: phone)
        } catch {
            print("❌ [AuthService] 验证码登录失败: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 退出登录
    @MainActor

    /// logout
    public func logout() {
        AuthSession.shared.logout()
        VaultService.shared.exitVault()
        saveState()
        
        Task {
            // 尝试通知后端登出并吊销 RefreshToken
            if let refreshToken = try? KeychainService.shared.retrieve(key: "refresh_token") {
                let req = RefreshRequest(refreshToken: refreshToken)
                let _: EmptyData? = try? await NetworkClient.shared.request(
                    path: "/api/v1/auth/logout",
                    method: "POST",
                    body: req,
                    requiresAuth: true
                )
            }
            
            // 清理本地状态
            try? KeychainService.shared.delete(key: AppConstants.Network.jwtTokenKey)
            try? KeychainService.shared.delete(key: "refresh_token")
        }
    }
    
    // MARK: - 多渠道中台统一登录
    
    @MainActor

    /// login
    /// /// - Returns: 是否成功
    public func login(using strategy: any AuthStrategy) async -> Bool {
        do {
            #if DEBUG
            if isMockBackend {
                // 在 Mock 模式下，直接构造测试凭证，跳过底层 SDK (如 FaceID) 唤起，防止 UI 测试阻塞
                let mockCred = AuthCredential(identityType: strategy.identityType, identifier: "mock_sub_123", credential: "mock_jwt_token", extraInfo: ["nickname": "Mock User"])
                return try await sendAuthRequestToBackend(mockCred)
            }
            #endif
            
            // 1. 驱动客户端 SDK 获取凭证
            let credential = try await strategy.acquireCredentials()
            
            // 2. 发送至后端校验
            return try await sendAuthRequestToBackend(credential)
        } catch {
            print("❌ [AuthService] 统一认证失败: \(error.localizedDescription)")
            return false
        }
    }
    
    private func sendAuthRequestToBackend(_ cred: AuthCredential) async throws -> Bool {
        #if DEBUG
        if isMockBackend {
            let name = cred.extraInfo?["nickname"] ?? "ZhiYu User"
            let response = LoginResponse(
                user: UserDTO(id: UUID().uuidString, name: name, phone: nil, email: cred.extraInfo?["email"], avatar: nil),
                tokens: TokenDTO(accessToken: "mock_jwt_access_token_\(UUID().uuidString)", refreshToken: "mock_jwt_refresh_token_\(UUID().uuidString)", accessExpireAt: Int(Date().timeIntervalSince1970) + 3600, refreshExpireAt: Int(Date().timeIntervalSince1970) + 2592000),
                isNewUser: false,
                totpRequired: false
            )
            return await handleSuccessfulLogin(response: response, identity: name)
        }
        #endif
        
        let path: String
        let reqBody: Any
        
        switch cred.identityType {
        case "apple":
            path = "/api/v1/auth/apple"
            reqBody = OAuthAppleRequest(code: cred.credential, state: cred.extraInfo?["state"], idToken: cred.extraInfo?["idToken"])
        case "wechat":
            path = "/api/v1/auth/wechat"
            reqBody = OAuthWeChatRequest(code: cred.credential, state: cred.extraInfo?["state"])
        case "google":
            path = "/api/v1/auth/google"
            reqBody = OAuthGoogleRequest(idToken: cred.extraInfo?["idToken"] ?? "")
        case "github":
            path = "/api/v1/auth/github"
            reqBody = OAuthGitHubRequest(code: cred.credential, state: cred.extraInfo?["state"])
        case "carrier":
            path = "/api/v1/auth/carrier"
            reqBody = CarrierAuthRequest(
                carrierToken: cred.extraInfo?["carrierToken"] ?? "",
                appKey: cred.extraInfo?["appKey"] ?? "",
                privacyConsent: cred.extraInfo?["privacyConsent"] == "true"
            )
        default:
            print("❌ 不支持的第三方登录策略: \(cred.identityType)")
            return false
        }
        
        // 此处为了兼容，直接使用底层 URLSession 或扩展 NetworkClient 处理字典
        // 使用 NetworkClient 进行动态泛型调用
        do {
            let response: LoginResponse
            
            if let appleReq = reqBody as? OAuthAppleRequest {
                response = try await NetworkClient.shared.request(path: path, method: "POST", body: appleReq, requiresAuth: false)
            } else if let wechatReq = reqBody as? OAuthWeChatRequest {
                response = try await NetworkClient.shared.request(path: path, method: "POST", body: wechatReq, requiresAuth: false)
            } else if let googleReq = reqBody as? OAuthGoogleRequest {
                response = try await NetworkClient.shared.request(path: path, method: "POST", body: googleReq, requiresAuth: false)
            } else if let githubReq = reqBody as? OAuthGitHubRequest {
                response = try await NetworkClient.shared.request(path: path, method: "POST", body: githubReq, requiresAuth: false)
            } else if let carrierReq = reqBody as? CarrierAuthRequest {
                response = try await NetworkClient.shared.request(path: path, method: "POST", body: carrierReq, requiresAuth: false)
            } else {
                return false
            }
            
            let name = cred.extraInfo?["nickname"] ?? "ZhiYu User"
            return await handleSuccessfulLogin(response: response, identity: name)
        } catch {
            print("❌ sendAuthRequestToBackend 失败: \(error)")
            throw error
        }
    }
    
    // MARK: - 私有辅助方法
    
    @MainActor
    private func handleSuccessfulLogin(response: LoginResponse, identity: String) -> Bool {
        do {
            // 写入本地安全区
            try KeychainService.shared.store(key: AppConstants.Network.jwtTokenKey, value: response.tokens.accessToken)
            if let refresh = response.tokens.refreshToken {
                try KeychainService.shared.store(key: "refresh_token", value: refresh)
            }
        } catch {
            print("❌ [AuthService] 存储 Token 失败: \(error.localizedDescription)")
            #if DEBUG
            if isMockBackend {
                print("⚠️ [AuthService] Mock 模式下忽略 Keychain 写入失败，强行通过登录")
            } else {
                return false
            }
            #else
            return false
            #endif
        }
        
        // 根据后端返回的数据构造本地 User
        let user = User(
            id: UUID(uuidString: response.user.id) ?? UUID(),
            name: response.user.name,
            email: response.user.email ?? "",
            avatarURL: response.user.avatar.flatMap { URL(string: $0) }
        )
        AuthSession.shared.update(user: user)
        
        saveState()
        return true
    }
    
    private func getDeviceId() -> String {
        let key = "zhiyu_device_id"
        if let savedId = UserDefaults.standard.string(forKey: key) {
            return savedId
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }
    
    private func saveState() {
        UserDefaults.standard.set(isAuthenticated, forKey: AppConstants.Keys.Storage.authIsAuthenticated)
        UserDefaults.standard.set(isGuest, forKey: AppConstants.Keys.Storage.authIsGuest)
    }
}

// MARK: - 数据模型
// User 已移动至 Sources/Features/Auth/Models/User.swift
