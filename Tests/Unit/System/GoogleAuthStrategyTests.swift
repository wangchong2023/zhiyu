//
//  GoogleAuthStrategyTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 GoogleAuthStrategy 开展自动化单元测试验证。
//
import XCTest
@testable import ZhiYu

@MainActor
final class GoogleAuthStrategyTests: XCTestCase {

    var strategy: GoogleAuthStrategy!

    override func setUp() {
        super.setUp()
        strategy = GoogleAuthStrategy()
    }

    override func tearDown() {
        strategy = nil
        super.tearDown()
    }

    func testGoogleAuthReturnsMockCredentialsInDebug() async {
        #if DEBUG
        do {
            let credential = try await strategy.acquireCredentials()
            XCTAssertEqual(credential.identityType, "google")
            XCTAssertEqual(credential.identifier, "mock_google_user_id")
            XCTAssertEqual(credential.extraInfo?["email"], "mock_google_user@gmail.com")
            XCTAssertEqual(credential.extraInfo?["nickname"], "Google Mock User")
            XCTAssertFalse((credential.extraInfo?["idToken"] ?? "").isEmpty)
        } catch {
            XCTFail("Debug 模式下未配置 ClientID 应当安全降级为 Mock 登录，不应抛出错误: \(error)")
        }
        #else
        do {
            _ = try await strategy.acquireCredentials()
            XCTFail("Google SDK 未配置时，Release 模式下应当抛出未配置错误")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "GoogleAuthStrategy")
            XCTAssertEqual(error.code, -99)
        } catch {
            XCTFail("抛出的不是预期的 NSError: \(error)")
        }
        #endif
    }
}
