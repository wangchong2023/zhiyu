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
        #if DEBUG
        return debugURL
        #else
        return productionURL
        #endif
    }

    /// 拉取Plugins
    func fetchPlugins() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            // 真实的网络请求逻辑
            let (data, _) = try await URLSession.shared.data(from: targetURL)
            let decoder = JSONDecoder()
            // 在 MainActor 上解码，因为 MarketPlugin 是 MainActor 隔离的
            let decodedPlugins = try await MainActor.run {
                try decoder.decode([MarketPlugin].self, from: data)
            }

            await MainActor.run {
                self.availablePlugins = decodedPlugins
                self.isLoading = false
            }
        } catch {
            Logger.shared.addLog(action: .error, target: "PluginMarketService", details: "获取插件失败: \(error.localizedDescription)")
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
                Logger.shared.error("❌ [PluginMarket] 插件下载地址无效: \(plugin.name)", error: nil)
            }
            return false
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
            
            let destinationURL = pluginsDirectory.appendingPathComponent("\(plugin.id).js")
            
            // 如果已存在则移除旧版
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            try fileManager.moveItem(at: tempURL, to: destinationURL)
            
            await MainActor.run {
                Logger.shared.info("✅ [PluginMarket] 插件下载成功并持久化: \(plugin.name)")
            }
            
            // 通知 Registry 重新扫描或加载该插件
            await PluginRegistry.shared.scanAndLoadLocalPlugins()
            
            return true
        } catch {
            await MainActor.run {
                Logger.shared.error("❌ [PluginMarket] 下载插件失败: \(plugin.name)", error: error)
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
}

extension PluginMarketService: @unchecked Sendable {}
