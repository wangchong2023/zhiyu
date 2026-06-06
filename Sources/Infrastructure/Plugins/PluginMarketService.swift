//
//  PluginMarketService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：实现 PluginMarket 模块的核心业务逻辑服务。
//
import Foundation
import Combine

/// 插件市场条目模型
@MainActor
struct MarketPlugin: Codable, Identifiable {
    let id: String
    let version: String
    let author: String
    let downloads: String
    let rating: Double
    let icon: String
    let downloadURL: String?
    let minAppVersion: String?
    let requiredPermissions: [String]?
    let monetization: MonetizationInfo?
    /// 审核评价数量
    let reviewCount: Int?
    /// 插件分类
    let category: String?

    let names: [String: String]
    let descriptions: [String: String]
    
    var name: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        return names[lang] ?? names["en"] ?? names.values.first ?? id
    }
    
    var description: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        return descriptions[lang] ?? descriptions["en"] ?? descriptions.values.first ?? ""
    }
}

/// 插件市场服务 (Architect 视角：实现云端分发体系)
final class PluginMarketService: ObservableObject {
    @Published var availablePlugins: [MarketPlugin] = []
    @Published var isLoading = false
    @Published var downloadingPluginID: String?
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    // 生产环境地址 (GitHub 模式)
    private let productionURL = URL(string: AppConfig.productionURL)!

    // 本地调试地址 (开发者模式)
    private let debugURL = URL(string: AppConfig.mockServerURL)!

    private var targetURL: URL {
        // 🔥 临时硬编码 URL 用于调试
        return URL(string: "http://127.0.0.1:9091/api/plugins")!
    }

    /// 拉取Plugins
    func fetchPlugins() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: targetURL)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            Logger.shared.info("[PluginMarket] Response: \(statusCode), bytes: \(data.count)")

            let decoder = JSONDecoder()

            // 尝试解析为 ApiResponse 格式（Mock 服务器）
            if let apiResponse = try? await MainActor.run(body: {
                try decoder.decode(ApiResponse<[MarketPlugin]>.self, from: data)
            }), let plugins = apiResponse.data {
                await MainActor.run {
                    self.availablePlugins = plugins
                    self.isLoading = false
                }
            } else {
                // 直接解析为数组格式（生产环境）
                let decodedPlugins = try await MainActor.run {
                    try decoder.decode([MarketPlugin].self, from: data)
                }
                await MainActor.run {
                    self.availablePlugins = decodedPlugins
                    self.isLoading = false
                }
            }
        } catch {
            Logger.shared.addLog(action: .error, target: "PluginMarketService", details: ": \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = L10n.Plugin.market.connectionError
                self.isLoading = false
            }
        }
    }

    /// 下载插件并保存到本地沙盒
    func downloadPlugin(_ plugin: MarketPlugin) async -> Bool {
        guard let urlString = plugin.downloadURL, let url = URL(string: urlString) else {
            await MainActor.run {
                // 无下载链接时，直接从本地 Plugins 目录复制同名文件
                let fileManager = FileManager.default
                guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
                let pluginsDir = documentsURL.appendingPathComponent("Plugins")
                let localFile = pluginsDir.appendingPathComponent("\(plugin.id).zyplugin")

                if !fileManager.fileExists(atPath: pluginsDir.path) {
                    try? fileManager.createDirectory(at: pluginsDir, withIntermediateDirectories: true)
                }

                // 尝试从 Tools/Plugins 目录复制
                let bundledSources = [
                    URL(fileURLWithPath: "Tools/Plugins/\(plugin.id).zyplugin"),
                    URL(fileURLWithPath: "Tools/Plugins/smart-cleaner.zyplugin"),
                ]
                for src in bundledSources {
                    if fileManager.fileExists(atPath: src.path) {
                        try? fileManager.removeItem(at: localFile)
                        try? fileManager.copyItem(at: src, to: localFile)
                        Logger.shared.info("[PluginMarket] Copied local: \(plugin.name)")
                        self.errorMessage = nil
                    }
                }

                if !fileManager.fileExists(atPath: localFile.path) {
                    self.errorMessage = L10n.Plugin.market.connectionError
                }
            }
            // 延迟后触发扫描
            try? await Task.sleep(nanoseconds: 500_000_000)
            await PluginRegistry.shared.scanAndLoadLocalPlugins()
            return true
        }

        await MainActor.run { 
            downloadingPluginID = plugin.id
            errorMessage = nil 
        }
        
        defer { 
            Task { @MainActor in downloadingPluginID = nil }
        }

        do {
            let (tempURL, _) = try await URLSession.shared.download(from: url)
            
            // 获取本地插件目录
            let fileManager = FileManager.default
            guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return false }
            let pluginsDirectory = documentsURL.appendingPathComponent("Plugins")
            
            if !fileManager.fileExists(atPath: pluginsDirectory.path) {
                try fileManager.createDirectory(at: pluginsDirectory, withIntermediateDirectories: true, attributes: nil)
            }

            let destinationURL = pluginsDirectory.appendingPathComponent("\(plugin.id).zyplugin")
            
            // 如果已存在则移除旧版
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            try fileManager.moveItem(at: tempURL, to: destinationURL)
            
            await MainActor.run {
                Logger.shared.info(" [PluginMarket] : \(plugin.name)")
            }
            
            // 通知 Registry 重新扫描或加载该插件
            await PluginRegistry.shared.scanAndLoadLocalPlugins()
            
            return true
        } catch {
            await MainActor.run {
                Logger.shared.error(" [PluginMarket] : \(plugin.name)", error: error)
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
}

extension PluginMarketService: @unchecked Sendable {}
