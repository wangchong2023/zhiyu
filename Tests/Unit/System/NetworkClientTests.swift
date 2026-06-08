//
//  NetworkClientTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 NetworkClient 开展自动化单元测试验证。
//
import XCTest
@testable import ZhiYu

@MainActor
final class NetworkClientTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Clear any leftover state before each test
        try? KeychainService.shared.delete(key: AppConstants.Network.jwtTokenKey)
        try? KeychainService.shared.delete(key: "refresh_token")
    }

    override func tearDownWithError() throws {
        try? KeychainService.shared.delete(key: AppConstants.Network.jwtTokenKey)
        try? KeychainService.shared.delete(key: "refresh_token")
    }

    func testNetworkClientBasicRequest() async throws {
        // Note: For a fully hermetic test, we should inject a MockURLProtocol into NetworkClient's URLSession.
        // For now, this test just verifies the public API signature of NetworkClient.
        XCTAssertNotNil(NetworkClient.shared)
        
        let req = GuestLoginRequest(deviceId: "test-device")
        XCTAssertEqual(req.deviceId, "test-device")
    }
    
    func testTokenStorage() throws {
        do {
            try KeychainService.shared.store(key: AppConstants.Network.jwtTokenKey, value: "fake_jwt")
            let token = try KeychainService.shared.retrieve(key: AppConstants.Network.jwtTokenKey)
            XCTAssertEqual(token, "fake_jwt")
        } catch KeychainError.storeFailed(let status) where status == -34018 {
            throw XCTSkip("Keychain access denied (errSecMissingEntitlement -34018). Skipping test in restricted simulator environment.")
        } catch {
            throw error
        }
    }
}