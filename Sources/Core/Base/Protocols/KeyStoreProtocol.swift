//
//  KeyStoreProtocol.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/07/14.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：键值存储抽象协议 — 统一 UserDefaults / iCloud KVS / 测试 Mock 访问。

import Foundation

/// 键值存储抽象协议
///
/// 为 UserDefaults.standard 提供协议化抽象层，支持：
/// - 生产环境：UserDefaultsKeyStore（标准 UserDefaults）
/// - iCloud：NSUbiquitousKeyValueStore 适配（未来）
/// - 测试环境：MockKeyStore（内存实现）
public protocol KeyStoreProtocol: AnyObject, Sendable {
    func bool(forKey key: String) -> Bool
    func string(forKey key: String) -> String?
    func data(forKey key: String) -> Data?
    func integer(forKey key: String) -> Int
    func double(forKey key: String) -> Double
    func object(forKey key: String) -> Any?
    func set(_ value: Any?, forKey key: String)
    func set(_ value: Bool, forKey key: String)
    func removeObject(forKey key: String)
    func dictionaryRepresentation() -> [String: Any]
}
