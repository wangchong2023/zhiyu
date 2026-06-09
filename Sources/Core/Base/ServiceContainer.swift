//
//  ServiceContainer.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：业务逻辑服务，封装 Container 的核心算法与数据操作。
//

import Foundation
import os

/// 依赖注入容器 (L2 层：解耦中枢)
/// 遵循 Service Locator 模式，支持 Mock 替换 (@SR-04: 受权限管控的插件访问基础)
final class ServiceContainer: @unchecked Sendable {
    /// 全局单例
    static let shared = ServiceContainer()
    
    /// 服务注册表
    private var services: [String: Any] = [:]
    
    /// 并发保护锁 (os_unfair_lock)，比 NSLock 更轻量且具备极佳的高并发性能
    private let lockPointer: UnsafeMutablePointer<os_unfair_lock>
    
    private init() {
        lockPointer = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        lockPointer.initialize(to: os_unfair_lock())
    }
    
    deinit {
        lockPointer.deallocate()
    }
    
    /// 注册服务
    /// - Parameters:
    ///   - service: 服务实例
    ///   - type: 服务的协议或类类型
    func register<T>(_ service: T, for type: T.Type) {
        let key = makeKey(for: type)
        os_unfair_lock_lock(lockPointer)
        services[key] = service
        os_unfair_lock_unlock(lockPointer)
        #if DEBUG
        Logger.shared.debug("DI: Registered [\(key)] with instance \(String(describing: service))")
        #endif
    }
    
    /// 标记是否由生产注册链（AppEnvironment）完成初始化，防止测试误清
    private var isProductionChainPopulated = false

    /// 标记生产链已完成，禁止 reset() 清空
    func markProductionChainComplete() {
        isProductionChainPopulated = true
    }

    /// 重置所有服务（主要用于测试环境隔离）
    /// 生产注册链完成后调用此方法无效果，防止测试误清导致 @Inject 崩溃
    func reset() {
        guard !isProductionChainPopulated else {
            Logger.shared.warning("[ServiceContainer] reset() blocked: production DI chain is complete. Use register() to override specific services in tests.")
            return
        }
        os_unfair_lock_lock(lockPointer)
        services.removeAll()
        os_unfair_lock_unlock(lockPointer)
    }
    
    /// 解析服务
    func resolve<T>(_ type: T.Type) -> T {
        let key = makeKey(for: type)
        
        // 单次加锁：同时读取实例和诊断信息，消除两次加锁间的竞态窗口
        os_unfair_lock_lock(lockPointer)
        let instance = services[key]
        let registeredKeys = Array(services.keys)
        os_unfair_lock_unlock(lockPointer)
        
        if let service = instance as? T {
            return service
        }
        
        // 服务未注册：输出诊断信息
        let errorMessage = " DI Error: Service [" + key + "] not registered. Expected type: " + String(describing: type) + ". Current keys: " + registeredKeys.joined(separator: ", ")
        
        #if DEBUG
        Logger.shared.error(errorMessage)
        #endif
        
        // 使用断言而非 fatalError，在开发环境下更容易追踪
        assertionFailure(errorMessage)
        
        // 兜底返回（仅在非调试模式下运行到此）
        fatalError(errorMessage)
    }
    
    /// 尝试解析服务，如果未注册则返回 nil，不会触发断言或崩溃
    func resolveOptional<T>(_ type: T.Type) -> T? {
        let key = makeKey(for: type)
        os_unfair_lock_lock(lockPointer)
        let instance = services[key]
        os_unfair_lock_unlock(lockPointer)
        return instance as? T
    }
    
    /// 生成类型唯一的 Key，移除 existential type 和模块名前缀的干扰
    private func makeKey<T>(for type: T.Type) -> String {
        var typeString = "\(type)"
        
        // 1. 移除 "any " 或 "all " 前缀
        if typeString.hasPrefix("any ") {
            typeString.removeFirst(4)
        } else if typeString.hasPrefix("all ") {
            typeString.removeFirst(4)
        }
        
        // 2. 移除模块名前缀 (例如 "ZhiYu.LoggerProtocol" -> "LoggerProtocol")
        if !typeString.contains("<") {
            if let lastDot = typeString.lastIndex(of: ".") {
                typeString = String(typeString[typeString.index(after: lastDot)...])
            }
        }
        
        // 3. 移除 Swift 内部修饰符 (例如 "(unknown context at $109403...)")
        if let bracketIndex = typeString.firstIndex(of: " ") {
            typeString = String(typeString[..<bracketIndex])
        }
        
        return typeString
    }

    /// 检查服务是否已注册
    func hasService<T>(for type: T.Type) -> Bool {
        let key = makeKey(for: type)
        os_unfair_lock_lock(lockPointer)
        let exists = services[key] != nil
        os_unfair_lock_unlock(lockPointer)
        return exists
    }

    /// 安全解析服务，未注册时返回 nil（不 fatalError）
    func optionalResolve<T>(_ type: T.Type) -> T? {
        let key = makeKey(for: type)
        os_unfair_lock_lock(lockPointer)
        let service = services[key]
        os_unfair_lock_unlock(lockPointer)
        return service as? T
    }
}

/// 服务注入助手属性包装器
@propertyWrapper
struct Inject<T>: @unchecked Sendable {
    var wrappedValue: T {
        ServiceContainer.shared.resolve(T.self)
    }
}

