//
//  AccessibilityServiceProtocol.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0] 底层基座层
//  核心职责：定义 AccessibilityService 跨平台 VoiceOver 系统语音宣告抽象契约接口。
//

import Foundation

/// 跨平台 VoiceOver 语音宣告及辅助功能服务协议
@MainActor
public protocol AccessibilityServiceProtocol: Sendable {
    /// 向 VoiceOver 系统发送语音公告，提示视障用户当前的即时状态变化。
    ///
    /// - Parameter text: 需要宣告的中文公告文本。
    func postAnnouncement(_ text: String)
}
