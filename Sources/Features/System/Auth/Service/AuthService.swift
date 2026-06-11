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

    private var isMockBackend: Bool {
        #if DEBUG
        // 优先检查强制 mock 标志（供单元测试使用）
        if Self.forceMockBackend { return true }
        // 其次检查 UI 测试启动参数（与 AppEnvironment 内存数据库 mock 保持一致）
        return CommandLine.arguments.contains("-UITest_MockData")
        #else
        return false
        #endif
    }

    /// 是否处于 Mock 模式下（供视图层与其它服务判定）
    public var isMockMode: Bool {
        isMockBackend
    }

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
    /// - Parameter identity: identity
    /// - Parameter password: password
    /// - Returns: 是否成功
    public func login(identity: String, password: String) async -> Bool {
        #if DEBUG
        if isMockBackend {
            let response = LoginResponse(
                user: UserDTO(id: UUID().uuidString, name: identity, phone: identity, email: nil, avatar: nil),
                tokens: TokenDTO(accessToken: "mock_jwt_access_token", refreshToken: "mock_jwt_refresh_token", accessExpireAt: 0, refreshExpireAt: 0),
                isNewUser: false,
                totpRequired: false
            )
            // mock 路径：handleSuccessfulLogin 是同步函数，无需 await
            return handleSuccessfulLogin(response: response, identity: identity)
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
            
            return handleSuccessfulLogin(response: response, identity: identity)
        } catch {
            Logger.shared.error("[AuthService] ", error: error)
            return false
        }
    }
    
    /// 发送注册/登录验证码
    @MainActor

    /// 发送SmsCode
    /// - Parameter phone: phone
    /// - Parameter scene: scene
    /// - Returns: 是否成功
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
            Logger.shared.error("[AuthService] ", error: error)
            return false
        }
    }
    
    /// 手机号+验证码登录/注册操作
    @MainActor

    /// 注册
    /// - Parameter phone: phone
    /// - Parameter code: code
    /// - Parameter password: password
    /// - Returns: 是否成功
    public func register(phone: String, code: String, password: String) async -> Bool {
        let req = LoginRequest.sms(phone: phone, code: code)
        do {
            let response: LoginResponse = try await NetworkClient.shared.request(
                path: "/api/v1/auth/login",
                method: "POST",
                body: req,
                requiresAuth: false
            )
            
            return handleSuccessfulLogin(response: response, identity: phone)
        } catch {
            Logger.shared.error("[AuthService] ", error: error)
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
    /// - Returns: 是否成功
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
            Logger.shared.error("[AuthService] ", error: error)
            return false
        }
    }
    
    private func sendAuthRequestToBackend(_ cred: AuthCredential) async throws -> Bool {
        #if DEBUG
        if let result = tryMockAuthRequest(cred) { return result }
        #endif

        let info = resolveAuthRequestInfo(cred)
        let response = try await sendOAuthRequest(path: info.path, reqBody: info.body)
        let name = cred.extraInfo?["nickname"] ?? "ZhiYu User"
        return handleSuccessfulLogin(response: response, identity: name)
    }

    #if DEBUG
    private func tryMockAuthRequest(_ cred: AuthCredential) -> Bool? {
        guard isMockBackend else { return nil }
        let name = cred.extraInfo?["nickname"] ?? "ZhiYu User"
        let response = LoginResponse(
            user: UserDTO(id: UUID().uuidString, name: name, phone: nil, email: cred.extraInfo?["email"], avatar: nil),
            tokens: TokenDTO(accessToken: "mock_jwt_access_token_\(UUID().uuidString)", refreshToken: "mock_jwt_refresh_token_\(UUID().uuidString)", accessExpireAt: Int(Date().timeIntervalSince1970) + 3600, refreshExpireAt: Int(Date().timeIntervalSince1970) + 2592000),
            isNewUser: false,
            totpRequired: false
        )
        return handleSuccessfulLogin(response: response, identity: name)
    }
    #endif

    private struct AuthRequestInfo {
        let path: String
        let body: Any
    }

    private func resolveAuthRequestInfo(_ cred: AuthCredential) -> AuthRequestInfo {
        switch cred.identityType {
        case "apple": return AuthRequestInfo(path: "/api/v1/auth/apple", body: OAuthAppleRequest(code: cred.credential, state: cred.extraInfo?["state"], idToken: cred.extraInfo?["idToken"]))
        case "wechat": return AuthRequestInfo(path: "/api/v1/auth/wechat", body: OAuthWeChatRequest(code: cred.credential, state: cred.extraInfo?["state"]))
        case "google": return AuthRequestInfo(path: "/api/v1/auth/google", body: OAuthGoogleRequest(idToken: cred.extraInfo?["idToken"] ?? ""))
        case "github": return AuthRequestInfo(path: "/api/v1/auth/github", body: OAuthGitHubRequest(code: cred.credential, state: cred.extraInfo?["state"]))
        case "carrier": return AuthRequestInfo(path: "/api/v1/auth/carrier", body: CarrierAuthRequest(carrierToken: cred.extraInfo?["carrierToken"] ?? "", appKey: cred.extraInfo?["appKey"] ?? "", privacyConsent: cred.extraInfo?["privacyConsent"] == "true"))
        default:
            Logger.shared.error(": \(cred.identityType)")
            return AuthRequestInfo(path: "", body: "")
        }
    }

    private func sendOAuthRequest(path: String, reqBody: Any) async throws -> LoginResponse {
        if let appleReq = reqBody as? OAuthAppleRequest {
            return try await NetworkClient.shared.request(path: path, method: "POST", body: appleReq, requiresAuth: false)
        }
        if let wechatReq = reqBody as? OAuthWeChatRequest {
            return try await NetworkClient.shared.request(path: path, method: "POST", body: wechatReq, requiresAuth: false)
        }
        if let googleReq = reqBody as? OAuthGoogleRequest {
            return try await NetworkClient.shared.request(path: path, method: "POST", body: googleReq, requiresAuth: false)
        }
        if let githubReq = reqBody as? OAuthGitHubRequest {
            return try await NetworkClient.shared.request(path: path, method: "POST", body: githubReq, requiresAuth: false)
        }
        if let carrierReq = reqBody as? CarrierAuthRequest {
            return try await NetworkClient.shared.request(path: path, method: "POST", body: carrierReq, requiresAuth: false)
        }
        throw NetworkError.unexpected("Unsupported auth request type")
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
            Logger.shared.error("[AuthService]  Token ", error: error)
            #if DEBUG
            if isMockBackend {
                Logger.shared.warning("[AuthService] Mock  Keychain ")
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
    
    // MARK: - 新增的个人信息修改与支付校验方法
    
    /// 更新个人资料
    /// - Parameters:
    ///   - nickname: 昵称
    ///   - avatar: 头像地址（URL字符串）
    /// - Returns: 是否更新成功
    public func updateUserProfile(nickname: String, avatar: String?) async -> Bool {
        #if DEBUG
        if isMockBackend {
            // Mock 模式：直接更新本地缓存，不调用网络
            if let user = AuthSession.shared.currentUser {
                let updated = User(
                    id: user.id,
                    name: nickname,
                    email: user.email,
                    avatarURL: avatar.flatMap { URL(string: $0) } ?? user.avatarURL,
                    planKey: user.planKey,
                    maxVaults: user.maxVaults,
                    maxPages: user.maxPages,
                    maxPlugins: user.maxPlugins
                )
                AuthSession.shared.update(user: updated)
                return true
            }
            return false
        }
        #endif
        
        // 实际请求后端 PUT /api/v1/user/profile 更新昵称和头像
        struct ProfileUpdateRequest: Codable {
            let nick: String
            let avatar: String?
        }
        
        struct ProfileUpdateResponse: Codable {
            let userId: Int64
            let username: String
            let nick: String
            let avatar: String?
            let email: String?
            let mobile: String?
        }
        
        let body = ProfileUpdateRequest(nick: nickname, avatar: avatar)
        do {
            let response: ProfileUpdateResponse = try await NetworkClient.shared.request(
                path: "/api/v1/user/profile",
                method: "PUT",
                body: body,
                requiresAuth: true
            )
            // 同步更新本地 User 缓存
            if let user = AuthSession.shared.currentUser {
                let updated = User(
                    id: user.id,
                    name: response.nick,
                    email: response.email ?? user.email,
                    avatarURL: response.avatar.flatMap { URL(string: $0) },
                    planKey: user.planKey,
                    maxVaults: user.maxVaults,
                    maxPages: user.maxPages,
                    maxPlugins: user.maxPlugins
                )
                AuthSession.shared.update(user: updated)
            }
            return true
        } catch {
            Logger.shared.error("[AuthService] 更新个人资料失败: ", error: error)
            return false
        }
    }
    
    /// 上传头像图片到后端 OSS
    /// - Parameter imageData: 图片的二进制数据（PNG/JPEG）
    /// - Returns: 上传成功后返回的头像 URL 字符串，失败返回 nil
    public func uploadAvatar(imageData: Data) async -> String? {
        #if DEBUG
        if isMockBackend {
            // Mock 模式：返回随机头像 URL
            return "https://api.multiavatar.com/\(UUID().uuidString).png"
        }
        #endif
        
        do {
            // 调用 NetworkClient 的 multipart 上传接口
            let avatarUrl: String = try await NetworkClient.shared.uploadFile(
                path: "/api/v1/user/profile/avatar",
                fileData: imageData,
                fileName: "avatar.png",
                mimeType: "image/png",
                requiresAuth: true
            )
            return avatarUrl
        } catch {
            Logger.shared.error("[AuthService] 上传头像失败: ", error: error)
            return nil
        }
    }
    
    /// 向后端验证 Apple 内购收据并激活 Pro 权益
    /// - Parameters:
    ///   - productId: App Store 商品 ID
    ///   - receiptData: StoreKit 返回的 Base64 编码收据
    ///   - orderNo: 发起购买前系统生成的订单号（可选）
    /// - Returns: 验证并激活成功返回 true
    public func verifyApplePurchase(productId: String, receiptData: String, orderNo: String?) async -> Bool {
        #if DEBUG
        if isMockBackend {
            // Mock 模式：直接本地激活 Pro
            if let user = AuthSession.shared.currentUser {
                let updated = User(
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    avatarURL: user.avatarURL,
                    planKey: "pro",
                    maxVaults: 10,
                    maxPages: 50000,
                    maxPlugins: 999999
                )
                AuthSession.shared.update(user: updated)
                return true
            }
            return false
        }
        #endif
        
        struct VerifyRequest: Codable {
            let productId: String
            let receiptData: String
            let orderNo: String?
        }
        
        struct VerifyResponse: Codable {
            let orderNo: String
            let status: String
            let planKey: String?
        }
        
        let body = VerifyRequest(productId: productId, receiptData: receiptData, orderNo: orderNo)
        do {
            let _: VerifyResponse = try await NetworkClient.shared.request(
                path: "/api/v1/subscriptions/apple/verify",
                method: "POST",
                body: body,
                requiresAuth: true
            )
            // 校验成功后，重新拉取最新用户资料（含套餐限额）
            try await refreshUserProfile()
            return true
        } catch {
            Logger.shared.error("[AuthService] 验证苹果支付凭证失败: ", error: error)
            return false
        }
    }
    
    /// 从后端拉取最新个人资料并更新本地 User 缓存
    /// 在登录成功或支付激活后调用，保证本地数据与后端同步
    public func refreshUserProfile() async throws {
        // 1. 拉取个人基本信息
        struct ProfileResponse: Codable {
            let userId: Int64
            let username: String
            let nick: String
            let avatar: String?
            let email: String?
        }
        
        let profile: ProfileResponse = try await NetworkClient.shared.request(
            path: "/api/v1/user/profile",
            method: "GET",
            requiresAuth: true
        )
        
        // 2. 拉取当前订阅套餐信息
        struct SubscriptionResponse: Codable {
            let planKey: String?
            let quotasJson: String?
        }
        
        var currentPlanKey: String? = "free"
        do {
            let sub: SubscriptionResponse = try await NetworkClient.shared.request(
                path: "/api/v1/subscriptions/me",
                method: "GET",
                requiresAuth: true
            )
            currentPlanKey = sub.planKey ?? "free"
        } catch {
            Logger.shared.warning("[AuthService] 获取当前订阅信息失败，将使用默认配置: \(error)")
        }
        
        // 3. 合并更新本地 User 对象
        if let user = AuthSession.shared.currentUser {
            let updated = User(
                id: user.id,
                name: profile.nick,
                email: profile.email ?? user.email,
                avatarURL: profile.avatar.flatMap { URL(string: $0) },
                planKey: currentPlanKey,
                maxVaults: currentPlanKey == "pro" ? 10 : 2,
                maxPages: currentPlanKey == "pro" ? 50000 : 1000,
                maxPlugins: currentPlanKey == "pro" ? 999999 : 3
            )
            AuthSession.shared.update(user: updated)
        }
    }
}

// MARK: - 数据模型
// User 已移动至 Sources/Features/Auth/Models/User.swift
