// iOSPasteboardService.swift
//
// 作者: Wang Chong
// 功能说明: PasteboardProtocol 的 iOS 实现。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

#if os(iOS)
import UIKit

/// iOS 剪贴板实现
final class iOSPasteboardService: PasteboardProtocol {
    var string: String? {
        get { UIPasteboard.general.string }
        set { UIPasteboard.general.string = newValue }
    }
}

// MARK: - AppImage 转换扩展
extension UIImage {
    /// 统一转换为 CGImage 以供 Vision 等框架使用
    var appCGImage: CGImage? {
        return self.cgImage
    }
}
#endif
