//
//  iOSAppEnvironment.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 应用层
//  核心职责：属于 Environment 模块，提供相关的结构体或工具支撑。
//
#if os(iOS)
import UIKit
import SwiftUI

/// iOS/iPadOS 环境能力实现
final class iOSAppEnvironment: AppEnvironmentProtocol {
    
    // 我们利用 SwiftUI 的 UserInterfaceSizeClass 进行辅助，但在注入层我们主要基于设备类型
    var screenClass: ScreenClass {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .expansive
        }
        return .compact
    }
    
    var interactionStyle: InteractionStyle {
        // 虽然 iPad 支持指针，但主导仍为触控
        return .touch
    }
    
    var deviceName: String {
        UIDevice.current.name
    }
    
    var supportsPencil: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    var hasCamera: Bool {
        // 简单判断，实际可深入使用 AVFoundation
        return true 
    }
    
    var isMobile: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    var platformName: String {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return "iPadOS"
        }
        return "iOS"
    }
    
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    var isCloudSyncSupported: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }
}
#endif
