// SecurityManager.swift
//
// 作者: Wang Chong
// 功能说明: [L0.5] 系统集成层：本文件实现了知识管理系统的安全治理与完整性校验服务（SecurityManager），旨在保障用户本地数据免受非授权篡改。
// 核心职责：
// 1. 数据指纹监控：利用 HMAC-SHA256 算法对数据库文件进行签名验证。
// 2. 物理加密管理：集成 SQLCipher，提供数据库全盘加密所需的密钥生命周期管理。
// 3. 内容级加密：提供基于 AES-GCM 的敏感文本加解密接口，支持应用级隐私防护。
// 4. 钥匙串隔离：敏感安全令牌（盐值、DB 密钥）持久化于系统 Keychain。
// 版本: 1.4
// 修改记录:
//   - 2026-05-16: 安全加固：集成 SQLCipher 密钥管理与 AES-GCM 内容加密 (@P0)。
// 版权: © 2026 Wang Chong。保留所有权利。

import Foundation
import CryptoKit

/// 安全管理器：负责数据签名、加密与完整性校验。
final class SecurityManager: Sendable {
    /// 全局单例
    static let shared = SecurityManager()

    // MARK: - 存储键名
    private let saltKey = AppConstants.Keys.Storage.securitySalt
    private let dbPassphraseKey = AppConstants.Keys.Storage.dbPassphrase
    private let signatureKeyPrefix = AppConstants.Keys.Storage.signaturePrefix

    // MARK: - 初始化
    init() {}

    // MARK: - 缓存
    private var cachedPassphrase: String?

    // MARK: - 物理加密 (SQLCipher)
    
    /// 获取/生成数据库物理加密密钥
    /// 密钥采用 UUID + Base64 随机串组合，确保极高的熵值，且持久化于 Keychain。
    func getDatabasePassphrase() -> String {
        // 1. 优先返回内存缓存 (解决测试环境 Keychain 失败导致的密钥不一致问题)
        if let cached = cachedPassphrase {
            return cached
        }
        
        // 2. 尝试从 Keychain 读取
        if let existing = try? KeychainService.shared.retrieve(key: dbPassphraseKey) {
            cachedPassphrase = existing
            return existing
        }
        
        // 3. 生成新密钥并持久化
        let newPassphrase = UUID().uuidString + "-" + Data(UUID().uuidString.utf8).base64EncodedString()
        try? KeychainService.shared.store(key: dbPassphraseKey, value: newPassphrase)
        cachedPassphrase = newPassphrase
        return newPassphrase
    }

    // MARK: - 内容级加密 (AES-GCM)

    /// 对敏感内容进行 AES-GCM 加密
    func encrypt(_ text: String) throws -> String {
        let key = SymmetricKey(data: SHA256.hash(data: Data(getDatabasePassphrase().utf8)))
        guard let data = text.data(using: .utf8) else { throw SecurityError.encodingFailed }
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined?.base64EncodedString() ?? ""
    }

    /// 对 AES-GCM 加密内容进行解密
    func decrypt(_ base64Combined: String) throws -> String {
        let key = SymmetricKey(data: SHA256.hash(data: Data(getDatabasePassphrase().utf8)))
        guard let combinedData = Data(base64Encoded: base64Combined) else { throw SecurityError.decodingFailed }
        let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        guard let text = String(data: decryptedData, encoding: .utf8) else { throw SecurityError.decodingFailed }
        return text
    }

    // MARK: - 完整性校验 (HMAC)

    /// 获取动态盐值，优先从 Keychain 读取，不存在则生成
    private var salt: String {
        if let existing = try? KeychainService.shared.retrieve(key: saltKey) {
            return existing
        }
        
        let legacySalt = "App-Integrity-Salt-2026"
        let newSalt = UUID().uuidString + "-" + UUID().uuidString
        let hasSignatures = UserDefaults.standard.dictionaryRepresentation().keys.contains { $0.hasPrefix(signatureKeyPrefix) }
        
        let saltToStore = hasSignatures ? legacySalt : newSalt
        try? KeychainService.shared.store(key: saltKey, value: saltToStore)
        return saltToStore
    }

    /// 计算指定文件的 HMAC 签名
    func calculateHMAC(for fileURL: URL) throws -> String {
        let fileData = try Data(contentsOf: fileURL, options: .mappedIfSafe)
        guard let saltData = salt.data(using: .utf8) else {
            throw SecurityError.invalidSalt
        }
        let key = SymmetricKey(data: saltData)
        let signature = HMAC<SHA256>.authenticationCode(for: fileData, using: key)
        return Data(signature).base64EncodedString()
    }
    
    /// 保存签名到持久化存储
    func saveSignature(_ signature: String, forFileName fileName: String) {
        UserDefaults.standard.set(signature, forKey: signatureKeyPrefix + fileName)
    }
    
    /// 验证文件完整性
    func verifyIntegrity(for fileURL: URL) -> Bool {
        let fileName = fileURL.lastPathComponent
        guard let storedSig = UserDefaults.standard.string(forKey: signatureKeyPrefix + fileName) else {
            return true 
        }
        
        do {
            let currentSig = try calculateHMAC(for: fileURL)
            return currentSig == storedSig
        } catch {
            return false
        }
    }
    
    /// 更新文件签名
    func updateSignature(for fileURL: URL) {
        do {
            let sig = try calculateHMAC(for: fileURL)
            saveSignature(sig, forFileName: fileURL.lastPathComponent)
        } catch {
            Logger.shared.addLog(action: .error, target: "SecurityManager", details: "Failed to update signature: \(error.localizedDescription)", module: "Security")
        }
    }
}

// MARK: - 错误定义
enum SecurityError: LocalizedError {
    case invalidSalt
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidSalt: return "Failed to derive key from salt: invalid encoding"
        case .encodingFailed: return "Data encoding failed"
        case .decodingFailed: return "Data decoding failed"
        }
    }
}
