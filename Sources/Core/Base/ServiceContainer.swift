//
//  ServiceContainer.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：属于 Base 模块，提供相关的结构体或工具支撑。
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
        print("DI: Registered [\(key)] with instance \(String(describing: service))")
        #endif
    }
    
    /// 重置所有服务（主要用于测试环境隔离）
    func reset() {
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
        let errorMessage = String(data: Data(base64Encoded: "IERJIEVycm9yOiBTZXJ2aWNlIFs=")!, encoding: .utf8)! + key + String(data: Data(base64Encoded: "XSBub3QgcmVnaXN0ZXJlZC4gRXhwZWN0ZWQgdHlwZTog")!, encoding: .utf8)! + String(describing: type) + String(data: Data(base64Encoded: "LiBDdXJyZW50IGtleXM6IA==")!, encoding: .utf8)! + registeredKeys.joined(separator: ", ")
        
        #if DEBUG
        print(errorMessage)
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

