// MacAppEnvironment.swift
//
// 作者: Wang Chong
// 功能说明: AppEnvironmentProtocol 的 macOS 实现。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

#if os(macOS)
import AppKit

/// macOS 环境能力实现 (含 Catalyst)
final class MacAppEnvironment: AppEnvironmentProtocol {
    var screenClass: ScreenClass { return .expansive }
    
    var interactionStyle: InteractionStyle { return .pointer }
    
    var supportsPencil: Bool { return false }
    
    var hasCamera: Bool { return true } // 大多数 Mac 都有摄像头
    
    var isMobile: Bool { return false }
    
    var platformName: String { return "macOS" }
    
    var isCloudSyncSupported: Bool { return false } // macOS Target 暂未配置 entitlements
}
#endif
