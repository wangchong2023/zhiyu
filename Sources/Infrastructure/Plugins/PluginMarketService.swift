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
    /// 来源类型：remote / local / community
    let source: String?

    let names: [String: String]
    let descriptions: [String: String]
    
    var name: String {
        return Localized.bestMatch(in: names, fallback: id)
    }

    var description: String {
        return Localized.bestMatch(in: descriptions, fallback: "")
    }

    /// 从 community-plugins.json 条目构造
    init(from entry: CommunityPluginEntry, downloadBase: URL) {
        self.id = entry.id
        self.version = "latest"
        self.author = entry.author
        self.downloads = "N/A"
        self.rating = 0
        self.icon = "puzzlepiece.extension.fill"
        self.downloadURL = downloadBase
            .appendingPathComponent("\(entry.id).zyplugin")
            .absoluteString
        self.minAppVersion = nil
        self.requiredPermissions = nil
        self.monetization = nil
        self.reviewCount = nil
        self.category = nil
        self.source = "community"
        self.names = ["en": entry.name]
        self.descriptions = ["en": entry.description]
    }
}

/// community-plugins.json 条目 (Obsidian 风格)
struct CommunityPluginEntry: Codable {
    let id: String
    let name: String
    let author: String
    let description: String
    let repo: String
}

/// 插件市场服务 (Architect 视角：实现云端分发体系)
final class PluginMarketService: ObservableObject {
    @Published var availablePlugins: [MarketPlugin] = []
    @Published var isLoading = false
    @Published var downloadingPluginID: String?
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    // 生产环境 (GitHub)
    private let registryGitHub = URL(string: "https://raw.githubusercontent.com/wangchong2023/zhiyu-releases/master/community-plugins.json")!

    // 本地 Gitea (开发/离线优先)
    private let registryGitea = URL(string: "http://localhost:3000/constantine/zhiyu-releases/raw/branch/master/community-plugins.json")!

    // 元数据回退 (mock 服务器，保留兼容)
    private let mockURL = URL(string: "http://127.0.0.1:9091/api/plugins")!

    private var targetURL: URL {
        #if DEBUG
        return registryGitea
        #else
        return registryGitHub
        #endif
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

            // 1. 先尝试解析 community-plugins.json 格式 (Obsidian 风格)
            if let communityPlugins = try? decoder.decode([CommunityPluginEntry].self, from: data) {
                // 从 registry URL 推导下载 base：community-plugins.json → plugins/
                let downloadBase = URL(string: targetURL.absoluteString
// swiftlint:disable:next force_unwrapping
                    .replacingOccurrences(of: "community-plugins.json", with: "plugins"))!
                let plugins = await MainActor.run {
                    communityPlugins.map { MarketPlugin(from: $0, downloadBase: downloadBase) }
                }
                await MainActor.run {
                    self.availablePlugins = plugins
                    self.isLoading = false
                }
                return
            }

            // 2. 回退：ApiResponse 格式（Mock 服务器兼容）
            if let apiResponse = try? decoder.decode(ApiResponse<[MarketPlugin]>.self, from: data),
               let plugins = apiResponse.data {
                await MainActor.run {
                    self.availablePlugins = plugins
                    self.isLoading = false
                }
                return
            }

            // 3. 回退：直接数组格式
            let decodedPlugins = try decoder.decode([MarketPlugin].self, from: data)
            await MainActor.run {
                self.availablePlugins = decodedPlugins
                self.isLoading = false
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
                    URL(fileURLWithPath: "Tools/Plugins/smart-cleaner.zyplugin")
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
