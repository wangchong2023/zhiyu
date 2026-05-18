// PluginRegistry.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：插件注册中心，负责插件的生命周期管理、权限管控及安全沙盒环境构建。
// MARK: [SR-04] 插件执行环境实施 API 访问白名单管控，防止沙盒逃逸
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import Combine

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
        
        Logger.shared.error("🛡️ [Watchdog 2.0] 插件 \(id) 已被物理隔离并强制回收内存资源。")
    }

    // MARK: - 插件数据持久化 (Phase 2)
    
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
    
    /// 保存插件私有数据
    func savePluginData(pluginID: String, key: String, value: String) {
        guard let url = dataURL(for: pluginID) else { return }
        
        var dict = loadAllPluginData(pluginID: pluginID)
        dict[key] = value
        
        // 序列化并加密
        if let encodedData = try? JSONEncoder().encode(dict),
           let jsonString = String(data: encodedData, encoding: .utf8),
           let encrypted = try? SecurityManager.shared.encrypt(jsonString) {
            try? encrypted.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    /// 读取插件私有数据
    func loadPluginData(pluginID: String, key: String) -> String? {
        return loadAllPluginData(pluginID: pluginID)[key]
    }

    /// 获取插件的所有持久化数据（解密后）
    func loadAllPluginData(pluginID: String) -> [String: String] {
        guard let url = dataURL(for: pluginID),
              let data = try? Data(contentsOf: url) else {
            return [:]
        }
        
        // 优先尝试 AES-GCM 解密
        if let contentString = String(data: data, encoding: .utf8),
           let decrypted = try? SecurityManager.shared.decrypt(contentString),
           let decryptedData = decrypted.data(using: .utf8),
           let dict = try? JSONDecoder().decode([String: String].self, from: decryptedData) {
            return dict
        } else if let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            // 回退尝试明文 JSON 解析 (兼容旧版本)
            return dict
        }
        
        return [:]
    }

    func loadPlugin(_ plugin: KnowledgePlugin) {
        // 安全检查：如果该插件已被持久化封禁，禁止加载
        guard !suspendedPluginIDs.contains(plugin.manifest.id) else {
            Logger.shared.warning("🚫 [Security] 插件 \(plugin.manifest.id) 处于封禁黑名单中，拒绝加载。")
            return
        }

        // 版本兼容性检查
        if plugin.manifest.version.hasPrefix("1.") {
            Logger.shared.debug("📦 [Adapter] 检测到 1.x 插件 \(plugin.manifest.name)，已启用 v1_Compatibility_Shim。")
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

        func log(_ message: String) {
            Logger.shared.debug("🔌 [Plugin:\(manifest.id)] \(message)")
        }

        func requestAIAccess(prompt: String) async -> String? {
            // 安全检查：检查 manifest 是否声明了 'llm' 权限
            guard manifest.permissions.contains("llm") else {
                Logger.shared.error("🛡️ [安全拦截] 插件 \(manifest.id) 尝试调用 LLM，但未在 manifest 中声明 'llm' 权限。", error: nil)
                return nil
            }
            return try? await ServiceContainer.shared.resolve((any LLMServiceProtocol).self).generate(prompt: prompt, systemPrompt: "你是一个智能插件辅助助手")
        }

        func queryPages(matching query: String) async -> [KnowledgePage] {
            guard manifest.permissions.contains("pages.read") else {
                Logger.shared.error("🛡️ [安全拦截] 插件 \(manifest.id) 尝试查询页面，但未声明 'pages.read' 权限。", error: nil)
                return []
            }
            let pages = await PluginRegistry.shared.pagesProvider?() ?? []
            return await ServiceContainer.shared.resolve(LinkService.self).search(query: query, in: pages)
        }
        
        func registerCommand(id: String, name: String, callback: @escaping @MainActor () -> Void) {
            let command = PluginCommand(id: id, pluginID: manifest.id, name: name, action: callback)
            PluginRegistry.shared.commands.append(command)
            log("已注册全局指令: \(name)")
        }
        
        func registerRibbonItem(icon: String, title: String, callback: @escaping @MainActor () -> Void) {
            let item = PluginRibbonItem(pluginID: manifest.id, icon: icon, title: title, action: callback)
            PluginRegistry.shared.ribbonItems.append(item)
            log("已注册侧边栏入口: \(title)")
        }
        
        func registerSettingTab(name: String, schema: String?, callback: @escaping @MainActor (String?) -> Void) {
            let tab = PluginSettingTab(pluginID: manifest.id, name: name, schema: schema, action: callback)
            PluginRegistry.shared.settingTabs.append(tab)
            log("已注册设置面板: \(name)")
        }
        
        func registerView(id: String, title: String, icon: String, callback: @escaping @MainActor () -> Void) {
            let view = PluginCustomView(id: id, pluginID: manifest.id, title: title, icon: icon, action: callback)
            PluginRegistry.shared.customViews.append(view)
            log("已注册自定义视图: \(title)")
        }
        
        func addEventListener(event: String, callback: @escaping @MainActor (Any?) -> Void) {
            let listener = PluginEventListener(pluginID: manifest.id, event: event, callback: callback)
            PluginRegistry.shared.eventListeners.append(listener)
            log("正在监听事件: \(event)")
        }
        
        func saveData(key: String, value: String) {
            PluginRegistry.shared.savePluginData(pluginID: manifest.id, key: key, value: value)
        }
        
        func loadData(key: String) -> String? {
            return PluginRegistry.shared.loadPluginData(pluginID: manifest.id, key: key)
        }
    }

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
        
        analytics?.trackEvent("plugin_unloaded", properties: ["id": id])
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
                Logger.shared.debug("⚠️ [Throttling] 插件 \(pluginID) 调用过于频繁，已自动降级。")
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
                Logger.shared.error("🛡️ [安全拦截] 插件 \(intercepter.manifest.name) 尝试修改内容，但未声明 writeContent 权限。", error: nil)
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
                    Logger.shared.error("🔴 [Watchdog] 插件 \(intercepter.manifest.name) 执行超时 (\(String(format: "%.2f", duration))s)，已被物理挂起。")
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
                Logger.shared.error("🛡️ [崩溃隔离] 插件 \(intercepter.manifest.name) 执行异常，已自动跳过。", error: error)
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
        
        // 如果目录不存在则创建
        if !fileManager.fileExists(atPath: pluginsDirectory.path) {
            try? fileManager.createDirectory(at: pluginsDirectory, withIntermediateDirectories: true, attributes: nil)
            Logger.shared.info("📁 [PluginRegistry] 已创建插件目录: \(pluginsDirectory.path)")
            return
        }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: pluginsDirectory, includingPropertiesForKeys: nil)
            for file in files where file.pathExtension == "js" {
                // 生产环境需进一步读取配套的 manifest.json，此处仅作示例
                let scriptContent = try String(contentsOf: file, encoding: .utf8)
                let manifest = PluginManifest(
                    id: "local.\(file.lastPathComponent)",
                    version: "1.0.0",
                    author: "Local Developer",
                    permissions: ["log", "writeContent"],
                    names: ["en": file.deletingPathExtension().lastPathComponent],
                    descriptions: ["en": "Locally loaded script plugin."]
                )
                
                #if canImport(JavaScriptCore)
                if let jsPlugin = JavaScriptPlugin(script: scriptContent, manifest: manifest) {
                    self.loadPlugin(jsPlugin)
                    Logger.shared.info("🔌 [PluginRegistry] 成功自动加载外部插件: \(manifest.name)")
                }
#endif
            }
        } catch {
            Logger.shared.error("❌ [PluginRegistry] 扫描本地插件目录失败", error: error)
        }
    }
}
