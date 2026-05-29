//
//  AppleAuthStrategyTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 AppleAuthStrategy 开展自动化单元测试验证。
//
import XCTest
@testable import ZhiYu

@MainActor
final class AppleAuthStrategyTests: XCTestCase {

    var strategy: AppleAuthStrategy!

    override func setUp() {
        super.setUp()
        strategy = AppleAuthStrategy()
    }

    override func tearDown() {
        strategy = nil
        super.tearDown()
    }

    func testAppleAuthIdentityType() {
        XCTAssertEqual(strategy.identityType, "apple")
    }

    func testAcquireCredentialsInitiatesAuthorization() async {
        do {
            let _ = try await strategy.acquireCredentials()
            XCTFail("单元测试环境无 Apple ID 授权 UI，应抛出错误")
        } catch {
            XCTAssertNotNil(error, "应抛出 ASAuthorization 相关错误")
        }
    }
}
