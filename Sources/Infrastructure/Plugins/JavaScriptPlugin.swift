#if canImport(JavaScriptCore)
// JavaScriptPlugin.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基于 JavaScriptCore 的沙箱插件实现
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import JavaScriptCore

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
/// JS 看门狗超时熔断回调类型，返回 0/1 (Int32)
typealias JSShouldTerminateCallback = @convention(c) (JSContextGroupRef?, UnsafeMutableRawPointer?) -> Int32

@_silgen_name("JSContextGroupSetExecutionTimeLimit")
func JSContextGroupSetExecutionTimeLimit(
    _ group: JSContextGroupRef?,
    _ limit: Double,
    _ callback: JSShouldTerminateCallback?,
    _ context: UnsafeMutableRawPointer?
)
#endif


/// 基于 JS 脚本的动态插件
final class JavaScriptPlugin: InterceptionPlugin {
    let manifest: PluginManifest
    let monetization: MonetizationInfo?
    
    private let context: JSContext
    private var pluginContext: PluginContext?
    
    init?(script: String, manifest: PluginManifest, monetization: MonetizationInfo? = nil) {
        self.manifest = manifest
        self.monetization = monetization
        
        guard let ctx = JSContext() else { return nil }
        self.context = ctx
        
        // 异常处理
        context.exceptionHandler = { ctx, exception in
            if let ctx = ctx, let exception = exception {
                ctx.exception = exception
            }
            Logger.shared.error("🔥 [JSPlugin: \(manifest.id)] Exception: \(exception?.toString() ?? "unknown")", error: nil)
        }
        
        // 加载脚本
        context.evaluateScript(script)
    }
    
    func onLoad(context: PluginContext) {
        self.pluginContext = context
        
        // 1. 定义具备 100% 严格并发安全的 JS 桥接 C 闭包 (Blocks)
        let logBlock: @convention(block) (String) -> Void = { msg in
            DispatchQueue.main.async {
                context.log(msg)
            }
        }
        
        let registerCommandBlock: @convention(block) (String, String, String) -> Void = { [weak self] id, name, funcName in
            DispatchQueue.main.async {
                guard let self = self else { return }
                context.registerCommand(id: id, name: name) {
                    if let jsFunc = self.context.objectForKeyedSubscript(funcName), !jsFunc.isUndefined {
                        jsFunc.call(withArguments: [])
                    }
                }
            }
        }
        
        let registerRibbonItemBlock: @convention(block) (String, String, String) -> Void = { [weak self] icon, title, funcName in
            DispatchQueue.main.async {
                guard let self = self else { return }
                context.registerRibbonItem(icon: icon, title: title) {
                    if let jsFunc = self.context.objectForKeyedSubscript(funcName), !jsFunc.isUndefined {
                        jsFunc.call(withArguments: [])
                    }
                }
            }
        }
        
        let registerSettingTabBlock: @convention(block) (String, String?, String) -> Void = { [weak self] name, schema, funcName in
            DispatchQueue.main.async {
                guard let self = self else { return }
                context.registerSettingTab(name: name, schema: schema) { data in
                    if let jsFunc = self.context.objectForKeyedSubscript(funcName), !jsFunc.isUndefined {
                        jsFunc.call(withArguments: data != nil ? [data!] : [])
                    }
                }
            }
        }
        
        let registerViewBlock: @convention(block) (String, String, String, String) -> Void = { [weak self] id, title, icon, funcName in
            DispatchQueue.main.async {
                guard let self = self else { return }
                context.registerView(id: id, title: title, icon: icon) {
                    if let jsFunc = self.context.objectForKeyedSubscript(funcName), !jsFunc.isUndefined {
                        jsFunc.call(withArguments: [])
                    }
                }
            }
        }
        
        let addEventListenerBlock: @convention(block) (String, String) -> Void = { [weak self] event, funcName in
            DispatchQueue.main.async {
                guard let self = self else { return }
                context.addEventListener(event: event) { data in
                    if let jsFunc = self.context.objectForKeyedSubscript(funcName), !jsFunc.isUndefined {
                        jsFunc.call(withArguments: [])
                    }
                }
            }
        }
        
        let saveDataBlock: @convention(block) (String, String) -> Void = { key, value in
            DispatchQueue.main.async {
                do {
                    // 通信网关审计：拦截限制存储键名及值大小
                    try PluginSandboxGateway.auditStorage(key: key, value: value)
                    context.saveData(key: key, value: value)
                } catch {
                    context.log("❌ [DLP拦截] saveData错误: \(error.localizedDescription)")
                }
            }
        }
        
        let loadDataBlock: @convention(block) (String) -> String? = { key in
            var result: String?
            DispatchQueue.main.sync {
                result = context.loadData(key: key)
            }
            return result
        }
        
        let fetchBlock: @convention(block) (String, [String: Any]?, String) -> Void = { [weak self] url, options, funcName in
            DispatchQueue.main.async {
                guard let self = self else { return }
                Task {
                    do {
                        // 通信网关审计：DLP 域名白名单与网络载荷审计
                        let allowed = self.manifest.allowedDomains ?? []
                        let request = try PluginSandboxGateway.auditFetch(url: url, options: options, allowedDomains: allowed)
                        
                        // 执行安全的网络请求
                        let (data, _) = try await URLSession.shared.data(for: request)
                        let responseString = String(data: data, encoding: .utf8) ?? ""
                        
                        // 请求完成，顺手触发 GC 减小内存驻留
                        JSGarbageCollect(self.context.jsGlobalContextRef)
                        
                        if let jsFunc = self.context.objectForKeyedSubscript(funcName), !jsFunc.isUndefined {
                            jsFunc.call(withArguments: [responseString])
                        }
                    } catch {
                        context.log("❌ [FetchError] \(error.localizedDescription)")
                    }
                }
            }
        }
        
        // 2. 注入桥接好的 API 字典对象到 JS 上下文中
        let jsContextObj: [String: Any] = [
            "log": unsafeBitCast(logBlock, to: AnyObject.self),
            "registerCommand": unsafeBitCast(registerCommandBlock, to: AnyObject.self),
            "registerRibbonItem": unsafeBitCast(registerRibbonItemBlock, to: AnyObject.self),
            "registerSettingTab": unsafeBitCast(registerSettingTabBlock, to: AnyObject.self),
            "registerView": unsafeBitCast(registerViewBlock, to: AnyObject.self),
            "addEventListener": unsafeBitCast(addEventListenerBlock, to: AnyObject.self),
            "saveData": unsafeBitCast(saveDataBlock, to: AnyObject.self),
            "loadData": unsafeBitCast(loadDataBlock, to: AnyObject.self),
            "fetch": unsafeBitCast(fetchBlock, to: AnyObject.self)
        ]
        
        self.context.setObject(jsContextObj, forKeyedSubscript: "ZhiYu" as NSString)
        
        // 调用 JS onLoad (注入 0.5s CPU 看门狗)
        if let onLoadFunc = self.context.objectForKeyedSubscript("onLoad"), !onLoadFunc.isUndefined {
            let group = JSContextGetGroup(self.context.jsGlobalContextRef)
            JSContextGroupSetExecutionTimeLimit(group, 0.5, { _, _ in return 1 }, nil)
            defer {
                JSContextGroupSetExecutionTimeLimit(group, 0, nil, nil)
                JSGarbageCollect(self.context.jsGlobalContextRef)
            }
            onLoadFunc.call(withArguments: [])
        }
    }
    
    func onUnload() {
        if let onUnloadFunc = self.context.objectForKeyedSubscript("onUnload"), !onUnloadFunc.isUndefined {
            let group = JSContextGetGroup(self.context.jsGlobalContextRef)
            JSContextGroupSetExecutionTimeLimit(group, 0.5, { _, _ in return 0 }, nil)
            defer {
                JSContextGroupSetExecutionTimeLimit(group, 0, nil, nil)
                JSGarbageCollect(self.context.jsGlobalContextRef)
            }
            onUnloadFunc.call(withArguments: [])
        }
        self.pluginContext = nil
    }
    
    private let maxResponseSize = 5 * 1024 * 1024 // 5MB 限制
    
    func preProcess(content: String) throws -> String {
        if let preProcessFunc = self.context.objectForKeyedSubscript("preProcess"), !preProcessFunc.isUndefined {
            let group = JSContextGetGroup(self.context.jsGlobalContextRef)
            // 物理硬限流：注入 0.5 秒 CPU 时间熔断看门狗
            JSContextGroupSetExecutionTimeLimit(group, 0.5, { _, _ in return 1 }, nil)
            
            defer {
                JSContextGroupSetExecutionTimeLimit(group, 0, nil, nil)
                JSGarbageCollect(self.context.jsGlobalContextRef)
            }
            
            let result = preProcessFunc.call(withArguments: [content])
            
            // 检查 CPU 超时异常或插件内部崩溃
            if let exception = context.exception {
                context.exception = nil
                throw NSError(
                    domain: "PluginSandbox",
                    code: 408,
                    userInfo: [NSLocalizedDescriptionKey: L10n.Plugin.Error.preProcessException(exception.toString() ?? "unknown")]
                )
            }
            
            let resultString = result?.toString() ?? content
            
            // Watchdog 2.0: 内存大小检查
            if resultString.count > maxResponseSize {
                throw NSError(domain: "PluginSandbox", code: 413, userInfo: [NSLocalizedDescriptionKey: L10n.Plugin.Error.payloadTooLarge])
            }
            return resultString
        }
        return content
    }
    
    func postProcess(content: String) throws -> String {
        if let postProcessFunc = self.context.objectForKeyedSubscript("postProcess"), !postProcessFunc.isUndefined {
            let group = JSContextGetGroup(self.context.jsGlobalContextRef)
            // 物理硬限流：注入 0.5 秒 CPU 时间熔断看门狗
            JSContextGroupSetExecutionTimeLimit(group, 0.5, { _, _ in return 1 }, nil)
            
            defer {
                JSContextGroupSetExecutionTimeLimit(group, 0, nil, nil)
                JSGarbageCollect(self.context.jsGlobalContextRef)
            }
            
            let result = postProcessFunc.call(withArguments: [content])
            
            // 检查 CPU 超时或插件崩溃
            if let exception = context.exception {
                context.exception = nil
                throw NSError(
                    domain: "PluginSandbox",
                    code: 408,
                    userInfo: [NSLocalizedDescriptionKey: L10n.Plugin.Error.postProcessException(exception.toString() ?? "unknown")]
                )
            }
            
            return result?.toString() ?? content
        }
        return content
    }
}

#endif
