//
//  AppEnvironmentProtocol.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：定义 AppEnvironment 模块的抽象契约接口。
//
import Foundation

/// 屏幕布局类别
public enum ScreenClass: Sendable {
    case compact    // iPhone 竖屏, Watch
    case regular    // iPhone 横屏, iPad 拆分视图
    case expansive  // iPad 全屏, macOS
}

/// 交互样式
public enum InteractionStyle: Sendable {
    case touch      // 触控 (iOS)
    case pointer    // 光标/鼠标 (macOS, iPad with Trackpad)
    case crown      // 旋钮 (watchOS)
}

/// 平台环境能力集协议
@MainActor
public protocol AppEnvironmentProtocol: Sendable {
    /// 当前屏幕类别
    var screenClass: ScreenClass { get }
    
    /// 主导交互方式
    var interactionStyle: InteractionStyle { get }
    
    /// 设备名称 (如 "iPhone 15 Pro", "Wang's Mac")
    var deviceName: String { get }
    
    /// 硬件特权：是否支持 Apple Pencil
    var supportsPencil: Bool { get }
    
    /// 硬件特权：是否具备摄像头能力
    var hasCamera: Bool { get }
    
    /// 是否为移动便携设备 (iPhone/Watch)
    var isMobile: Bool { get }
    
    /// 平台显示名称 (用于调试或关于页面)
    var platformName: String { get }
    
    /// 应用程序版本号 (如 "1.0.0 (42)")
    var appVersion: String { get }
    
    /// 硬件特权：是否支持 iCloud 同步 (考虑模拟器限制与 entitlements)
    var isCloudSyncSupported: Bool { get }
}