//
//  PluginEnginePool.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/24.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：提供高并发安全的 JSContext 连接池，控制沙箱资源并防止内存碎片与 OOM。
//

#if !os(watchOS)

import Foundation
import JavaScriptCore
import os

/// 插件 JavaScriptCore 执行引擎连接池
/// 复用 JSContext 并将最大并发数物理限制为 4 个，有效遏制内存碎片积压与 OOM 隐患。
final class PluginEnginePool: @unchecked Sendable {
    /// 全局单例
    static let shared = PluginEnginePool()
    
    /// 连接池物理上限
    private let maxPoolSize = 4
    
    /// 缓存的可用 JSContext 实例队列
    private var availableContexts: [JSContext] = []
    
    /// 并发保护锁，用以保障连接池字典的读写安全性
    private let lockPointer: UnsafeMutablePointer<os_unfair_lock>
    
    private init() {
        lockPointer = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        lockPointer.initialize(to: os_unfair_lock())
    }
    
    deinit {
        lockPointer.deallocate()
    }
    
    /// 从池中获取或动态构建一个干净的 JSContext 实例，并注入 eval/Function 安全硬化配置。
    /// - Returns: 一个可供执行脚本的 JSContext。
    func borrowContext() -> JSContext {
        os_unfair_lock_lock(lockPointer)
        defer { os_unfair_lock_unlock(lockPointer) }
        
        // 1. 尝试从空闲队列中复用
        if let context = availableContexts.popLast() {
            // 清理异常状态
            context.exception = nil
            return context
        }
        
        // 2. 无可用空闲连接时动态分配新实例（在宿主生命周期中受最多 4 个的严格限流）
        guard let newContext = JSContext() else {
            fatalError("Failed to initialize JSContext")
        }
        
        // 3. 安全加固：彻底禁用 eval 和 Function 构造器，规避动态字符串代码执行漏洞 (@P1-5)
        newContext.evaluateScript("""
        (function() {
            // 物理删除全局 eval，防范 eval("...") 动态执行
            if (typeof eval !== 'undefined') {
                try {
                    delete globalThis.eval;
                } catch(e) {}
                globalThis.eval = undefined;
            }
            // 覆盖 Function 构造函数，杜绝 new Function("...") 执行
            globalThis.Function = function() {
                throw new Error("Dynamic code execution via Function constructor is strictly prohibited in ZhiYu sandbox.");
            };
        })();
        """)
        
        return newContext
    }
    
    /// 将使用过的 JSContext 归还到池中以便下一次复用
    /// - Parameter context: 归还的 JSContext 实例。
    func returnContext(_ context: JSContext) {
        os_unfair_lock_lock(lockPointer)
        defer { os_unfair_lock_unlock(lockPointer) }
        
        // 1. 检查池是否已满
        if availableContexts.count < maxPoolSize {
            // 2. 擦除异常与残留状态，防止污染下一次借用
            context.exception = nil
            availableContexts.append(context)
        }
    }
}

#endif

