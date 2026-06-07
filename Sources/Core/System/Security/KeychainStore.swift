//
//  KeychainStore.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/07.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0.5] 系统集成层
//  核心职责：基于 KeychainAccess 的安全存储适配器。
//           提供对系统 Keychain 的轻量级访问，支持 JWT Token、API Key 等敏感数据的持久化存储。
//           替代原自研 Security.framework 直接封装，复用 KeychainAccess 的边缘情况处理与线程安全保障。
//
import Foundation
import KeychainAccess

// MARK: - Keychain 安全存储

/// 钥匙串服务适配器，封装 KeychainAccess 库提供简洁的存储/读取/删除接口。
/// 保持与旧 KeychainService 相同的 `shared` 单例模式，最小化消费者改动。
final class KeychainStore: Sendable {
    /// 全局单例
    static let shared = KeychainStore()

    /// KeychainAccess 实例，绑定 ZhiYu 服务标识符。
    private let keychain = Keychain(service: "com.zhiyu.keychain")

    private init() {}

    /// 存储敏感数据。若 key 已存在则覆盖。
    /// - Parameters:
    ///   - key: 键名
    ///   - value: 要存储的字符串
    func store(key: String, value: String) throws {
        keychain[key] = value
    }

    /// 获取敏感数据。
    /// - Parameter key: 键名
    /// - Returns: 存储的字符串，不存在则返回 nil
    func retrieve(key: String) -> String? {
        return keychain[key]
    }

    /// 删除敏感数据。若 key 不存在则不抛错。
    /// - Parameter key: 键名
    func delete(key: String) throws {
        try keychain.remove(key)
    }
}
