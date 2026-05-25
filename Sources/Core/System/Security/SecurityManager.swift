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
    
    /// 注入文件指纹签名仓储，贯彻 DIP 依赖倒置原则。
    /// 采用可选解析防止在冷启动尚未注册时发生崩溃，此时会安全降级到 UserDefaults。
    private var signatureRepository: (any FileSignatureRepository)? {
        ServiceContainer.shared.resolveOptional((any FileSignatureRepository).self)
    }

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
        
        // 1. 优先从 Keychain 读取
        if let existing = try? KeychainService.shared.retrieve(key: dbPassphraseKey) {
            cachedPassphrase = existing
            return existing
        }
        
        #if DEBUG
        // 2. 在 DEBUG 模式下，Keychain 读不到，尝试从 UserDefaults 兜底读取 (用于模拟器未签名环境)
        if let fallback = UserDefaults.standard.string(forKey: dbPassphraseKey) {
            cachedPassphrase = fallback
            return fallback
        }
        #endif
        
        // 3. 生成新密码
        let newPassphrase = UUID().uuidString + "-" + Data(UUID().uuidString.utf8).base64EncodedString()
        
        // 4. 优先存入 Keychain
        do {
            try KeychainService.shared.store(key: dbPassphraseKey, value: newPassphrase)
            cachedPassphrase = newPassphrase
            return newPassphrase
        } catch {
            #if DEBUG
            // 仅在 DEBUG 下允许写入 UserDefaults 兜底
            UserDefaults.standard.set(newPassphrase, forKey: dbPassphraseKey)
            cachedPassphrase = newPassphrase
            return newPassphrase
            #else
            // 生产环境下 Keychain 故障属于灾难性安全错误，拒绝明文存储，直接崩溃以防密文泄露
            fatalError("❌ Critical security error: Failed to secure Database Passphrase in Keychain.")
            #endif
        }
    }

    // MARK: - 内容级加密 (AES-GCM)

    /// 加密
    /// /// - Parameter text: text
    /// /// - Returns: 字符串
    func encrypt(_ text: String) throws -> String {
        let key = SymmetricKey(data: SHA256.hash(data: Data(getDatabasePassphrase().utf8)))
        guard let data = text.data(using: .utf8) else { throw SecurityError.encodingFailed }
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined?.base64EncodedString() ?? ""
    }

    /// 解密
    /// /// - Parameter base64Combined: base64Combined
    /// /// - Returns: 字符串
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
        // 1. 优先从 Keychain 获取
        if let existing = try? KeychainService.shared.retrieve(key: saltKey) {
            return existing
        }
        
        #if DEBUG
        // 2. 在 DEBUG 模式下，Keychain 获取失败，尝试从 UserDefaults 兜底获取
        if let fallback = UserDefaults.standard.string(forKey: saltKey) {
            return fallback
        }
        #endif
        
        let legacySalt = AppConstants.Keys.Storage.defaultLegacySalt
        let newSalt = UUID().uuidString + "-" + UUID().uuidString
        
        var hasSignatures = UserDefaults.standard.dictionaryRepresentation().keys.contains { $0.hasPrefix(signatureKeyPrefix) }
        
        if !hasSignatures {
            let count = (try? await signatureRepository?.fetchSignatureCount()) ?? 0
            hasSignatures = count > 0
        }
        
        let saltToStore = hasSignatures ? legacySalt : newSalt
        
        // 3. 优先存入 Keychain
        do {
            try KeychainService.shared.store(key: saltKey, value: saltToStore)
            return saltToStore
        } catch {
            #if DEBUG
            // 仅在 DEBUG 下允许写入 UserDefaults 兜底
            UserDefaults.standard.set(saltToStore, forKey: saltKey)
            return saltToStore
            #else
            // 生产环境下 Keychain 故障属于灾难性安全错误，直接致命崩溃
            fatalError("❌ Critical security error: Failed to secure HMAC Salt in Keychain.")
            #endif
        }
    }

    /// 计算HMAC
    /// /// - Returns: 字符串
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
    
    /// 保存Signature
    /// /// - Parameter signature: signature
    func saveSignature(_ signature: String, forFilePath filePath: String) async {
        let currentSalt = await getSalt()
        do {
            guard let repo = signatureRepository else {
                throw NSError(domain: "SecurityManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "FileSignatureRepository is not registered yet"])
            }
            try await repo.saveSignature(signature, forFilePath: filePath, salt: currentSalt)
        } catch {
            #if DEBUG
            // 仅在 DEBUG 下允许降级到 UserDefaults，用于模拟器未签名环境
            print("⚠️ [SecurityManager] DEBUG: HMAC 签名持久化降级到 UserDefaults: \(error)")
            let fileName = URL(fileURLWithPath: filePath).lastPathComponent
            UserDefaults.standard.set(signature, forKey: signatureKeyPrefix + fileName)
            #else
            // 生产环境：签名持久化失败属于严重安全错误，不允许明文降级
            Logger.shared.addLog(
                action: .error,
                target: "SecurityManager",
                details: "Critical: Failed to persist HMAC signature securely: \(error.localizedDescription)",
                module: "Security"
            )
            #endif
        }
    }
    
    /// 验证Integrity
    /// /// - Returns: 是否成功
    func verifyIntegrity(for fileURL: URL) async -> Bool {
        let filePath = fileURL.path
        
        let storedSig: String?
        if let repo = signatureRepository {
            storedSig = try? await repo.fetchSignature(forFilePath: filePath)
        } else {
            storedSig = nil
        }
        
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
    
    /// 更新Signature
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
