//
//  SecurityManager.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0.5] 系统集成层
//  核心职责：属于 Security 模块，提供相关的结构体或工具支撑。
//
import Foundation
import CryptoKit
import GRDB

/// 安全管理器：负责数据签名、加密与完整性校验。
final class SecurityManager: @unchecked Sendable {
    /// 全局单例
    static let shared = SecurityManager()

    // MARK: - 依赖注入
    
    /// 注入文件指纹签名仓储，贯彻 DIP 依赖倒置原则
    @Inject private var signatureRepository: any FileSignatureRepository

    // MARK: - 存储键名
    private let saltKey = AppConstants.Keys.Storage.securitySalt
    private let dbPassphraseKey = AppConstants.Keys.Storage.dbPassphrase
    private let signatureKeyPrefix = AppConstants.Keys.Storage.signaturePrefix

    // MARK: - 初始化
    private init() {}

    // MARK: - 缓存
    // 使用 nonisolated(unsafe) 配合 actor 同步访问或确保单线程访问
    // 此处由于 SecurityManager 是 Sendable 且 singleton，我们采用锁或 MainActor 隔离来保护缓存
    // 为简化实现且保证性能，我们将缓存操作也放在辅助方法中
    private let lock = NSLock()
    private var _cachedPassphrase: String?
    private var cachedPassphrase: String? {
        get { lock.withLock { _cachedPassphrase } }
        set { lock.withLock { _cachedPassphrase = newValue } }
    }

    // MARK: - 物理加密 (SQLCipher)
    
    /// 获取或生成数据库物理加密所用的密钥
    func getDatabasePassphrase() -> String {
        if let cached = cachedPassphrase {
            return cached
        }
        
        if let existing = try? KeychainService.shared.retrieve(key: dbPassphraseKey) {
            cachedPassphrase = existing
            return existing
        }
        
        let newPassphrase = UUID().uuidString + "-" + Data(UUID().uuidString.utf8).base64EncodedString()
        try? KeychainService.shared.store(key: dbPassphraseKey, value: newPassphrase)
        cachedPassphrase = newPassphrase
        return newPassphrase
    }

    // MARK: - 内容级加密 (AES-GCM)

    func encrypt(_ text: String) throws -> String {
        let key = SymmetricKey(data: SHA256.hash(data: Data(getDatabasePassphrase().utf8)))
        guard let data = text.data(using: .utf8) else { throw SecurityError.encodingFailed }
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined?.base64EncodedString() ?? ""
    }

    func decrypt(_ base64Combined: String) throws -> String {
        let key = SymmetricKey(data: SHA256.hash(data: Data(getDatabasePassphrase().utf8)))
        guard let combinedData = Data(base64Encoded: base64Combined) else { throw SecurityError.decodingFailed }
        let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        guard let text = String(data: decryptedData, encoding: .utf8) else { throw SecurityError.decodingFailed }
        return text
    }

    // MARK: - 完整性校验 (HMAC)

    private func getSalt() async -> String {
        if let existing = try? KeychainService.shared.retrieve(key: saltKey) {
            return existing
        }
        
        let legacySalt = AppConstants.Keys.Storage.defaultLegacySalt
        let newSalt = UUID().uuidString + "-" + UUID().uuidString
        
        var hasSignatures = UserDefaults.standard.dictionaryRepresentation().keys.contains { $0.hasPrefix(signatureKeyPrefix) }
        
        if !hasSignatures {
            let count = (try? await signatureRepository.fetchSignatureCount()) ?? 0
            hasSignatures = count > 0
        }
        
        let saltToStore = hasSignatures ? legacySalt : newSalt
        try? KeychainService.shared.store(key: saltKey, value: saltToStore)
        return saltToStore
    }

    func calculateHMAC(for fileURL: URL) async throws -> String {
        let fileData = try Data(contentsOf: fileURL, options: .mappedIfSafe)
        let currentSalt = await getSalt()
        guard let saltData = currentSalt.data(using: .utf8) else {
            throw SecurityError.invalidSalt
        }
        let key = SymmetricKey(data: saltData)
        let signature = HMAC<SHA256>.authenticationCode(for: fileData, using: key)
        return Data(signature).base64EncodedString()
    }
    
    func saveSignature(_ signature: String, forFilePath filePath: String) async {
        let currentSalt = await getSalt()
        do {
            try await signatureRepository.saveSignature(signature, forFilePath: filePath, salt: currentSalt)
        } catch {
            print("❌ [SecurityManager] Failed to save file HMAC signature: \(error)")
            let fileName = URL(fileURLWithPath: filePath).lastPathComponent
            UserDefaults.standard.set(signature, forKey: signatureKeyPrefix + fileName)
        }
    }
    
    func verifyIntegrity(for fileURL: URL) async -> Bool {
        let filePath = fileURL.path
        let storedSig = try? await signatureRepository.fetchSignature(forFilePath: filePath)
        
        var finalStoredSig = storedSig
        if finalStoredSig == nil {
            let fileName = fileURL.lastPathComponent
            finalStoredSig = UserDefaults.standard.string(forKey: signatureKeyPrefix + fileName)
        }
        
        guard let expectedSig = finalStoredSig else { return true }
        
        do {
            let currentSig = try await calculateHMAC(for: fileURL)
            return currentSig == expectedSig
        } catch {
            return false
        }
    }
    
    func updateSignature(for fileURL: URL) async {
        do {
            let sig = try await calculateHMAC(for: fileURL)
            await saveSignature(sig, forFilePath: fileURL.path)
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
