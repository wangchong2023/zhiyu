// AppPasteboard.swift
//
// 作者: Wang Chong
// 功能说明: 跨平台剪贴板包装器 (Facade 模式：作为具体平台实现的统一入口)
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 跨平台剪贴板包装器
@MainActor
enum AppPasteboard {
    /// 获取或设置系统剪贴板文本
    static var string: String? {
        get { service.string }
        set { 
            var s = service
            s.string = newValue 
        }
    }
    
    /// 内部持有的具体实现
    private static var service: any PasteboardProtocol {
        ServiceContainer.shared.resolve((any PasteboardProtocol).self)
    }
}

/// 跨平台图片类型别名
#if os(iOS)
import UIKit
public typealias AppImage = UIImage
#elseif os(macOS)
import AppKit
public typealias AppImage = NSImage
#else
public struct AppImage: Sendable {}
#endif
