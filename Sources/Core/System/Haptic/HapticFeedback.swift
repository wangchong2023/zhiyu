//
//  HapticFeedback.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0.5] 系统集成层
//  核心职责：属于 Haptic 模块，提供相关的结构体或工具支撑。
//
import Foundation

/// 系统级触感管理器 (Facade 模式：作为具体平台实现的统一入口)
@MainActor
final class HapticFeedback: HapticFeedbackProtocol {
    static let shared = HapticFeedback()
    
    @Inject private var service: any HapticFeedbackProtocol
    
    private init() {}
    
    /// 触发指定模式的触感反馈
    func trigger(_ pattern: HapticPattern) {
        service.trigger(pattern)
    }
}
