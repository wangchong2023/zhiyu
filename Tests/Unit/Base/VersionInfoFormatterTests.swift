//
//  VersionInfoFormatterTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/27.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 测试层
//  核心职责：验证 VersionInfoFormatter 在所有输入组合下的格式化输出正确性，
//          覆盖完整链路 Bundle.infoDictionary → UI 展示字符串。

import XCTest
@testable import ZhiYu

final class VersionInfoFormatterTests: XCTestCase {

    // MARK: - versionDisplayString

    func testVersionDisplayString_fullValidData_formatsCorrectly() {
        // Arrange
        let info: [String: Any] = [
            "CFBundleShortVersionString": "1.2.3",
            "CFBundleVersion": "342",
            "GIT_SHORT_HASH": "abc1234"
        ]

        // Act
        let result = VersionInfoFormatter.versionDisplayString(from: info)

        // Assert
        XCTAssertEqual(result, "1.2.3 (342 · abc1234)")
    }

    func testVersionDisplayString_missingHash_usesUnknownFallback() {
        // Arrange
        let info: [String: Any] = [
            "CFBundleShortVersionString": "2.0.0",
            "CFBundleVersion": "500"
        ]

        // Act
        let result = VersionInfoFormatter.versionDisplayString(from: info)

        // Assert
        XCTAssertEqual(result, "2.0.0 (500 · unknown)")
    }

    func testVersionDisplayString_missingVersion_usesDefaultFallback() {
        // Arrange
        let info: [String: Any] = [
            "CFBundleVersion": "10",
            "GIT_SHORT_HASH": "deadbeef"
        ]

        // Act
        let result = VersionInfoFormatter.versionDisplayString(from: info)

        // Assert
        XCTAssertEqual(result, "0.0.0 (10 · deadbeef)")
    }

    func testVersionDisplayString_missingBuild_usesQuestionMark() {
        // Arrange
        let info: [String: Any] = [
            "CFBundleShortVersionString": "3.0.0-beta",
            "GIT_SHORT_HASH": "1234567"
        ]

        // Act
        let result = VersionInfoFormatter.versionDisplayString(from: info)

        // Assert
        XCTAssertEqual(result, "3.0.0-beta (? · 1234567)")
    }

    func testVersionDisplayString_nilDictionary_usesFullFallback() {
        // Act
        let result = VersionInfoFormatter.versionDisplayString(from: nil)

        // Assert
        XCTAssertEqual(result, "0.0.0 (? · unknown)")
    }

    func testVersionDisplayString_emptyDictionary_usesFullFallback() {
        // Act
        let result = VersionInfoFormatter.versionDisplayString(from: [:])

        // Assert
        XCTAssertEqual(result, "0.0.0 (? · unknown)")
    }

    func testVersionDisplayString_devVersion_preservesSuffix() {
        // Arrange: 无 tag 场景下 inject_version.sh 写入 0.0.0-dev
        let info: [String: Any] = [
            "CFBundleShortVersionString": "0.0.0-dev",
            "CFBundleVersion": "342",
            "GIT_SHORT_HASH": "abc1234"
        ]

        // Act
        let result = VersionInfoFormatter.versionDisplayString(from: info)

        // Assert
        XCTAssertEqual(result, "0.0.0-dev (342 · abc1234)")
    }

    // MARK: - buildTimestampString

    func testBuildTimestampString_validISO8601_formatsToLocalShort() {
        // Arrange: inject_version.sh 写入的 UTC ISO 8601 格式
        let info: [String: Any] = [
            "BUILD_TIMESTAMP": "2026-06-27T15:30:00Z"
        ]

        // Act
        let result = VersionInfoFormatter.buildTimestampString(from: info)

        // Assert: 格式应为 "yyyy-MM-dd HH:mm"，具体值取决于本地时区
        // 只验证格式模式，不验证具体时间值（时区差异）
        let pattern = #"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$"#
        XCTAssertTrue(
            result.range(of: pattern, options: .regularExpression) != nil,
            "构建时间格式应为 'yyyy-MM-dd HH:mm'，实际: '\(result)'"
        )
        XCTAssertFalse(result.isEmpty)
    }

    func testBuildTimestampString_nilDictionary_returnsEmpty() {
        // Act
        let result = VersionInfoFormatter.buildTimestampString(from: nil)

        // Assert
        XCTAssertEqual(result, "")
    }

    func testBuildTimestampString_missingKey_returnsEmpty() {
        // Arrange
        let info: [String: Any] = [
            "CFBundleShortVersionString": "1.0"
        ]

        // Act
        let result = VersionInfoFormatter.buildTimestampString(from: info)

        // Assert
        XCTAssertEqual(result, "")
    }

    func testBuildTimestampString_invalidFormat_returnsRawValue() {
        // Arrange: ISO8601DateFormatter 无法解析的格式，应该原样返回
        let info: [String: Any] = [
            "BUILD_TIMESTAMP": "not-a-valid-date"
        ]

        // Act
        let result = VersionInfoFormatter.buildTimestampString(from: info)

        // Assert
        XCTAssertEqual(result, "not-a-valid-date")
    }

    func testBuildTimestampString_emptyString_returnsEmpty() {
        // Arrange
        let info: [String: Any] = [
            "BUILD_TIMESTAMP": ""
        ]

        // Act
        let result = VersionInfoFormatter.buildTimestampString(from: info)

        // Assert: 空字符串不是有效的 ISO 8601，应原样返回空串
        XCTAssertEqual(result, "")
    }

    // MARK: - 穿通场景：模拟 inject_version.sh 完整输出

    func testEndToEnd_injectScriptOutput_rendersCorrectly() {
        // Arrange: 模拟 inject_version.sh 注入后的完整 infoDictionary
        let info: [String: Any] = [
            "CFBundleShortVersionString": "1.2.3",
            "CFBundleVersion": "342",
            "GIT_SHORT_HASH": "abc1234",
            "BUILD_TIMESTAMP": "2026-06-27T15:30:00Z"
        ]

        // Act
        let version = VersionInfoFormatter.versionDisplayString(from: info)
        let buildTime = VersionInfoFormatter.buildTimestampString(from: info)

        // Assert
        XCTAssertEqual(version, "1.2.3 (342 · abc1234)")
        XCTAssertFalse(buildTime.isEmpty, "构建时间不应为空")
        // 验证构建时间格式
        XCTAssertTrue(
            buildTime.range(of: #"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$"#, options: .regularExpression) != nil,
            "构建时间格式: '\(buildTime)'"
        )
    }
}
