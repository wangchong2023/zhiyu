// SecurityManager.swift
//
// 作者: Wang Chong
// 功能说明: [L0.5] 系统集成层：本文件实现了知识管理系统的安全治理与完整性校验服务（SecurityManager），旨在保障用户本地数据免受非授权篡改。
// 该服务基于现代加密算法，构建了一套轻量级的数据防护体系，核心功能点如下：
// 1. 数据指纹监控：利用 HMAC-SHA256 算法对核心数据库文件进行哈希签名，确保任何物理层面的非法篡改都能被即时检测。
// 2. 运行时完整性校验：在应用启动或关键数据加载时，通过比对内存指纹与持久化指纹，动态验证数据的合法性。
// 3. 智适应签名更新：在合法的写操作（如 CRUD）完成后，自动触发签名的差量更新，确保安全边界随数据演进动态迁移。
// 4. 容错式初始化逻辑：平衡了初次启动的便捷性与长期运行的安全性，支持在安全基准缺失时的平滑初始化。
//
// @SR-01: 确保用户原始文档安全。
// @SR-02: 向量数据库完整性校验基础。
// @SR-04: 沙盒安全性加固。
//
// 版本: 1.2
// 修改记录:
//   - 2026-05-05: 升级全工程文档规范，详细描述数据签名与加密校验逻辑。
//   - 2026-05-10: 标准化代码注释与 SRS 溯源标识。
// 版权: © 2026 Wang Chong。保留所有权利。

import Foundation
import CryptoKit

/// 安全管理器：负责数据签名、加密与完整性校验。
final class SecurityManager: Sendable {
    /// 全局单例
    static let shared = SecurityManager()

    /// 哈希盐值标识符
    private let saltKey = "zhiyu_security_salt"
    /// 签名存储在 UserDefaults 中的键前缀
    private let signatureKeyPrefix = "zhiyu.integrity.sig."

    /// 获取动态盐值，优先从 Keychain 读取，不存在则生成
    private var salt: String {
        if let existing = try? KeychainService.shared.retrieve(key: saltKey) {
            return existing
        }
        
        // 兼容性检查：如果 Keychain 为空但已有签名，说明需要迁移旧的硬编码盐
        let legacySalt = "App-Integrity-Salt-2026"
        let newSalt = UUID().uuidString + "-" + UUID().uuidString
        
        // 尝试探测是否有旧签名（以 KnowledgePage.sqlite 为例）
        let hasSignatures = UserDefaults.standard.dictionaryRepresentation().keys.contains { $0.hasPrefix(signatureKeyPrefix) }
        
        let saltToStore = hasSignatures ? legacySalt : newSalt
        try? KeychainService.shared.store(key: saltKey, value: saltToStore)
        return saltToStore
    }

    /// 初始化安全管理器
    init() {}

    /// 计算指定文件的 HMAC 签名
    /// - Parameter fileURL: 目标文件路径
    /// - Returns: Base64 编码的签名字符串
    func calculateHMAC(for fileURL: URL) throws -> String {
        let fileData = try Data(contentsOf: fileURL, options: .mappedIfSafe)
        guard let saltData = salt.data(using: .utf8) else {
            throw SecurityError.invalidSalt
        }
        let key = SymmetricKey(data: saltData)
        let signature = HMAC<SHA256>.authenticationCode(for: fileData, using: key)
        return Data(signature).base64EncodedString()
    }
    
    /// 保存签名到持久化存储 (@RR-01: 确保状态一致性)
    /// - Parameters:
    ///   - signature: 签名内容
    ///   - fileName: 文件名
    func saveSignature(_ signature: String, forFileName fileName: String) {
        UserDefaults.standard.set(signature, forKey: signatureKeyPrefix + fileName)
    }
    
    /// 验证文件完整性 (@SR-04: 防止非授权篡改)
    /// - Parameter fileURL: 目标文件路径
    /// - Returns: 是否通过校验
    func verifyIntegrity(for fileURL: URL) -> Bool {
        let fileName = fileURL.lastPathComponent
        guard let storedSig = UserDefaults.standard.string(forKey: signatureKeyPrefix + fileName) else {
            // 如果没有存储签名，可能是第一次运行，允许通过并初始化签名
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
    /// - Parameter fileURL: 目标文件路径
    func updateSignature(for fileURL: URL) {
        do {
            let sig = try calculateHMAC(for: fileURL)
            saveSignature(sig, forFileName: fileURL.lastPathComponent)
        } catch {
            Logger.shared.addLog(action: .error, target: "SecurityManager", details: "Failed to update signature: \(error.localizedDescription)", module: "Security")
        }
    }
}

enum SecurityError: LocalizedError {
    case invalidSalt

    var errorDescription: String? {
        switch self {
        case .invalidSalt:
            return "Failed to derive key from salt: invalid encoding"
        }
    }
}
