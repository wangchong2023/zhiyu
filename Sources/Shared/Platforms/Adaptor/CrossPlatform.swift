// CrossPlatform.swift
//
// 作者: Wang Chong
// 功能说明: 跨平台剪贴板包装器 (PM 视角：确保 Mac/iPad 核心交互一致性)
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// 跨平台剪贴板包装器 (PM 视角：确保 Mac/iPad 核心交互一致性)
enum AppPasteboard {
    /// 获取或设置系统剪贴板文本
    static var string: String? {
        get {
            #if os(iOS)
            return UIPasteboard.general.string
            #elseif os(macOS)
            return NSPasteboard.general.string(forType: .string)
            #else
            return nil
            #endif
        }
        set {
            #if os(iOS)
            UIPasteboard.general.string = newValue
            #elseif os(macOS)
            NSPasteboard.general.clearContents()
            if let s = newValue {
                NSPasteboard.general.setString(s, forType: .string)
            }
            #endif
        }
    }
}

/// 跨平台图片包装器
#if os(iOS)
typealias AppImage = UIImage
#elseif os(macOS)
typealias AppImage = NSImage
#else
// For watchOS, or others. We might not need AppImage directly or can use an empty struct.
struct AppImage {}
#endif

extension AppImage {
    /// 统一转换为 CGImage 以供 Vision 等框架使用
    var appCGImage: CGImage? {
        #if os(iOS)
        return self.cgImage
        #elseif os(macOS)
        return self.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #else
        return nil
        #endif
    }
}

