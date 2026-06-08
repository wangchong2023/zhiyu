//
//  iOSPasteboardService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：实现 iOSPasteboard 模块的核心业务逻辑服务。
//
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