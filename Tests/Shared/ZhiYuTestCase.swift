//
//  ZhiYuTestCase.swift
//  ZhiYuTests
//
//  Created by Antigravity on 2026/06/24.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Tests/Shared] 测试基础设施
//  核心职责：所有 ZhiYu 测试用例的统一基类，自动在 setUp 中搭建 Mock DI 环境，
//           消除测试漏调 setupFullMockEnvironment() 导致的 DI 崩溃风险。
//

import XCTest
@testable import ZhiYu

/// ZhiYu 测试基类——自动注册 Mock DI 容器。
///
/// 继承此类的测试用例无需手动调用 `setupFullMockEnvironment()`，
/// 基类已在 `setUp()` 中自动完成 DI 注册。
///
/// 如果测试不需要 DI（纯逻辑测试），可覆写 `needsDIContainer` 返回 `false`。
open class ZhiYuTestCase: XCTestCase {

    /// 子类覆写此属性返回 `false` 以跳过 DI 注册（纯逻辑测试、快照测试等）。
    open var needsDIContainer: Bool { true }

    open override func setUp() async throws {
        try await super.setUp()
        if needsDIContainer {
            await MainActor.run {
                setupFullMockEnvironment()
            }
        }
    }
}
