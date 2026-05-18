// FileSignatureRepository.swift
//
// 作者: Wang Chong
// 功能说明: [L1.5] 领域层：物理文件防篡改完整性指纹仓储协议，定义指纹入全局库的契约。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// [Domain] 文件 HMAC 防篡改签名仓储协议，彻底解除安全管理器与 raw SQL 的直接耦合。
public protocol FileSignatureRepository: Sendable {
    /// 获取当前存储的指纹总数量 (用于冷启动盐值选择与向下兼容)
    func fetchSignatureCount() async throws -> Int
    
    /// 保存或更新指定物理文件的 HMAC 签名指纹
    func saveSignature(_ signature: String, forFilePath filePath: String, salt: String) async throws
    
    /// 获取指定物理文件的已保存 HMAC 签名指纹
    func fetchSignature(forFilePath filePath: String) async throws -> String?
}
