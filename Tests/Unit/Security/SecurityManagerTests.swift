// SecurityManagerTests.swift
//
// 作者: Wang Chong
// 功能说明: [P0] 安全加固：验证 SecurityManager 的核心加密能力，确保数据指纹与全盘内容防护逻辑的可靠性。
// 版本: 1.0
// 日期: 2026-05-16
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import XCTest
import CryptoKit
@testable import ZhiYu

final class SecurityManagerTests: XCTestCase {
    
    private var securityManager: SecurityManager!
    
    override func setUp() {
        super.setUp()
        securityManager = SecurityManager.shared
    }
    
    override func tearDown() {
        securityManager = nil
        super.tearDown()
    }
    
    // MARK: - AES-GCM 加解密测试
    
    func testAESGCMEncryptionAndDecryption() throws {
        let originalText = "Hello, ZhiYu Security! 🚀"
        
        // 1. 测试加密
        let encryptedBase64 = try securityManager.encrypt(originalText)
        XCTAssertNotEqual(originalText, encryptedBase64, "加密后的内容不应与原文相同")
        XCTAssertFalse(encryptedBase64.isEmpty, "加密产物不应为空")
        
        // 2. 测试解密
        let decryptedText = try securityManager.decrypt(encryptedBase64)
        XCTAssertEqual(originalText, decryptedText, "解密后的内容应与原文完全一致")
    }
    
    func testEncryptionProducesDifferentResultsForSameInput() throws {
        let text = "Static Content"
        let encrypted1 = try securityManager.encrypt(text)
        let encrypted2 = try securityManager.encrypt(text)
        
        // 由于 AES-GCM 使用随机 Nonce，每次加密结果应不同 (Base64 包含 Combined Data)
        XCTAssertNotEqual(encrypted1, encrypted2, "由于使用了随机 Nonce，每次加密的结果应具有差异性")
    }
    
    // MARK: - HMAC 完整性校验测试
    
    func testHMACIntegrityCheck() throws {
        // 创建临时测试文件
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("integrity_test.db")
        let content = "Fake Database Content".data(using: .utf8)!
        try content.write(to: fileURL)
        
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        // 1. 生成并保存签名
        securityManager.updateSignature(for: fileURL)
        
        // 2. 验证初始状态 (应通过)
        XCTAssertTrue(securityManager.verifyIntegrity(for: fileURL), "初始生成的签名应验证通过")
        
        // 3. 篡改文件内容
        let corruptedContent = "Corrupted Data".data(using: .utf8)!
        try corruptedContent.write(to: fileURL)
        
        // 4. 验证篡改后状态 (应失败)
        XCTAssertFalse(securityManager.verifyIntegrity(for: fileURL), "文件被篡改后，签名验证应失败")
    }
    
    // MARK: - 密钥管理测试
    
    func testDatabasePassphrasePersistence() {
        let passphrase1 = securityManager.getDatabasePassphrase()
        let passphrase2 = securityManager.getDatabasePassphrase()
        
        XCTAssertFalse(passphrase1.isEmpty)
        XCTAssertEqual(passphrase1, passphrase2, "密钥一旦生成并存储于 Keychain，后续获取应保持一致")
    }
}
