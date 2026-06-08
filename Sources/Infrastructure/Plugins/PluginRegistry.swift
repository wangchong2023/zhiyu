//
//  PluginRegistry.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：插件系统：JavaScript 沙箱、市场服务、插件注册与生命周期。
//
import Foundation
import Combine
import ZIPFoundation

/// 插件注册中心 (L2 层：中枢管理)
@MainActor
final class PluginRegistry: ObservableObject {
    static let shared = PluginRegistry()

    @Published var plugins: [KnowledgePlugin] = []
    @Published var commands: [PluginCommand] = []
    @Published var ribbonItems: [PluginRibbonItem] = []
    @Published var settingTabs: [PluginSettingTab] = []
    @Published var customViews: [PluginCustomView] = []
    
    /// 插件资源消耗快照 (Watchdog 2.0)
    public struct ResourceUsage: Sendable {
        public var totalExecutionTime: TimeInterval = 0
        public var callCount: Int = 0
        public var lastExecutionTime: TimeInterval = 0
        public var status: Status = .active
        
        public enum Status: String, Sendable {
            case active, throttled, suspended
        }
    }
    
    @Published public private(set) var pluginResourceUsage: [String: ResourceUsage] = [:]

    private var eventListeners: [PluginEventListener] = []
    private var intercepters: [InterceptionPlugin] = []
    
    /// 已挂起的插件 ID (Security Watchdog)
    /// 采用持久化存储，防止僵尸插件在重启后循环导致崩溃。
    private var suspendedPluginIDs: Set<String> = {
        let saved = UserDefaults.standard.stringArray(forKey: AppConstants.Keys.Storage.suspendedPlugins) ?? []
        return Set(saved)
    }()

    // 注入分析服务
    var analytics: (any AnalyticsServiceProtocol)?

    // 数据提供者：用于将核心数据（如页面列表）安全传递给沙盒
    var pagesProvider: (@Sendable () -> [KnowledgePage])?

    // 内核版本定义
    nonisolated let currentHostVersion = "2.0.0"

    // 超时配置：单插件最大执行时间 0.5s
    private let pluginTimeout: TimeInterval = 0.5

    // 限流配置
    private var pluginCallCounts: [String: Int] = [:]
    private let maxCallsPerWindow = 50
    private let throttlingWindow: TimeInterval = 60.0 // 1分钟

    private init() {}

    /// 重置注册中心状态（仅用于测试）
    func reset() {
        for plugin in plugins {
            plugin.onUnload()
        }
        plugins.removeAll()
        intercepters.removeAll()
        commands.removeAll()
        ribbonItems.removeAll()
        settingTabs.removeAll()
        customViews.removeAll()
        eventListeners.removeAll()
        suspendedPluginIDs.removeAll()
        UserDefaults.standard.removeObject(forKey: AppConstants.Keys.Storage.suspendedPlugins)
        pluginCallCounts.removeAll()
        pluginResourceUsage.removeAll()
    }

    /// 标记并持久化封禁插件
    private func suspendPlugin(_ id: String) {
        suspendedPluginIDs.insert(id)
        let array = Array(suspendedPluginIDs)
        UserDefaults.standard.set(array, forKey: AppConstants.Keys.Storage.suspendedPlugins)
        
        // 物理回收：从活跃插件列表中彻底移除，释放 JSContext 内存
        if let index = plugins.firstIndex(where: { $0.manifest.id == id }) {
            let plugin = plugins[index]
            plugin.onUnload()
            plugins.remove(at: index)
        }
        intercepters.removeAll(where: { $0.manifest.id == id })
        commands.removeAll(where: { $0.pluginID == id })
        ribbonItems.removeAll(where: { $0.pluginID == id })
        settingTabs.removeAll(where: { $0.pluginID == id })
        customViews.removeAll(where: { $0.pluginID == id })
        
        // 更新资源状态
        var usage = pluginResourceUsage[id] ?? ResourceUsage()
        usage.status = .suspended
        pluginResourceUsage[id] = usage
        
        Logger.shared.error(" [Watchdog 2.0]  \(id) ")
    }

    // MARK: - 插件数据持久化 (委托至 PluginDataStore)

    /// 插件数据持久化实例
    private let dataStore = PluginDataStore()

    /// 保存插件私有数据
    func savePluginData(pluginID: String, key: String, value: String) {
        dataStore.savePluginData(pluginID: pluginID, key: key, value: value)
    }

    /// 读取插件私有数据
    func loadPluginData(pluginID: String, key: String) -> String? {
        dataStore.loadPluginData(pluginID: pluginID, key: key)
    }

    /// 获取插件的所有持久化数据（解密后）
    func loadAllPluginData(pluginID: String) -> [String: String] {
        dataStore.loadAllPluginData(pluginID: pluginID)
    }

    /// 加载Plugin
    /// - Parameter plugin: plugin
    func loadPlugin(_ plugin: KnowledgePlugin) {
        // 去重检查：防止重复加载已存在的插件
        guard !plugins.contains(where: { $0.manifest.id == plugin.manifest.id }) else {
            Logger.shared.info("[PluginRegistry] Skipped duplicate: \(plugin.manifest.id)")
            return
        }

        // 安全检查：如果该插件已被持久化封禁，禁止加载
        guard !suspendedPluginIDs.contains(plugin.manifest.id) else {
            Logger.shared.warning("[Security] Blocked: \(plugin.manifest.id)")
            return
        }

        // 版本兼容性检查
        if plugin.manifest.version.hasPrefix("1.") {
            Logger.shared.debug(" [Adapter]  1.x  \(plugin.manifest.name) v1_Compatibility_Shim")
        }

        // 创建沙盒上下文
        let context = PluginContextImpl(manifest: plugin.manifest)

        plugin.onLoad(context: context)
        plugins.append(plugin)
        if let intercepter = plugin as? InterceptionPlugin {
            intercepters.append(intercepter)
        }
        
        // 初始化统计
        if pluginResourceUsage[plugin.manifest.id] == nil {
            pluginResourceUsage[plugin.manifest.id] = ResourceUsage()
        }
        
        analytics?.trackEvent("plugin_loaded", properties: ["id": plugin.manifest.id])
    }

    // MARK: - Plugin Context Implementation
    @MainActor
    private struct PluginContextImpl: PluginContext {
        let manifest: PluginManifest
        var hostVersion: String { "2.0.0" } // nonisolated copy, avoids @MainActor crossing

        /// 记录日志
        /// - Parameter message: message
        func log(_ message: String) {
            Logger.shared.debug(" [Plugin:\(manifest.id)] \(message)")
        }

        /// 请求AIAccess
        /// - Parameter prompt: prompt
        /// - Returns: 可选值
        func requestAIAccess(prompt: String) async -> String? {
            // 安全检查：检查 manifest 是否声明了 'llm' 权限
            guard manifest.permissions.contains("llm") else {
                Logger.shared.error(" []" + "  \(manifest.id)" + "  LLM" + " manifest " + " 'llm' ", error: nil)
                return nil
            }
            return try? await ServiceContainer.shared.resolve((any LLMServiceProtocol).self).generate(prompt: prompt, systemPrompt: "")
        }

        /// queryPages
        /// - Returns: 列表
        func queryPages(matching query: String) async -> [KnowledgePage] {
            guard manifest.permissions.contains("pages.read") else {
                Logger.shared.error(" []  \(manifest.id)  'pages.read' ", error: nil)
                return []
            }
            let pages = PluginRegistry.shared.pagesProvider?() ?? []
            return await ServiceContainer.shared.resolve(LinkService.self).search(query: query, in: pages)
        }
        
        /// 注册Command
        /// - Parameter id: id
        /// - Parameter name: name
        /// - Parameter callback: callback
        /// - Returns: 返回值
        func registerCommand(id: String, name: String, callback: @escaping @MainActor () -> Void) {
            let command = PluginCommand(id: id, pluginID: manifest.id, name: name, action: callback)
            PluginRegistry.shared.commands.append(command)
            log(": \(name)")
        }
        
        /// 注册RibbonItem
        /// - Parameter icon: icon
        /// - Parameter title: title
        /// - Parameter callback: callback
        /// - Returns: 返回值
        func registerRibbonItem(icon: String, title: String, callback: @escaping @MainActor () -> Void) {
            let item = PluginRibbonItem(pluginID: manifest.id, icon: icon, title: title, action: callback)
            PluginRegistry.shared.ribbonItems.append(item)
            log(": \(title)")
        }

        /// 注册PageProcessor
        /// - Parameter processor: processor
        func registerPageProcessor(_ processor: any KnowledgePageProcessor) {
            guard let store = ServiceContainer.shared.optionalResolve(KnowledgeStore.self) else { return }
            store.registerProcessor(processor, pluginID: manifest.id)
            log(": \(processor.name)")
        }
        
        /// 注册SettingTab
        /// - Parameter name: name
        /// - Parameter schema: schema
        /// - Parameter callback: callback
        /// - Returns: 返回值
        func registerSettingTab(name: String, schema: String?, callback: @escaping @MainActor (String?) -> Void) {
            let tab = PluginSettingTab(pluginID: manifest.id, name: name, schema: schema, action: callback)
            PluginRegistry.shared.settingTabs.append(tab)
            log(": \(name)")
        }
        
        /// 注册View
        /// - Parameter id: id
        /// - Parameter title: title
        /// - Parameter icon: icon
        /// - Parameter callback: callback
        /// - Returns: 返回值
        func registerView(id: String, title: String, icon: String, callback: @escaping @MainActor () -> Void) {
            let view = PluginCustomView(id: id, pluginID: manifest.id, title: title, icon: icon, action: callback)
            PluginRegistry.shared.customViews.append(view)
            log(": \(title)")
        }
        
        /// 添加EventListener
        /// - Parameter event: event
        /// - Parameter callback: callback
        /// - Returns: 返回值
        func addEventListener(event: String, callback: @escaping @MainActor (Any?) -> Void) {
            let listener = PluginEventListener(pluginID: manifest.id, event: event, callback: callback)
            PluginRegistry.shared.eventListeners.append(listener)
            log(": \(event)")
        }
        
        /// 保存Data
        /// - Parameter key: key
        /// - Parameter value: value
        func saveData(key: String, value: String) {
            PluginRegistry.shared.savePluginData(pluginID: manifest.id, key: key, value: value)
        }
        
        /// 加载Data
        /// - Parameter key: key
        /// - Returns: 可选值
        func loadData(key: String) -> String? {
            return PluginRegistry.shared.loadPluginData(pluginID: manifest.id, key: key)
        }
    }

    /// 卸载插件：从内存移除并删除磁盘文件，防止重启后重新加载
    /// - Parameter id: 插件 ID
    func unloadPlugin(id: String) {
        if let index = plugins.firstIndex(where: { $0.manifest.id == id }) {
            plugins[index].onUnload()
            plugins.remove(at: index)
        }
        intercepters.removeAll(where: { $0.manifest.id == id })

        // 清理该插件注册的所有扩展点
        commands.removeAll(where: { $0.pluginID == id })
        ribbonItems.removeAll(where: { $0.pluginID == id })
        settingTabs.removeAll(where: { $0.pluginID == id })
        customViews.removeAll(where: { $0.pluginID == id })
        eventListeners.removeAll(where: { $0.pluginID == id })

        // 安全注销页面处理器
        if let store = ServiceContainer.shared.optionalResolve(KnowledgeStore.self) {
            store.unregisterProcessors(for: id)
        }

        // 删除磁盘上的插件文件，防止重启后重新加载
        removePluginFilesFromDisk(pluginID: id)

        analytics?.trackEvent("plugin_unloaded", properties: ["id": id])
    }

    // MARK: - 磁盘清理

    /// 删除插件在磁盘上的 .zyplugin 和 .js 文件
    private func removePluginFilesFromDisk(pluginID: String) {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let pluginsDir = documentsURL.appendingPathComponent("Plugins")

        // 匹配策略：pluginID 或 ID 的部分匹配文件名
        let patterns = [
            "\(pluginID).zyplugin",
            "\(pluginID).js",
        ]

        for pattern in patterns {
            let fileURL = pluginsDir.appendingPathComponent(pattern)
            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    try fileManager.removeItem(at: fileURL)
                    Logger.shared.info("[PluginRegistry] Deleted: \(fileURL.lastPathComponent)")
                } catch {
                    Logger.shared.error("[PluginRegistry] Failed to delete \(fileURL.lastPathComponent)", error: error)
                }
            }
        }

        // 模糊匹配：删除包含 pluginID 片段的文件（兼容旧格式）
        do {
            let files = try fileManager.contentsOfDirectory(at: pluginsDir, includingPropertiesForKeys: nil)
            let idSlug = pluginID.replacingOccurrences(of: "com.zhiyu.plugin.", with: "")
            for file in files {
                let name = file.deletingPathExtension().lastPathComponent
                if name.contains(idSlug) || name == pluginID {
                    try? fileManager.removeItem(at: file)
                    Logger.shared.info("[PluginRegistry] Cleaned up: \(file.lastPathComponent)")
                }
            }
        } catch {
            Logger.shared.error("[PluginRegistry] Cleanup scan error", error: error)
        }
    }

    /// 分发事件给插件监听器
    func emitEvent(_ event: String, data: Any? = nil) {
        let relevant = eventListeners.filter { $0.event == event }
        for listener in relevant {
            listener.callback(data)
        }
    }

    /// 执行全量拦截过滤 (含超时熔断逻辑)
    func applyPreProcess(to content: String) -> String {
        var result = content

        for intercepter in plugins.compactMap({ $0 as? InterceptionPlugin }) {
            let pluginID = intercepter.manifest.id
            
            // 安全隔离：过滤已挂起的插件
            guard !suspendedPluginIDs.contains(pluginID) else { continue }
            
            // 动态流控监控 (Throttling)
            let callCount = pluginCallCounts[pluginID] ?? 0
            if callCount > maxCallsPerWindow {
                Logger.shared.debug(" [Throttling]  \(pluginID) ")
                continue
            }
            pluginCallCounts[pluginID] = callCount + 1

            // 异步重置计数器 (简易窗口期)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(throttlingWindow * 1_000_000_000))
                self.pluginCallCounts[pluginID] = 0
            }

            let start = CFAbsoluteTimeGetCurrent()

            // 安全校验：权限检查
            if !intercepter.manifest.permissions.contains("writeContent") {
                Logger.shared.error(" []  \(intercepter.manifest.name)  writeContent ", error: nil)
                continue
            }

            do {
                let processed = try intercepter.preProcess(content: result)
                let duration = CFAbsoluteTimeGetCurrent() - start

                // 更新性能指标
                var usage = pluginResourceUsage[pluginID] ?? ResourceUsage()
                usage.lastExecutionTime = duration
                usage.totalExecutionTime += duration
                usage.callCount += 1
                pluginResourceUsage[pluginID] = usage

                if duration > pluginTimeout {
                    Logger.shared.error(" [Watchdog]  \(intercepter.manifest.name)  (\(String(format: "%.2f", duration))s)")
                    suspendPlugin(pluginID) // 物理封禁并持久化
                    analytics?.trackEvent("plugin_circuit_break", properties: ["id": pluginID, "duration": duration])
                    continue // 丢弃该插件结果
                }

                result = processed

                // 埋点：插件执行成功，记录时长
                analytics?.trackEvent("plugin_intercepted", properties: [
                    "id": pluginID,
                    "duration": duration,
                    "type": "preProcess"
                ])
            } catch {
                Logger.shared.error(" []  \(intercepter.manifest.name) ", error: error)
                analytics?.trackEvent("plugin_crash", properties: ["id": pluginID, "error": error.localizedDescription])
                // 如果连续异常多次，也可以考虑在此挂起
            }
        }

        return result
    }
}

// MARK: - 插件自动发现机制
extension PluginRegistry {
    /// 从本地沙盒目录扫描并加载外部脚本插件 (规范化加载机制)
    /// - Note: 实际运行中，此方法应在 App 启动后异步调用，不阻塞主线程。
    func scanAndLoadLocalPlugins() {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let pluginsDirectory = documentsURL.appendingPathComponent("Plugins")

        if !fileManager.fileExists(atPath: pluginsDirectory.path) {
            try? fileManager.createDirectory(at: pluginsDirectory, withIntermediateDirectories: true, attributes: nil)
            Logger.shared.info("[PluginRegistry] Created: \(pluginsDirectory.path)")
            return
        }

        do {
            let files = try fileManager.contentsOfDirectory(at: pluginsDirectory, includingPropertiesForKeys: nil)

            for file in files {
                let ext = file.pathExtension.lowercased()

                switch ext {
                case "zyplugin":
                    // .zyplugin 是标准 ZIP 格式，内含 manifest.json + index.js
                    loadPluginFromArchive(file)

                case "js":
                    // 兼容裸 .js 文件（使用内置占位 manifest）
                    loadPluginFromRawJS(file)

                default:
                    continue
                }
            }
        } catch {
            Logger.shared.error("[PluginRegistry] Scan error", error: error)
        }
    }

    // MARK: - 多语言 README 校验

    /// 校验插件包中是否包含 manifest.readmeFiles 声明的所有多语言 README
    private func validateReadmeFiles(manifest: PluginManifest, extractedDir: URL) {
        guard let readmeMap = manifest.readmeFiles, !readmeMap.isEmpty else {
            Logger.shared.warning("[PluginRegistry] \(manifest.id): manifest 未声明 readmeFiles，建议添加多语言 README")
            return
        }

        for (locale, filename) in readmeMap {
            let fileURL = extractedDir.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                Logger.shared.info("[PluginRegistry] \(manifest.id): README.\(locale) ✓")
            } else {
                Logger.shared.warning("[PluginRegistry] \(manifest.id): README.\(locale) (\(filename)) 缺失")
            }
        }

        // 强制要求至少 en 和 zh-Hans
        let requiredLocales = ["en", "zh-Hans"]
        for locale in requiredLocales {
            guard let filename = readmeMap[locale] else {
                Logger.shared.warning("[PluginRegistry] \(manifest.id): readmeFiles 缺少 \(locale) 语言")
                continue
            }
            let fileURL = extractedDir.appendingPathComponent(filename)
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                Logger.shared.warning("[PluginRegistry] \(manifest.id): \(locale) README 文件 (\(filename)) 未找到")
            }
        }
    }

    // MARK: - 持久化资源

    /// 从解压目录复制 icon.png + README 到 Documents/Plugins/{id}_*
    private func persistPluginAssets(manifest: PluginManifest, extractedDir: URL) {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let assetsDir = documentsURL.appendingPathComponent("Plugins")
        try? fileManager.createDirectory(at: assetsDir, withIntermediateDirectories: true)

        // 保存图标
        if let iconFile = manifest.iconFile {
            let src = extractedDir.appendingPathComponent(iconFile)
            let dst = assetsDir.appendingPathComponent("\(manifest.id)_icon.png")
            try? fileManager.removeItem(at: dst)
            if fileManager.fileExists(atPath: src.path) {
                try? fileManager.copyItem(at: src, to: dst)
                Logger.shared.info("[PluginRegistry] \(manifest.id): icon saved")
            }
        }

        // 保存多语言 README
        if let readmeMap = manifest.readmeFiles {
            for (locale, filename) in readmeMap {
                let src = extractedDir.appendingPathComponent(filename)
                let dst = assetsDir.appendingPathComponent("\(manifest.id)_\(locale).md")
                try? fileManager.removeItem(at: dst)
                if fileManager.fileExists(atPath: src.path) {
                    try? fileManager.copyItem(at: src, to: dst)
                }
            }
        }
    }

    /// 获取已安装插件的图标 URL
    public func iconURL(for pluginID: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let url = documentsURL.appendingPathComponent("Plugins/\(pluginID)_icon.png")
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    /// 获取已安装插件的本地化 README 内容
    public func localizedReadme(for pluginID: String) -> String? {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }

        // 尝试用户语言 → en fallback
        for locale in [lang, "en"] {
            let url = documentsURL.appendingPathComponent("Plugins/\(pluginID)_\(locale).md")
            if fileManager.fileExists(atPath: url.path) {
                return try? String(contentsOf: url, encoding: .utf8)
            }
        }
        return nil
    }

    // MARK: - .zyplugin 加载（ZIPFoundation 文件提取）

    /// 使用 ZIPFoundation 解压 .zyplugin：提取到临时文件后读取，确保数据完整性
    private func loadPluginFromArchive(_ archiveURL: URL) {
        do {
            // 创建临时目录
            let tempDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("plugin_\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            // 打开 ZIP 归档
            let archive: Archive
            do {
                archive = try Archive(url: archiveURL, accessMode: .read)
            } catch {
                Logger.shared.error("[PluginRegistry] Cannot open archive: \(archiveURL.lastPathComponent), error: \(error)")
                return
            }

            // 提取所有条目到文件（ZIPFoundation 文件提取保证数据完整）
            for entry in archive {
                let entryPath = entry.path
                guard !entryPath.contains("..") else {
                    Logger.shared.warning("[PluginRegistry] Skipped: \(entryPath)")
                    continue
                }
                let destURL = tempDir.appendingPathComponent(entryPath)
                // 确保父目录存在（处理 ZIP 内目录结构）
                try? FileManager.default.createDirectory(at: destURL.deletingLastPathComponent(),
                                                         withIntermediateDirectories: true)
                _ = try archive.extract(entry, to: destURL)
            }

            // 读取提取的文件
            let manifestURL = tempDir.appendingPathComponent("manifest.json")
            let scriptURL = tempDir.appendingPathComponent("index.js")

            guard FileManager.default.fileExists(atPath: manifestURL.path),
                  FileManager.default.fileExists(atPath: scriptURL.path) else {
                Logger.shared.error("[PluginRegistry] .zyplugin missing manifest.json or index.js")
                return
            }

            let manifestData = try Data(contentsOf: manifestURL)
            let script = try String(contentsOf: scriptURL, encoding: .utf8)

            // [DEBUG] 打印前 200 字符验证完整性
            Logger.shared.info("[PluginRegistry] JS preview: \(String(script.prefix(80)).replacingOccurrences(of: "\n", with: " "))")

            let manifest = try JSONDecoder().decode(PluginManifest.self, from: manifestData)

            // 校验多语言 README 完整性
            validateReadmeFiles(manifest: manifest, extractedDir: tempDir)

            // 持久化图标和 README 到 Documents/Plugins/{id}_icon.png
            persistPluginAssets(manifest: manifest, extractedDir: tempDir)

            #if canImport(JavaScriptCore) && !os(watchOS)
            if let jsPlugin = JavaScriptPlugin(script: script, manifest: manifest) {
                loadPlugin(jsPlugin)
                Logger.shared.info("[PluginRegistry] Loaded: \(manifest.name)")
            } else {
                Logger.shared.error("[PluginRegistry] Init failed: \(manifest.name)")
            }
            #endif

        } catch {
            Logger.shared.error("[PluginRegistry] Archive error: \(archiveURL.lastPathComponent)", error: error)
        }
    }

    // MARK: - 裸 .js 加载（兼容旧格式）

    private func loadPluginFromRawJS(_ fileURL: URL) {
        do {
            let scriptContent = try String(contentsOf: fileURL, encoding: .utf8)
            let displayName = fileURL.deletingPathExtension().lastPathComponent
            let manifest = PluginManifest(
                id: "local.\(displayName)",
                version: "1.0.0",
                author: "Local Developer",
                permissions: ["log", "writeContent"],
                names: ["en": displayName],
                descriptions: ["en": "Legacy .js plugin (migrate to .zyplugin format)"]
            )

            #if canImport(JavaScriptCore) && !os(watchOS)
            if let jsPlugin = JavaScriptPlugin(script: scriptContent, manifest: manifest) {
                loadPlugin(jsPlugin)
                Logger.shared.info("[PluginRegistry] Loaded legacy .js: \(displayName)")
            }
            #endif
        } catch {
            Logger.shared.error("[PluginRegistry] Failed to load .js: \(fileURL.lastPathComponent)", error: error)
        }
    }
}