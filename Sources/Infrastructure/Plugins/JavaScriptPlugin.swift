#if canImport(JavaScriptCore)
// JavaScriptPlugin.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基于 JavaScriptCore 的沙箱插件实现
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import JavaScriptCore

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
        context.exceptionHandler = { _, exception in
            Logger.shared.error("🔥 [JSPlugin: \(manifest.id)] Exception: \(exception?.toString() ?? "unknown")", error: nil)
        }
        
        // 加载脚本
        context.evaluateScript(script)
    }
    
    func onLoad(context: PluginContext) {
        self.pluginContext = context
        
        // 注入 API 到 JS
        let jsContextObj: [String: Any] = [
            "log": unsafeBitCast({ (msg: String) in
                context.log(msg)
            } as @convention(block) (String) -> Void, to: AnyObject.self),
            
            "registerCommand": unsafeBitCast({ (id: String, name: String, funcName: String) in
                // 在主线程执行 UI 注册
                Task { @MainActor in
                    context.registerCommand(id: id, name: name) {
                        // 回调 JS 函数
                        if let jsFunc = self.context.objectForKeyedSubscript(funcName), !jsFunc.isUndefined {
                            jsFunc.call(withArguments: [])
                        }
                    }
                }
            } as @convention(block) (String, String, String) -> Void, to: AnyObject.self),
            
            "registerRibbonItem": unsafeBitCast({ (icon: String, title: String, funcName: String) in
                Task { @MainActor in
                    context.registerRibbonItem(icon: icon, title: title) {
                        if let jsFunc = self.context.objectForKeyedSubscript(funcName), !jsFunc.isUndefined {
                            jsFunc.call(withArguments: [])
                        }
                    }
                }
            } as @convention(block) (String, String, String) -> Void, to: AnyObject.self),
            
            "registerSettingTab": unsafeBitCast({ (name: String, schema: String?, funcName: String) in
                Task { @MainActor in
                    context.registerSettingTab(name: name, schema: schema) { data in
                        if let jsFunc = self.context.objectForKeyedSubscript(funcName), !jsFunc.isUndefined {
                            jsFunc.call(withArguments: data != nil ? [data!] : [])
                        }
                    }
                }
            } as @convention(block) (String, String?, String) -> Void, to: AnyObject.self),
            
            "registerView": unsafeBitCast({ (id: String, title: String, icon: String, funcName: String) in
                Task { @MainActor in
                    context.registerView(id: id, title: title, icon: icon) {
                        if let jsFunc = self.context.objectForKeyedSubscript(funcName), !jsFunc.isUndefined {
                            jsFunc.call(withArguments: [])
                        }
                    }
                }
            } as @convention(block) (String, String, String, String) -> Void, to: AnyObject.self),
            
            "addEventListener": unsafeBitCast({ (event: String, funcName: String) in
                Task { @MainActor in
                    context.addEventListener(event: event) { data in
                        if let jsFunc = self.context.objectForKeyedSubscript(funcName), !jsFunc.isUndefined {
                            // 暂时不传递复杂 data 对象，仅作为信号通知
                            jsFunc.call(withArguments: [])
                        }
                    }
                }
            } as @convention(block) (String, String) -> Void, to: AnyObject.self),
            
            "saveData": unsafeBitCast({ (key: String, value: String) in
                Task { @MainActor in
                    context.saveData(key: key, value: value)
                }
            } as @convention(block) (String, String) -> Void, to: AnyObject.self),
            
            "loadData": unsafeBitCast({ (key: String) -> String? in
                return context.loadData(key: key)
            } as @convention(block) (String) -> String?, to: AnyObject.self),
            
            "fetch": unsafeBitCast({ (url: String, options: [String: Any]?, funcName: String) in
                Task { @MainActor in
                    // DLP 安全审计：检查域名白名单
                    guard let requestURL = URL(string: url), let host = requestURL.host else {
                        context.log("❌ [DLP拦截] 无效的请求地址: \(url)")
                        return
                    }
                    
                    let allowed = self.manifest.allowedDomains ?? []
                    if !allowed.contains(where: { host.contains($0) }) {
                        context.log("🛡️ [DLP拦截] 插件未被授权访问域名: \(host)。请在 manifest 中声明 allowedDomains。")
                        return
                    }
                    
                    var request = URLRequest(url: requestURL)
                    
                    // 解析 options
                    if let opts = options {
                        request.httpMethod = (opts["method"] as? String)?.uppercased() ?? "GET"
                        if let headers = opts["headers"] as? [String: String] {
                            for (key, val) in headers {
                                request.setValue(val, forHTTPHeaderField: key)
                            }
                        }
                        if let body = opts["body"] as? String {
                            request.httpBody = body.data(using: .utf8)
                        }
                    }
                    
                    // 执行安全的网络请求
                    do {
                        let (data, _) = try await URLSession.shared.data(for: request)
                        let responseString = String(data: data, encoding: .utf8) ?? ""
                        
                        if let jsFunc = self.context.objectForKeyedSubscript(funcName), !jsFunc.isUndefined {
                            jsFunc.call(withArguments: [responseString])
                        }
                    } catch {
                        context.log("❌ [FetchError] \(error.localizedDescription)")
                    }
                }
            } as @convention(block) (String, [String: Any]?, String) -> Void, to: AnyObject.self)
        ]
        
        self.context.setObject(jsContextObj, forKeyedSubscript: "ZhiYu" as NSString)
        
        // 调用 JS onLoad
        if let onLoadFunc = self.context.objectForKeyedSubscript("onLoad"), !onLoadFunc.isUndefined {
            onLoadFunc.call(withArguments: [])
        }
    }
    
    func onUnload() {
        if let onUnloadFunc = self.context.objectForKeyedSubscript("onUnload"), !onUnloadFunc.isUndefined {
            onUnloadFunc.call(withArguments: [])
        }
        self.pluginContext = nil
    }
    
    private let maxResponseSize = 5 * 1024 * 1024 // 5MB 限制
    
    func preProcess(content: String) throws -> String {
        if let preProcessFunc = self.context.objectForKeyedSubscript("preProcess"), !preProcessFunc.isUndefined {
            let result = preProcessFunc.call(withArguments: [content])
            let resultString = result?.toString() ?? content
            
            // Watchdog 2.0: 内存大小检查
            if resultString.count > maxResponseSize {
                throw NSError(domain: "PluginSandbox", code: 413, userInfo: [NSLocalizedDescriptionKey: "插件返回数据过大 (Payload Too Large)"])
            }
            return resultString
        }
        return content
    }
    
    func postProcess(content: String) throws -> String {
        if let postProcessFunc = self.context.objectForKeyedSubscript("postProcess"), !postProcessFunc.isUndefined {
            let result = postProcessFunc.call(withArguments: [content])
            return result?.toString() ?? content
        }
        return content
    }
}

#endif
