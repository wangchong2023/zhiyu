// WatchAppEnvironment.swift
//
// 作者: Wang Chong
// 功能说明: [L3] 应用调度层：AppEnvironmentProtocol 的 watchOS 实现。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

#if os(watchOS)
import WatchKit

/// watchOS 环境能力实现
final class WatchAppEnvironment: AppEnvironmentProtocol {
    var screenClass: ScreenClass { return .compact }
    
    var interactionStyle: InteractionStyle { return .crown }
    
    var supportsPencil: Bool { return false }
    
    var hasCamera: Bool { return false }
    
    var isMobile: Bool { return true }
    
    var platformName: String { return "watchOS" }
    
    var deviceName: String {
        return WKInterfaceDevice.current().name
    }
    
    var isCloudSyncSupported: Bool { return false }
}
#endif
