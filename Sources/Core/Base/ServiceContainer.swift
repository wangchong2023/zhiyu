// ServiceContainer.swift
//
// 作者: Wang Chong
// 功能说明: [L0] 底层基座层：依赖注入容器 (L2 层：解耦中枢)
// 版本: 1.1
// 修改记录:
//   - 2026-05-02: 初始版本。
//   - 2026-05-10: 标准化代码注释与文件头。
// 版权: © 2026 Wang Chong。保留所有权利。

import Foundation

/// 依赖注入容器 (L2 层：解耦中枢)
/// 遵循 Service Locator 模式，支持 Mock 替换 (@SR-04: 受权限管控的插件访问基础)
final class ServiceContainer: @unchecked Sendable {
    /// 全局单例
    static let shared = ServiceContainer()
    
    /// 服务注册表
    private var services: [String: Any] = [:]
    
    /// 并发保护锁
    private let lock = NSLock()
    
    private init() {}
    
    /// 注册服务
    /// - Parameters:
    ///   - service: 服务实例
    ///   - type: 服务的协议或类类型
    func register<T>(_ service: T, for type: T.Type) {
        let key = makeKey(for: type)
        lock.lock()
        services[key] = service
        lock.unlock()
        #if DEBUG
        print("DI: Registered [\(key)] with instance \(String(describing: service))")
        #endif
    }
    
    /// 重置所有服务（主要用于测试环境隔离）
    func reset() {
        lock.lock()
        services.removeAll()
        lock.unlock()
    }
    
    /// 解析服务
    func resolve<T>(_ type: T.Type) -> T {
        let key = makeKey(for: type)
        
        lock.lock()
        let instance = services[key]
        lock.unlock()
        
        if let service = instance as? T {
            return service
        }
        
        // 详细诊断输出
        let registeredKeys = lock.withLock { Array(services.keys) }
        let errorMessage = "❌ DI Error: Service [\(key)] not registered. Expected type: \(type). Current keys: \(registeredKeys.joined(separator: ", "))"
        
        #if DEBUG
        print(errorMessage)
        #endif
        
        // 使用断言而非 fatalError，在开发环境下更容易追踪
        assertionFailure(errorMessage)
        
        // 兜底返回（仅在非调试模式下运行到此）
        fatalError(errorMessage)
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
        // 注意：简单移除点可能会破坏带泛型的类型，这里只处理简单的协议/类名
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
        lock.lock()
        let exists = services[key] != nil
        lock.unlock()
        return exists
    }
}

extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}

/// 服务注入助手属性包装器
@propertyWrapper
struct Inject<T> {
    var wrappedValue: T {
        ServiceContainer.shared.resolve(T.self)
    }
}
