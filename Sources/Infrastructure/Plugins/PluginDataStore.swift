//
//  PluginDataStore.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/07.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：插件私有数据持久化——JSON 加密存储与读取。
//           从 PluginRegistry 独立提取，遵循单一职责原则 (SRP)。
//
import Foundation

/// 插件数据持久化管理器
/// 负责插件私有 key-value 数据的加密存储与读取。
final class PluginDataStore: Sendable {

    /// 获取插件专用存储路径
    private func dataURL(for pluginID: String) -> URL? {
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let directoryURL = appSupportURL.appendingPathComponent("PluginsData")

        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }

        return directoryURL.appendingPathComponent("\(pluginID).json")
    }

    /// 保存插件私有数据（AES-GCM 加密）
    /// - Parameters:
    ///   - pluginID: 插件唯一标识
    ///   - key: 数据键
    ///   - value: 数据值
    func savePluginData(pluginID: String, key: String, value: String) {
        guard let url = dataURL(for: pluginID) else { return }

        var dict = loadAllPluginData(pluginID: pluginID)
        dict[key] = value

        if let encodedData = try? JSONEncoder().encode(dict),
           let jsonString = String(data: encodedData, encoding: .utf8),
           let encrypted = try? SecurityManager.shared.encrypt(jsonString) {
            try? encrypted.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    /// 读取插件私有数据
    /// - Parameters:
    ///   - pluginID: 插件唯一标识
    ///   - key: 数据键
    /// - Returns: 对应的值，若不存在则返回 nil
    func loadPluginData(pluginID: String, key: String) -> String? {
        return loadAllPluginData(pluginID: pluginID)[key]
    }

    /// 获取插件的所有持久化数据（解密后）
    /// - Parameter pluginID: 插件唯一标识
    /// - Returns: 键值对字典
    func loadAllPluginData(pluginID: String) -> [String: String] {
        guard let url = dataURL(for: pluginID),
              let data = try? Data(contentsOf: url) else {
            return [:]
        }

        if let contentString = String(data: data, encoding: .utf8),
           let decrypted = try? SecurityManager.shared.decrypt(contentString),
           let decryptedData = decrypted.data(using: .utf8),
           let dict = try? JSONDecoder().decode([String: String].self, from: decryptedData) {
            return dict
        } else if let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            return dict
        }

        return [:]
    }
}