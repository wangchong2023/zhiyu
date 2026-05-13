// PasteboardProtocol.swift
//
// 作者: Wang Chong
// 功能说明: 剪贴板抽象协议，定义跨平台文本交换标准。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

/// 剪贴板服务协议
@MainActor
public protocol PasteboardProtocol: Sendable {
    /// 获取或设置剪贴板文本
    var string: String? { get set }
}
