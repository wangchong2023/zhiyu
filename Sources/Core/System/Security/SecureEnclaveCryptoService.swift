//
//  SecureEnclaveCryptoService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0.5] 系统集成层
//  核心职责：实现 SecureEnclaveCrypto 模块的核心业务逻辑服务。
//
import Foundation
import CryptoKit

/// 硬件安全芯片加解密服务 (SecureEnclaveCryptoService)
/// 专为第三方敏感令牌提供 Secure Enclave 物理层级锁死，杜绝文件级破解与异地克隆。
final class SecureEnclaveCryptoService: Sendable {
    /// 全局唯一的线程安全单例
    static let shared = SecureEnclaveCryptoService()
    
    /// 用于在 UserDefaults / Keychain 中保存硬件私钥 Token 的 Key
    private let hardwareKeyTokenPath = "com.zhiyu.secure_enclave.token"
    
    private init() {}
    
    // MARK: - 状态属性
    
    /// 检测当前设备硬件是否支持并启用了 Secure Enclave 安全协处理器
    var isSupported: Bool {
        #if targetEnvironment(simulator)
        // 模拟器下硬件芯片层无法完全加载，返回 false 走安全降级
        return false
        #else
        return SecureEnclave.isAvailable
        #endif
    }
    
    // MARK: - API 接口
    
    /// 使用 Secure Enclave 硬件芯片物理级加解密 API 密钥 (加密)
    /// - Parameter plainText: 原始明文字符串
    /// - Returns: 加密后的 Base64 复合密文字符串。若不支持 Secure Enclave，则优雅降级为基于 SQLCipher 密钥的应用级 AES-GCM 密文。
    func encrypt(_ plainText: String) throws -> String {
        guard isSupported else {
            // 物理降级方案：使用 SecurityManager 现有的 AES-GCM 软件保护逻辑
            return try SecurityManager.shared.encrypt(plainText)
        }
        
        // 1. 获取或生成驻留在 Secure Enclave 硬件内部的 P-256 私钥
        let hardwarePrivateKey = try getOrCreateHardwarePrivateKey()
        
        // 2. 在物理芯片内执行密钥协商，衍生出唯一的硬件对称密钥 (256-bit SymmetricKey)
        let sharedSecret = try hardwarePrivateKey.sharedSecretFromKeyAgreement(with: hardwarePrivateKey.publicKey)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data(),
            outputByteCount: 32
        )
        
        // 3. 校验原始文本并使用 AES-GCM 进行物理级高安全加密
        guard let data = plainText.data(using: .utf8) else {
            throw SecurityError.encodingFailed
        }
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
        return sealedBox.combined?.base64EncodedString() ?? ""
    }
    
    /// 使用 Secure Enclave 硬件芯片物理级加解密 API 密钥 (解密)
    /// - Parameter cipherText: 加密后的 Base64 复合密文
    /// - Returns: 还原的原始明文字符串。若不支持 Secure Enclave，则优雅使用物理降级解密。
    func decrypt(_ cipherText: String) throws -> String {
        guard isSupported else {
            // 物理降级方案：使用 SecurityManager 的 AES-GCM 解密
            return try SecurityManager.shared.decrypt(cipherText)
        }
        
        // 1. 读取 Secure Enclave 内对应的硬件私钥
        let hardwarePrivateKey = try getOrCreateHardwarePrivateKey()
        
        // 2. 物理芯片内同步执行密钥协商，衍生相同的对称密钥
        let sharedSecret = try hardwarePrivateKey.sharedSecretFromKeyAgreement(with: hardwarePrivateKey.publicKey)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data(),
            outputByteCount: 32
        )
        
        // 3. 使用 AES-GCM 还原明文
        guard let combinedData = Data(base64Encoded: cipherText) else {
            throw SecurityError.decodingFailed
        }
        let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
        
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw SecurityError.decodingFailed
        }
        return decryptedString
    }
    
    // MARK: - 内部私密辅助方法
    
    /// 获取或物理新建 Secure Enclave 内置 P-256 私钥
    private func getOrCreateHardwarePrivateKey() throws -> SecureEnclave.P256.KeyAgreement.PrivateKey {
        // 1. 尝试从本地 Keychain 中拉取保存的私钥引用 Token
        if let tokenDataString = try? KeychainService.shared.retrieve(key: hardwareKeyTokenPath),
           let tokenData = Data(base64Encoded: tokenDataString) {
            do {
                // 利用 Token 物理连接回 Secure Enclave 内部的硬件密钥
                return try SecureEnclave.P256.KeyAgreement.PrivateKey(dataRepresentation: tokenData)
            } catch {
                Logger.shared.error(String(data: Data(base64Encoded: "RmFpbGVkIHRvIGxvYWQgZXhpc3RpbmcgU2VjdXJlIEVuY2xhdmUgS2V5LCByZWNyZWF0aW5nLi4u")!, encoding: .utf8)!, error: error)
            }
        }
        
        // 2. 本地不存在引用代币，或硬件密钥已被系统抹除，重新在 Secure Enclave 物理芯片区生成新私钥
        // 采用 silent 模式，不设定 userPresence 弹窗强硬限制，完美支持单元测试与后台 RAG 静默运行
        let newKey = try SecureEnclave.P256.KeyAgreement.PrivateKey()
        let tokenData = newKey.dataRepresentation
        
        // 3. 将该非敏感的硬件私钥 Token 持久化进钥匙串，供以后无缝挂接
        try KeychainService.shared.store(key: hardwareKeyTokenPath, value: tokenData.base64EncodedString())
        return newKey
    }
}
