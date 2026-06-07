//
//  FileSignatureRepository.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1.5] 领域层
//  核心职责：领域层协议定义（Repository、Service、Strategy 等抽象）。
//
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
