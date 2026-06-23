//
//  URLOpenerProtocol.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/20.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：定义 URL 打开的跨平台协议，屏蔽 UIApplication.shared.open / NSWorkspace.shared.open 的 API 差异。

import Foundation

/// URL 打开器协议
@MainActor
public protocol URLOpenerProtocol: Sendable {
    /// 异步打开指定 URL
    func open(_ url: URL) async
}
