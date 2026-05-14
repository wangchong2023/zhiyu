// ServiceContainer.swift
//
// 作者: Wang Chong
// 功能说明: 依赖注入容器 (L2 层：解耦中枢)
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
    
    private init() {}
    
    /// 注册服务
    /// - Parameters:
    ///   - service: 服务实例
    ///   - type: 服务的协议或类类型
    func register<T>(_ service: T, for type: T.Type) {
        let key = "\(type)"
        services[key] = service
    }
    
    /// 重置所有服务（主要用于测试环境隔离）
    func reset() {
        services.removeAll()
    }
    
    /// 解析服务
    /// - Parameter type: 服务的协议或类类型
    /// - Returns: 已注册的服务实例
    func resolve<T>(_ type: T.Type) -> T {
        let key = "\(type)"
        if let service = services[key] as? T {
            return service
        }
        
        // 诊断信息：打印当前已注册的所有 Key
        print("❌ [DI] 服务 \(key) 未注册！")
        print("📍 当前已注册的服务: \(services.keys.joined(separator: ", "))")
        fatalError("❌ [DI] 服务 \(key) 未注册！请在 App 启动时初始化。")
    }

    /// 检查服务是否已注册
    /// - Parameter type: 服务的协议或类类型
    /// - Returns: 是否存在该服务
    func hasService<T>(for type: T.Type) -> Bool {
        let key = String(describing: type)
        return services[key] != nil
    }
}

/// 服务注入助手属性包装器
/// 用于在各层级服务中实现透明的依赖解析
@propertyWrapper
struct Inject<T> {
    var wrappedValue: T {
        ServiceContainer.shared.resolve(T.self)
    }
}
