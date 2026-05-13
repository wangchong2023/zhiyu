// MacPasteboardService.swift
//
// 作者: Wang Chong
// 功能说明: PasteboardProtocol 的 macOS 实现。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
