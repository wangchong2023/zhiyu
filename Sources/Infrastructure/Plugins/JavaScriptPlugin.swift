//
//  JavaScriptPlugin.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：属于 Plugins 模块，提供相关的结构体或工具支撑。
//
#if canImport(JavaScriptCore) && !os(watchOS)

import Foundation
import JavaScriptCore

/// 基于 JS 脚本的动态插件，已接入 PluginEnginePool 缓存连接池
final class JavaScriptPlugin: InterceptionPlugin {
    let manifest: PluginManifest
    let monetization: MonetizationInfo?
    
    /// 保存的脚本内容以备在借出的 context 中执行
    private let scriptContent: String
    private var pluginContext: PluginContext?
    
    init?(script: String, manifest: PluginManifest, monetization: MonetizationInfo? = nil) {
        self.manifest = manifest
        self.monetization = monetization
        self.scriptContent = script
        
        // 初始时仅用于校验脚本是否合法
        let tempContext = JSContext()
        tempContext?.exceptionHandler = { ctx, exception in
            if let ctx = ctx, let exception = exception { ctx.exception = exception }
        }
        tempContext?.evaluateScript(script)
        if tempContext?.exception != nil {
            return nil
        }
    }
    
    /// 辅助方法：动态从池中租借 JSContext，装配 ZhiYu API 后执行，执行完后在 defer 中安全归还
    private func executeInContext<T>(_ body: (JSContext) throws -> T) throws -> T {
        let ctx = PluginEnginePool.shared.borrowContext()
        defer {
            PluginEnginePool.shared.returnContext(ctx)
        }
        
        // 1. 设置异常捕获器
        ctx.exceptionHandler = { [weak self] c, exception in
            guard let self = self else { return }
            if let c = c, let exception = exception {
                c.exception = exception
            }
            Logger.shared.error(" [JSPlugin: \(self.manifest.id)] Exception: \(exception?.toString() ?? "unknown")", error: nil)
        }
        
        // 2. 注入桥接好的 API
        setupAPI(in: ctx)

        // 2.2 核心安全加固：配置运行时看门狗护栏 (@SR-04)
        PluginSandboxGateway.configureWatchdog(for: ctx)
        
        // 2.5 注入安全硬化脚本：禁用 eval 和 Function 构造器，防止沙箱逃逸 (@SR-04)
        let hardeningScript = """
        (function() {
            const forbidden = function() { throw new Error(String(data: Data(base64Encoded: "U2VjdXJpdHkgRXJyb3I6ICdldmFsJyBhbmQgJ0Z1bmN0aW9uJyBhcmUgZGlzYWJsZWQgaW4gWmhpWXUgc2FuZGJveC4=")!, encoding: .utf8)!); };
            try {
                eval = forbidden;
                Function = forbidden;
                Object.freeze(forbidden);
            } catch (e) {
                console.error(String(data: Data(base64Encoded: "RmFpbGVkIHRvIGFwcGx5IHNhbmRib3ggaGFyZGVuaW5nLg==")!, encoding: .utf8)!);
            }
        })();
        """
        ctx.evaluateScript(hardeningScript)
        
        // 3. 加载脚本
        ctx.evaluateScript(self.scriptContent)
        
        // 4. 执行业务逻辑
        return try body(ctx)
    }
    
    /// 装配宿主为 JS 沙箱提供的标准 API 网关
    private func setupAPI(in context: JSContext) {
        guard let pluginCtx = self.pluginContext else { return }
        
        let logBlock: @convention(block) (String) -> Void = { msg in
            DispatchQueue.main.async {
                pluginCtx.log(msg)
            }
        }
        
        let registerCommandBlock: @convention(block) (String, String, String) -> Void = { [weak self] id, name, funcName in
            DispatchQueue.main.async {
                guard let self = self else { return }
                pluginCtx.registerCommand(id: id, name: name) {
                    try? self.executeInContext { ctx in
                        if let jsFunc = ctx.objectForKeyedSubscript(funcName), !jsFunc.isUndefined {
                            jsFunc.call(withArguments: [])
                        }
                    }
                }
            }
        }
        
        let registerRibbonItemBlock: @convention(block) (String, String, String) -> Void = { [weak self] icon, title, funcName in
            DispatchQueue.main.async {
                guard let self = self else { return }
                pluginCtx.registerRibbonItem(icon: icon, title: title) {
                    try? self.executeInContext { ctx in
                        if let jsFunc = ctx.objectForKeyedSubscript(funcName), !jsFunc.isUndefined {
                            jsFunc.call(withArguments: [])
                        }
                    }
                }
            }
        }
        
        let registerSettingTabBlock: @convention(block) (String, String?, String) -> Void = { [weak self] name, schema, funcName in
            DispatchQueue.main.async {
                guard let self = self else { return }
                pluginCtx.registerSettingTab(name: name, schema: schema) { data in
                    try? self.executeInContext { ctx in
                        if let jsFunc = ctx.objectForKeyedSubscript(funcName), !jsFunc.isUndefined {
                            jsFunc.call(withArguments: data != nil ? [data!] : [])
                        }
                    }
                }
            }
        }
        
        let registerViewBlock: @convention(block) (String, String, String, String) -> Void = { [weak self] id, title, icon, funcName in
            DispatchQueue.main.async {
                guard let self = self else { return }
                pluginCtx.registerView(id: id, title: title, icon: icon) {
                    try? self.executeInContext { ctx in
                        if let jsFunc = ctx.objectForKeyedSubscript(funcName), !jsFunc.isUndefined {
                            jsFunc.call(withArguments: [])
                        }
                    }
                }
            }
        }
        
        let addEventListenerBlock: @convention(block) (String, String) -> Void = { [weak self] event, funcName in
            DispatchQueue.main.async {
                guard let self = self else { return }
                pluginCtx.addEventListener(event: event) { data in
                    try? self.executeInContext { ctx in
                        if let jsFunc = ctx.objectForKeyedSubscript(funcName), !jsFunc.isUndefined {
                            jsFunc.call(withArguments: [])
                        }
                    }
                }
            }
        }
        
        let saveDataBlock: @convention(block) (String, String) -> Void = { key, value in
            DispatchQueue.main.async {
                do {
                    try PluginSandboxGateway.auditStorage(key: key, value: value)
                    pluginCtx.saveData(key: key, value: value)
                } catch {
                    pluginCtx.log(" [DLP] saveData: \(error.localizedDescription)")
                }
            }
        }
        
        let loadDataBlock: @convention(block) (String) -> String? = { key in
            var result: String?
            DispatchQueue.main.sync {
                result = pluginCtx.loadData(key: key)
            }
            return result
        }
        
        let fetchBlock: @convention(block) (String, [String: Any]?, String) -> Void = { [weak self] url, options, funcName in
            DispatchQueue.main.async {
                guard let self = self else { return }
                Task {
                    do {
                        let allowed = self.manifest.allowedDomains ?? []
                        let request = try PluginSandboxGateway.auditFetch(url: url, options: options, allowedDomains: allowed)
                        let (data, _) = try await URLSession.shared.data(for: request)
                        let responseString = String(data: data, encoding: .utf8) ?? ""
                        
                        try? self.executeInContext { ctx in
                            JSGarbageCollect(ctx.jsGlobalContextRef)
                            if let jsFunc = ctx.objectForKeyedSubscript(funcName), !jsFunc.isUndefined {
                                jsFunc.call(withArguments: [responseString])
                            }
                        }
                    } catch {
                        pluginCtx.log(" [FetchError] \(error.localizedDescription)")
                    }
                }
            }
        }
        
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
        
        context.setObject(jsContextObj, forKeyedSubscript: "ZhiYu" as NSString)
    }
    
    /// on加载
    /// - Parameter context: context
    func onLoad(context: PluginContext) {
        self.pluginContext = context
        
        // 调用 JS onLoad (使用池化的 JSContext 并设置看门狗)
        try? executeInContext { ctx in
            if let onLoadFunc = ctx.objectForKeyedSubscript("onLoad"), !onLoadFunc.isUndefined {
                let group = JSContextGetGroup(ctx.jsGlobalContextRef)
                JSContextGroupSetExecutionTimeLimit(group, 0.5, { _, _ in return 1 }, nil)
                defer {
                    JSContextGroupSetExecutionTimeLimit(group, 0, nil, nil)
                    JSGarbageCollect(ctx.jsGlobalContextRef)
                }
                onLoadFunc.call(withArguments: [])
            }
        }
    }
    
    /// onUnload
    func onUnload() {
        try? executeInContext { ctx in
            if let onUnloadFunc = ctx.objectForKeyedSubscript("onUnload"), !onUnloadFunc.isUndefined {
                let group = JSContextGetGroup(ctx.jsGlobalContextRef)
                JSContextGroupSetExecutionTimeLimit(group, 0.5, { _, _ in return 0 }, nil)
                defer {
                    JSContextGroupSetExecutionTimeLimit(group, 0, nil, nil)
                    JSGarbageCollect(ctx.jsGlobalContextRef)
                }
                onUnloadFunc.call(withArguments: [])
            }
        }
        self.pluginContext = nil
    }
    
    private let maxResponseSize = 5 * 1024 * 1024 // 5MB 限制
    
    /// pre处理
    /// - Parameter content: content
    /// - Returns: 字符串
    func preProcess(content: String) throws -> String {
        return try executeInContext { ctx in
            if let preProcessFunc = ctx.objectForKeyedSubscript("preProcess"), !preProcessFunc.isUndefined {
                let group = JSContextGetGroup(ctx.jsGlobalContextRef)
                JSContextGroupSetExecutionTimeLimit(group, 0.5, { _, _ in return 1 }, nil)
                
                defer {
                    JSContextGroupSetExecutionTimeLimit(group, 0, nil, nil)
                    JSGarbageCollect(ctx.jsGlobalContextRef)
                }
                
                let result = preProcessFunc.call(withArguments: [content])
                
                if let exception = ctx.exception {
                    ctx.exception = nil
                    throw NSError(
                        domain: "PluginSandbox",
                        code: 408,
                        userInfo: [NSLocalizedDescriptionKey: L10n.Plugin.Error.preProcessException(exception.toString() ?? "unknown")]
                    )
                }
                
                let resultString = result?.toString() ?? content
                if resultString.count > maxResponseSize {
                    throw NSError(domain: "PluginSandbox", code: 413, userInfo: [NSLocalizedDescriptionKey: L10n.Plugin.Error.payloadTooLarge])
                }
                return resultString
            }
            return content
        }
    }
    
    /// post处理
    /// - Parameter content: content
    /// - Returns: 字符串
    func postProcess(content: String) throws -> String {
        return try executeInContext { ctx in
            if let postProcessFunc = ctx.objectForKeyedSubscript("postProcess"), !postProcessFunc.isUndefined {
                let group = JSContextGetGroup(ctx.jsGlobalContextRef)
                JSContextGroupSetExecutionTimeLimit(group, 0.5, { _, _ in return 1 }, nil)
                
                defer {
                    JSContextGroupSetExecutionTimeLimit(group, 0, nil, nil)
                    JSGarbageCollect(ctx.jsGlobalContextRef)
                }
                
                let result = postProcessFunc.call(withArguments: [content])
                
                if let exception = ctx.exception {
                    ctx.exception = nil
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
}

#endif

