//
//  WatchPasteboardService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：实现 WatchPasteboard 模块的核心业务逻辑服务。
//
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