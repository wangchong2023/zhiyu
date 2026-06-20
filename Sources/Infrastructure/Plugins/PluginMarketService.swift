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

    /// 逐个成员初始构造器 (方便单元测试与本地 Fallback 构造)
    init(
        id: String,
        version: String,
        author: String,
        downloads: String,
        rating: Double,
        icon: String,
        downloadURL: String?,
        minAppVersion: String?,
        requiredPermissions: [String]?,
        monetization: MonetizationInfo?,
        reviewCount: Int?,
        category: String?,
        source: String?,
        names: [String: String] = [:],
        descriptions: [String: String] = [:]
    ) {
        self.id = id
        self.version = version
        self.author = author
        self.downloads = downloads
        self.rating = rating
        self.icon = icon
        self.downloadURL = downloadURL
        self.minAppVersion = minAppVersion
        self.requiredPermissions = requiredPermissions
        self.monetization = monetization
        self.reviewCount = reviewCount
        self.category = category
        self.source = source
        self.names = names
        self.descriptions = descriptions
    }

    /// 从 community-plugins.json 元数据条目构造插件市场条目，支持可选的多语言元数据字段。
    /// - Parameters:
    ///   - entry: 解析后的社区插件元数据条目
    ///   - downloadBase: 下载的基准 URL 地址
    init(from entry: CommunityPluginEntry, downloadBase: URL) {
        self.id = entry.id
        self.version = "latest"
        self.author = entry.author
        self.downloads = "N/A"
        self.rating = 0
        self.icon = "puzzlepiece.extension.fill"
        self.downloadURL = downloadBase
            .appendingPathComponent(entry.id)
            .absoluteString
        self.minAppVersion = nil
        self.requiredPermissions = nil
        self.monetization = nil
        self.reviewCount = nil
        self.category = nil
        self.source = "community"
        
        // 优先采纳 entry.names 多语言字典，若为空则自动补充默认英文名称
        var resolvedNames = entry.names ?? [:]
        if resolvedNames["en"] == nil {
            resolvedNames["en"] = entry.name
        }
        self.names = resolvedNames
        
        // 优先采纳 entry.descriptions 多语言字典，若为空则自动补充默认英文描述
        var resolvedDescs = entry.descriptions ?? [:]
        if resolvedDescs["en"] == nil {
            resolvedDescs["en"] = entry.description
        }
        self.descriptions = resolvedDescs
    }
}

/// community-plugins.json 条目（Obsidian 风格，扩展支持多语言元数据）
struct CommunityPluginEntry: Codable {
    let id: String
    let name: String
    let author: String
    let description: String
    let repo: String
    
    let names: [String: String]?
    let descriptions: [String: String]?
}

/// 插件市场服务 (Architect 视角：实现云端分发体系)
@MainActor
final class PluginMarketService: ObservableObject {
    @Published var availablePlugins: [MarketPlugin] = []
    @Published var isLoading = false
    @Published var downloadingPluginID: String?
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    // 生产环境 (GitHub)
    private let registryGitHub: URL = {
        guard let url = URL(string: "https://raw.githubusercontent.com/wangchong2023/zhiyu-releases/master/community-plugins.json") else {
            preconditionFailure("Invalid GitHub registry URL")
        }
        return url
    }()

    private var targetURL: URL {
        return registryGitHub
    }

    /// 拉取云端插件市场的最新插件列表（从 GitHub 远端配置地址异步加载，无本地静态 Fallback）
    /// - Returns: Void。更新 `@Published` 的 `availablePlugins` 与 `isLoading` 状态。
    func fetchPlugins() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        let urlsToTry = self.buildPluginURLs()
        let fetchSuccess = await tryFetchAny(from: urlsToTry)

        if !fetchSuccess {
            await MainActor.run {
                self.availablePlugins = []
                self.errorMessage = L10n.Plugin.market.connectionError
                self.isLoading = false
            }
        }
    }

    private func buildPluginURLs() -> [URL] {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        var urls: [URL] = []
        if preferredLanguage.hasPrefix("zh") {
            let zhURL = registryGitHub.deletingLastPathComponent().appendingPathComponent("community-plugins_zh-Hans.json")
            urls.append(zhURL)
        }
        urls.append(registryGitHub)
        return urls
    }

    private func tryFetchAny(from urls: [URL]) async -> Bool {
        // swiftlint:disable for_where
        for url in urls {
            if await tryFetch(from: url) {
                return true
            }
        }
        // swiftlint:enable for_where
        return false
    }

    private func tryFetch(from url: URL) async -> Bool {
        do {
            Logger.shared.info("[PluginMarket] 正在尝试从以下地址拉取插件市场: \(url.absoluteString)")
            let (data, response) = try await URLSession.shared.data(from: url)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            guard statusCode == 200 else {
                throw NSError(domain: "PluginMarketService", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(statusCode)"])
            }

            Logger.shared.info("[PluginMarket] 成功拉取插件元数据，大小: \(data.count) 字节")
            return await processPluginResponse(data: data)
        } catch {
            Logger.shared.warning("[PluginMarket] 从云端 \(url.absoluteString) 拉取插件市场元数据失败: \(error.localizedDescription)")
            return false
        }
    }

    private func processPluginResponse(data: Data) async -> Bool {
        let decoder = JSONDecoder()

        if let communityPlugins = try? decoder.decode([CommunityPluginEntry].self, from: data) {
            let rawURLString = registryGitHub.absoluteString.replacingOccurrences(of: "community-plugins.json", with: "plugins")
            if let downloadBase = URL(string: rawURLString) {
                let plugins = await MainActor.run {
                    communityPlugins.map { MarketPlugin(from: $0, downloadBase: downloadBase) }
                }
                await MainActor.run {
                    self.availablePlugins = plugins
                    self.isLoading = false
                }
                return true
            }
        }

        if let apiResponse = try? decoder.decode(ApiResponse<[MarketPlugin]>.self, from: data),
           let plugins = apiResponse.data {
            await MainActor.run {
                self.availablePlugins = plugins
                self.isLoading = false
            }
            return true
        }

        if let decodedPlugins = try? decoder.decode([MarketPlugin].self, from: data) {
            await MainActor.run {
                self.availablePlugins = decodedPlugins
                self.isLoading = false
            }
            return true
        }

        return false
    }

    /// 下载指定的插件并将其保存到本地沙盒存储目录中
    /// - Parameter plugin: 目标下载插件条目
    /// - Returns: Bool，代表下载与解包保存是否成功。
    /// 下载指定的插件并将其保存到本地沙盒存储目录中（明文分流并发下载版）
    /// - Parameter plugin: 目标下载插件条目
    /// - Returns: Bool，代表下载保存是否成功。
    /// 下载指定的插件并将其保存到本地沙盒存储目录中（明文分流并发下载版）
    /// - Parameter plugin: 目标下载插件条目
    /// - Returns: Bool，代表下载保存是否成功。
    func downloadPlugin(_ plugin: MarketPlugin) async -> Bool {
        guard let urlString = plugin.downloadURL, let baseURL = URL(string: urlString) else {
            Logger.shared.warning("[PluginMarket] 插件 \(plugin.name) 下载链接无效或缺失。")
            return false
        }

        await MainActor.run { 
            downloadingPluginID = plugin.id
            errorMessage = nil 
        }
        
        defer { 
            Task { @MainActor in downloadingPluginID = nil }
        }
        
        let fileManager = FileManager.default

        do {
            Logger.shared.info("[PluginMarket] 开始从明文目录并发下载插件: \(plugin.name)")
            let destinationFolderURL = try prepareDestinationFolder(for: plugin.id, fileManager: fileManager)
            let tasks = buildDownloadTasks(baseURL: baseURL, destinationFolderURL: destinationFolderURL)
            
            try await executeDownloadTasks(tasks)
            
            await MainActor.run {
                Logger.shared.info(" [PluginMarket] 插件下载并安装成功: \(plugin.name)")
            }
            
            // 扫描并重新加载插件以供系统挂载
            PluginRegistry.shared.scanAndLoadLocalPlugins()
            return true
        } catch {
            performDownloadRollback(for: plugin.id, fileManager: fileManager)
            await MainActor.run {
                Logger.shared.error(" [PluginMarket] 插件明文并发下载安装失败: \(plugin.name)", error: error)
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }

    /// 为指定插件准备物理沙盒目标文件夹，清理老旧缓存
    private func prepareDestinationFolder(for pluginID: String, fileManager: FileManager) throws -> URL {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(
                domain: "PluginMarketService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Failed to locate documents directory"]
            )
        }
        let pluginsDirectory = documentsURL.appendingPathComponent("Plugins")
        let destinationFolderURL = pluginsDirectory.appendingPathComponent(pluginID)
        
        if fileManager.fileExists(atPath: destinationFolderURL.path) {
            try fileManager.removeItem(at: destinationFolderURL)
        }
        try fileManager.createDirectory(at: destinationFolderURL, withIntermediateDirectories: true, attributes: nil)
        return destinationFolderURL
    }

    /// 构造所要下载的文件清单任务列表
    private func buildDownloadTasks(baseURL: URL, destinationFolderURL: URL) -> [FileDownloadTask] {
        return [
            FileDownloadTask(
                remoteURL: baseURL.appendingPathComponent("manifest.json"),
                localURL: destinationFolderURL.appendingPathComponent("manifest.json"),
                isRequired: true
            ),
            FileDownloadTask(
                remoteURL: baseURL.appendingPathComponent("index.js"),
                localURL: destinationFolderURL.appendingPathComponent("index.js"),
                isRequired: true
            ),
            FileDownloadTask(
                remoteURL: baseURL.appendingPathComponent("icon.png"),
                localURL: destinationFolderURL.appendingPathComponent("icon.png"),
                isRequired: false
            ),
            FileDownloadTask(
                remoteURL: baseURL.appendingPathComponent("README.md"),
                localURL: destinationFolderURL.appendingPathComponent("README.md"),
                isRequired: false
            ),
            FileDownloadTask(
                remoteURL: baseURL.appendingPathComponent("README.zh-Hans.md"),
                localURL: destinationFolderURL.appendingPathComponent("README.zh-Hans.md"),
                isRequired: false
            )
        ]
    }

    /// 并发吞吐执行网络拉取文件任务组，控制错误传递
    private func executeDownloadTasks(_ tasks: [FileDownloadTask]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for task in tasks {
                group.addTask {
                    do {
                        let (tempURL, response) = try await URLSession.shared.download(from: task.remoteURL)
                        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                        guard statusCode == 200 else {
                            throw NSError(
                                domain: "PluginMarketService",
                                code: statusCode,
                                userInfo: [NSLocalizedDescriptionKey: "HTTP \(statusCode)"]
                            )
                        }
                        
                        if FileManager.default.fileExists(atPath: task.localURL.path) {
                            try FileManager.default.removeItem(at: task.localURL)
                        }
                        try FileManager.default.moveItem(at: tempURL, to: task.localURL)
                        Logger.shared.info("[PluginMarket] 成功下载明文文件: \(task.remoteURL.lastPathComponent)")
                    } catch {
                        if task.isRequired {
                            throw error
                        } else {
                            Logger.shared.warning(
                                "[PluginMarket] 辅助资源拉取跳过: \(task.remoteURL.lastPathComponent), error: \(error.localizedDescription)"
                            )
                        }
                    }
                }
            }
            try await group.waitForAll()
        }
    }

    /// 发生异常时的下载清理回滚动作
    private func performDownloadRollback(for pluginID: String, fileManager: FileManager) {
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let destinationFolderURL = documentsURL.appendingPathComponent("Plugins").appendingPathComponent(pluginID)
            if fileManager.fileExists(atPath: destinationFolderURL.path) {
                try? fileManager.removeItem(at: destinationFolderURL)
            }
        }
    }

    /// 获取云端 README.md 拉取时的候选 URL 降级路径数组（支持根据当前首选语言自动降级）
    /// - Parameters:
    ///   - pluginID: 插件 ID 标识
    ///   - downloadURLString: 插件下载物理包的 URL 地址字符串
    ///   - preferredLanguages: 系统首选语言链条，默认自 Locale.preferredLanguages 自动生成，允许单测注入
    /// - Returns: 按尝试优先级从高到低排列的 URL 数组。
    public func readmeCandidateURLs(
        forID pluginID: String,
        downloadURLString: String,
        preferredLanguages: [String] = Locale.preferredLanguages
    ) -> [URL] {
        guard let downloadURL = URL(string: downloadURLString) else { return [] }
        let base = downloadURL.deletingLastPathComponent()
        let preferredLanguage = preferredLanguages.first ?? "en"
        
        var urlsToTry: [URL] = []
        // 1. 优先拼接首选语言专属的 README (如 _zh-Hans.md / _en.md)
        if preferredLanguage.hasPrefix("zh") {
            urlsToTry.append(base.appendingPathComponent("\(pluginID)_zh-Hans.md"))
        } else if preferredLanguage.hasPrefix("en") {
            urlsToTry.append(base.appendingPathComponent("\(pluginID)_en.md"))
        } else {
            let cleanLang = preferredLanguage.components(separatedBy: "-").first ?? preferredLanguage
            urlsToTry.append(base.appendingPathComponent("\(pluginID)_\(cleanLang).md"))
        }
        
        // 2. 其次添加英文版 README 兜底 (若首选语言不是英文)
        if !preferredLanguage.hasPrefix("en") {
            urlsToTry.append(base.appendingPathComponent("\(pluginID)_en.md"))
        }
        
        // 3. 最后使用默认 README.md 文件无后缀路径兜底
        urlsToTry.append(base.appendingPathComponent("\(pluginID).md"))
        
        return urlsToTry
    }
}

/// 文件下载清单描述结构
private struct FileDownloadTask: Sendable {
    let remoteURL: URL
    let localURL: URL
    let isRequired: Bool
}

extension PluginMarketService: @unchecked Sendable {}
