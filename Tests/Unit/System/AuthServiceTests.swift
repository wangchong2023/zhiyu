//
//  AuthServiceTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 AuthService 开展自动化单元测试验证。
//
import XCTest
@testable import ZhiYu

@MainActor
final class AuthServiceTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        setupFullMockEnvironment()

        AuthSession.shared.logout()
        try? KeychainService.shared.delete(key: AppConstants.Network.jwtTokenKey)
        try? KeychainService.shared.delete(key: "refresh_token")
    }

    override func tearDown() async throws {
        AuthSession.shared.logout()
        // ServiceContainer.reset() 由生产 DI 链保护，不允许清空
        // DatabaseManager.reset() 会关闭数据库，导致后续测试访问已关闭连接
        try await super.tearDown()
    }

    // MARK: - 登出测试

    func testLogoutClearsState() {
        AuthSession.shared.update(user: User(id: UUID(), name: "Test User", email: "test@example.com"))
        XCTAssertTrue(AuthService.shared.isAuthenticated)

        AuthService.shared.logout()

        XCTAssertFalse(AuthService.shared.isAuthenticated)
        XCTAssertNil(AuthService.shared.currentUser)
    }

    func testLogoutClearsGuestFlag() {
        AuthSession.shared.isGuest = true
        XCTAssertTrue(AuthService.shared.isGuest)

        AuthService.shared.logout()

        XCTAssertFalse(AuthService.shared.isGuest)
    }

    // MARK: - 游客模式测试

    func testContinueAsGuestSetsGuestFlag() {
        AuthService.shared.continueAsGuest()

        let expectation = XCTestExpectation(description: "等待游客登录异步完成")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(AuthService.shared.isGuest)
    }

    // MARK: - 统一第三方登录测试 (DEBUG Mock)

    func testLoginWithCarrierStrategyInDebug() async {
        #if DEBUG
        AuthService.forceMockBackend = true
        defer { AuthService.forceMockBackend = false }
        let success = await AuthService.shared.login(using: CarrierAuthStrategy())
        XCTAssertTrue(success, "DEBUG 模式下 Carrier Mock 登录应成功")
        #endif
    }

    func testLoginWithGitHubStrategyInDebug() async {
        #if DEBUG
        AuthService.forceMockBackend = true
        defer { AuthService.forceMockBackend = false }
        let success = await AuthService.shared.login(using: GitHubAuthStrategy())
        XCTAssertTrue(success, "DEBUG 模式下 GitHub Mock 登录应成功")
        #endif
    }

    func testLoginWithWeChatStrategyInDebug() async {
        #if DEBUG
        AuthService.forceMockBackend = true
        defer { AuthService.forceMockBackend = false }
        let success = await AuthService.shared.login(using: WeChatAuthStrategy())
        XCTAssertTrue(success, "DEBUG 模式下 WeChat Mock 登录应成功")
        #endif
    }

    // MARK: - 密码/验证码登录网络失败测试

    func testPasswordLoginFailsWithoutNetwork() async {
        #if DEBUG
        AuthService.forceMockBackend = false
        #endif
        let success = await AuthService.shared.login(identity: "testuser", password: "testpass")
        XCTAssertFalse(success, "无后端服务时密码登录应返回 false")
    }

    func testSmsSendFailsWithoutNetwork() async {
        let success = await AuthService.shared.sendSmsCode(phone: "13800138000", scene: "login")
        XCTAssertFalse(success, "无后端服务时发送验证码应返回 false")
    }

    func testSmsCodeLoginFailsWithoutNetwork() async {
        let success = await AuthService.shared.register(phone: "13800138000", code: "123456", password: "")
        XCTAssertFalse(success, "无后端服务时验证码登录应返回 false")
    }
}

// MockVaultDatabaseSwitcher 已移至 Tests/Shared/TestMocks.swift 统一管理
