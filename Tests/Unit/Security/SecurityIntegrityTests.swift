// SecurityIntegrityTests.swift
//
// 作者: Wang Chong
// 功能说明: 安全管理器完整性校验与密钥管理测试 (@P0)
// 版本: 1.0
// 日期: 2026-05-16
// 版权: Copyright © 2026 Wang Chong. All rights reserved.

import XCTest
@testable import ZhiYu

@MainActor
final class SecurityIntegrityTests: XCTestCase {

    var securityManager: SecurityManager!
    let testFileName = "test_db.sqlite"
    var testFileURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        setupFullMockEnvironment()
        securityManager = SecurityManager.shared
        let tempDir = FileManager.default.temporaryDirectory
        testFileURL = tempDir.appendingPathComponent(testFileName)
        try "Test Data".write(to: testFileURL, atomically: true, encoding: .utf8)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: testFileURL)
        securityManager = nil
        ServiceContainer.shared.reset()
        try super.tearDownWithError()
    }

    // MARK: - Passphrase Tests

    func testDatabasePassphraseGeneration() {
        let key1 = securityManager.getDatabasePassphrase()
        let key2 = securityManager.getDatabasePassphrase()
        
        XCTAssertFalse(key1.isEmpty, "密钥不应为空")
        XCTAssertEqual(key1, key2, "连续调用应返回相同的持久化密钥")
        XCTAssertTrue(key1.contains("-"), "密钥应符合 UUID 组合格式")
    }

    // MARK: - HMAC Integrity Tests

    /// 测试 HMAC 计算与完整性验证
    /// 验证文件生成后其 HMAC 指纹的计算、存储以及初始校验功能。
    func testHMACCalculationAndVerification() async throws {
        // 1. 计算测试文件的 HMAC 签名
        let signature = try await securityManager.calculateHMAC(for: testFileURL)
        XCTAssertFalse(signature.isEmpty, "签名不应为空")
        
        // 2. 保存签名指纹
        await securityManager.saveSignature(signature, forFilePath: testFileURL.path)
        
        // 3. 验证文件的完整性状态应为通过
        let isValid = await securityManager.verifyIntegrity(for: testFileURL)
        XCTAssertTrue(isValid, "原始文件应通过校验")
    }

    /// 测试物理篡改导致的完整性校验失败
    /// 验证当物理文件内容被恶意篡改后，HMAC 指纹校验应能灵敏捕获并返回失败。
    func testIntegrityFailureOnTamper() async throws {
        // 1. 计算并存储初始签名
        let signature = try await securityManager.calculateHMAC(for: testFileURL)
        await securityManager.saveSignature(signature, forFilePath: testFileURL.path)
        
        // 2. 模拟物理篡改，向文件写入篡改后的数据
        try "Tampered Data".write(to: testFileURL, atomically: true, encoding: .utf8)
        
        // 3. 校验被篡改文件的完整性，期望验证失败
        let isValid = await securityManager.verifyIntegrity(for: testFileURL)
        XCTAssertFalse(isValid, "篡改后的文件不应通过校验")
    }
    
    /// 测试数据签名更新机制
    /// 验证更新文件内容后，能够通过主动更新指纹签名来重新恢复完整性校验通过状态。
    func testSignatureUpdate() async throws {
        // 1. 更新当前测试文件的签名指纹
        await securityManager.updateSignature(for: testFileURL)
        let isValid1 = await securityManager.verifyIntegrity(for: testFileURL)
        XCTAssertTrue(isValid1, "更新签名后应能通过校验")
        
        // 2. 修改文件内容，此时校验应当失败
        try "New Data".write(to: testFileURL, atomically: true, encoding: .utf8)
        let isValid2 = await securityManager.verifyIntegrity(for: testFileURL)
        XCTAssertFalse(isValid2, "再次修改后校验应失败")
        
        // 3. 再次更新签名，校验状态应恢复为通过
        await securityManager.updateSignature(for: testFileURL)
        let isValid3 = await securityManager.verifyIntegrity(for: testFileURL)
        XCTAssertTrue(isValid3, "再次更新签名后应通过")
    }
}
