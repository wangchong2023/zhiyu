//
//  GitHubAuthStrategyTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 GitHubAuthStrategy 开展自动化单元测试验证。
//
import XCTest
@testable import ZhiYu

@MainActor
final class GitHubAuthStrategyTests: XCTestCase {

    func testGitHubAuthIdentityType() {
        let strategy = GitHubAuthStrategy()
        XCTAssertEqual(strategy.identityType, "github")
    }
    
    func testGitHubAuthReturnsMockOrThrowsError() async {
        let strategy = GitHubAuthStrategy()
        #if DEBUG
        do {
            let credential = try await strategy.acquireCredentials()
            XCTAssertEqual(credential.identityType, "github")
            XCTAssertEqual(credential.identifier, "mock_github_user_id")
            XCTAssertEqual(credential.extraInfo?["nickname"], "GitHub Mock User")
            XCTAssertFalse(credential.credential.isEmpty)
        } catch {
            XCTFail("Debug 模式下 GitHub 未配置 ClientID 应当安全降级为 Mock 登录，不应抛出错误: \(error)")
        }
        #else
        do {
            _ = try await strategy.acquireCredentials()
            XCTFail("GitHub 未配置时在 Release 模式下应该抛出错误")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "GitHubAuthStrategy")
            XCTAssertEqual(error.code, -99)
        } catch {
            XCTFail("抛出的不是预期的 NSError: \(error)")
        }
        #endif
    }
}
