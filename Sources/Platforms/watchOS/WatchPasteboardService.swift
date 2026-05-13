// WatchPasteboardService.swift
//
// 作者: Wang Chong
// 功能说明: PasteboardProtocol 的 watchOS 实现 (存根)。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

#if os(watchOS)
import Foundation

/// watchOS 剪贴板实现 (手表暂不支持全局剪贴板)
final class WatchPasteboardService: PasteboardProtocol {
    var string: String? {
        get { nil }
        set { }
    }
}
#endif
