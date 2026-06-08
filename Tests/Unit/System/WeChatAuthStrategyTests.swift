//
//  WeChatAuthStrategyTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 WeChatAuthStrategy 开展自动化单元测试验证。
//
import XCTest
@testable import ZhiYu

@MainActor
final class WeChatAuthStrategyTests: XCTestCase {

    var strategy: WeChatAuthStrategy!

    override func setUp() {
        super.setUp()
        strategy = WeChatAuthStrategy()
    }

    override func tearDown() {
        strategy = nil
        super.tearDown()
    }

    func testAcquireCredentialsReturnsMockOrThrowsError() async {
        #if DEBUG
        do {
            let credential = try await strategy.acquireCredentials()
            XCTAssertEqual(credential.identityType, "wechat")
            XCTAssertEqual(credential.identifier, "mock_wechat_openid")
            XCTAssertEqual(credential.extraInfo?["nickname"], "WeChat Mock User")
            XCTAssertFalse(credential.credential.isEmpty)
        } catch {
            XCTFail("Debug 模式下未安装微信应当安全降级为 Mock 登录，不应抛出错误: \(error)")
        }
        #else
        do {
            let _ = try await strategy.acquireCredentials()
            XCTFail("微信未安装时在 Release 模式下应该抛出错误")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "WeChatAuthStrategy")
            XCTAssertEqual(error.code, -1)
        } catch {
            XCTFail("抛出的不是预期的 NSError: \(error)")
        }
        #endif
    }
}