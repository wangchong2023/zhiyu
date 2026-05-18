// SecurityIntegrityTests.swift
//
// 作者: Wang Chong
// 功能说明: 安全管理器完整性校验与密钥管理测试 (@P0)
// 版本: 1.0
// 日期: 2026-05-16
// 版权: Copyright © 2026 Wang Chong. All rights reserved.

import XCTest
@testable import ZhiYu

final class SecurityIntegrityTests: XCTestCase {

    var securityManager: SecurityManager!
    let testFileName = "test_db.sqlite"
    var testFileURL: URL!

    override func setUpWithError() throws {
        securityManager = SecurityManager.shared
        let tempDir = FileManager.default.temporaryDirectory
        testFileURL = tempDir.appendingPathComponent(testFileName)
        try "Test Data".write(to: testFileURL, atomically: true, encoding: .utf8)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: testFileURL)
        securityManager = nil
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

    func testHMACCalculationAndVerification() throws {
        let signature = try securityManager.calculateHMAC(for: testFileURL)
        XCTAssertFalse(signature.isEmpty, "签名不应为空")
        
        securityManager.saveSignature(signature, forFileName: testFileName)
        XCTAssertTrue(securityManager.verifyIntegrity(for: testFileURL), "原始文件应通过校验")
    }

    func testIntegrityFailureOnTamper() throws {
        let signature = try securityManager.calculateHMAC(for: testFileURL)
        securityManager.saveSignature(signature, forFileName: testFileName)
        
        // 模拟物理篡改
        try "Tampered Data".write(to: testFileURL, atomically: true, encoding: .utf8)
        
        XCTAssertFalse(securityManager.verifyIntegrity(for: testFileURL), "篡改后的文件不应通过校验")
    }
    
    func testSignatureUpdate() throws {
        securityManager.updateSignature(for: testFileURL)
        XCTAssertTrue(securityManager.verifyIntegrity(for: testFileURL), "更新签名后应能通过校验")
        
        try "New Data".write(to: testFileURL, atomically: true, encoding: .utf8)
        XCTAssertFalse(securityManager.verifyIntegrity(for: testFileURL), "再次修改后校验应失败")
        
        securityManager.updateSignature(for: testFileURL)
        XCTAssertTrue(securityManager.verifyIntegrity(for: testFileURL), "再次更新签名后应通过")
    }
}
