//
//  MacPasteboardService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：实现 MacPasteboard 模块的核心业务逻辑服务。
//
#if os(macOS)
import AppKit

/// macOS 剪贴板实现
final class MacPasteboardService: PasteboardProtocol {
    var string: String? {
        get { NSPasteboard.general.string(forType: .string) }
        set {
            NSPasteboard.general.clearContents()
            if let s = newValue {
                NSPasteboard.general.setString(s, forType: .string)
            }
        }
    }
}

// MARK: - AppImage 转换扩展
extension NSImage {
    /// 统一转换为 CGImage 以供 Vision 等框架使用
    var appCGImage: CGImage? {
        return self.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
}
#endif