//
//  NetworkClient.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/28.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：全局 HTTP 网络客户端，支持自动注入 Bearer Token 以及 401 无感刷新双重拦截。
//

import Foundation

public actor NetworkClient {
    public static let shared = NetworkClient()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    // 无感刷新防并发控制
    private var isRefreshing = false
    private var refreshTask: Task<String, Error>?
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConstants.Network.requestTimeout
        config.timeoutIntervalForResource = 30.0
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }
    
    /// 发起带有数据载荷的请求 (POST, PUT 等)
    public func request<T: Codable, Body: Encodable>(
        path: String,
        method: String = "POST",
        body: Body? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        return try await performRequest(path: path, method: method, body: body, requiresAuth: requiresAuth, isRetry: false)
    }
    
    /// 发起无数据载荷的请求 (GET 等)
    public func request<T: Codable>(
        path: String,
        method: String = "GET",
        requiresAuth: Bool = true
    ) async throws -> T {
        let dummyBody: EmptyData? = nil
        return try await performRequest(path: path, method: method, body: dummyBody, requiresAuth: requiresAuth, isRetry: false)
    }
    
    // MARK: - 内部请求与拦截逻辑
    
    private func performRequest<T: Codable, Body: Encodable>(
        path: String,
        method: String,
        body: Body?,
        requiresAuth: Bool,
        isRetry: Bool
    ) async throws -> T {
        
        // 1. 如果正在刷新，挂起当前请求等待新 token
        if requiresAuth && isRefreshing && !isRetry {
            if let refreshTask = self.refreshTask {
                _ = try await refreshTask.value
            }
        }
        
        guard let url = URL(string: AppConfig.backendBaseURL + path) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue(AppConstants.Network.contentTypeJSON, forHTTPHeaderField: AppConstants.Network.headerContentType)
        
        // 2. 注入 Access Token
        if requiresAuth {
            if let token = try? KeychainService.shared.retrieve(key: AppConstants.Network.jwtTokenKey) {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }
        
        if let body = body {
            request.httpBody = try encoder.encode(body)
        }
        
        // 3. 执行网络请求
        let (data, response) = try await session.data(for: request)
        
        // HTTP 层校验：确保是标准 HTTP 响应（业务层通过 apiResponse.code 判断成功与否）
        guard response is HTTPURLResponse else {
            throw NetworkError.unexpected(L10n.Network.invalidHTTPResponse)
        }
        
        // 4. 解析全局 JSON
        let apiResponse: ApiResponse<T>
        do {
            apiResponse = try decoder.decode(ApiResponse<T>.self, from: data)
        } catch {
            throw NetworkError.decodeFailed(error)
        }
        
        // 5. 判断业务响应与 401 拦截
        if apiResponse.isSuccess {
            if let payload = apiResponse.data {
                return payload
            } else if T.self == EmptyData.self {
                // 如果泛型是 EmptyData 且 data 为空，强转通过
                // swiftlint:disable:next force_cast
                return EmptyData() as! T
            }
            throw NetworkError.unexpected(L10n.Network.missingDataPayload)
        }
        
        // 6. Token 过期处理 (后端业务码 40101)
        if apiResponse.code == 40101 && requiresAuth && !isRetry {
            return try await handleTokenRefreshAndRetry(
                path: path,
                method: method,
                body: body
            )
        }
        
        // 7. 其他统一报错
        throw NetworkError.serverError(apiResponse.code, apiResponse.message)
    }
    
    // MARK: - 无感刷新逻辑 (Refresh Token)
    
    private func handleTokenRefreshAndRetry<T: Codable, Body: Encodable>(
        path: String,
        method: String,
        body: Body?
    ) async throws -> T {
        // 防止多个并发请求同时触发刷新
        if isRefreshing, let existingTask = refreshTask {
            _ = try await existingTask.value
            return try await performRequest(path: path, method: method, body: body, requiresAuth: true, isRetry: true)
        }
        
        isRefreshing = true
        refreshTask = Task {
            defer {
                self.isRefreshing = false
                self.refreshTask = nil
            }
            
            // 拿到长效 Refresh Token
            guard let refreshToken = try? KeychainService.shared.retrieve(key: "refresh_token") else {
                NotificationCenter.default.post(name: .userAuthExpired, object: nil)
                throw NetworkError.unauthorized(L10n.Network.missingRefreshToken)
            }
            
            // 发起刷新请求
            let req = RefreshRequest(refreshToken: refreshToken)
            let refreshURL = AppConfig.backendBaseURL + "/api/auth/refresh"
            var request = URLRequest(url: URL(string: refreshURL) ?? URL(string: "about:blank")!)
            request.httpMethod = "POST"
            request.addValue(AppConstants.Network.contentTypeJSON, forHTTPHeaderField: AppConstants.Network.headerContentType)
            request.httpBody = try encoder.encode(req)
            
            let (data, _) = try await session.data(for: request)
            let response = try decoder.decode(ApiResponse<RefreshResponse>.self, from: data)
            
            if response.isSuccess, let newTokens = response.data {
                // 更新 Keychain
                try KeychainService.shared.store(key: AppConstants.Network.jwtTokenKey, value: newTokens.accessToken)
                try KeychainService.shared.store(key: "refresh_token", value: newTokens.refreshToken)
                return newTokens.accessToken
            } else {
                // 刷新失败（如重放攻击 40103，或者已过期），强制退登
                try? KeychainService.shared.delete(key: AppConstants.Network.jwtTokenKey)
                try? KeychainService.shared.delete(key: "refresh_token")
                NotificationCenter.default.post(name: .userAuthExpired, object: nil)
                throw NetworkError.unauthorized(L10n.Network.sessionInvalidated)
            }
        }
        
        // 等待刷新完成并重试原请求
// swiftlint:disable:next force_unwrapping
        _ = try await refreshTask!.value
        return try await performRequest(path: path, method: method, body: body, requiresAuth: true, isRetry: true)
    }
}

public extension Notification.Name {
    /// 广播：用户认证信息已完全过期失效，UI 应该跳转回登录页
    static let userAuthExpired = Notification.Name("com.zhiyu.app.userAuthExpired")
}
