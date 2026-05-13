// HapticFeedback.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了系统级的触感反馈工具（HapticFeedback），旨在为用户提供标准化、语义化的触感反馈语言。
// 通过封装底层硬件接口，该组件实现了以下核心功能：
// 1. 定义了一套跨平台的触感模式枚举（HapticPattern），支持成功、失败、警告、处理中等多种交互语义。
// 2. 针对 macOS 和 iOS 进行了差异化适配，分别调用 NSHapticFeedbackManager 和 UINotificationFeedbackGenerator 等原生 API。
// 3. 建立了闭环的反馈机制，确保在知识金库加锁、AI 思考、链接建立等核心交互环节提供一致且细腻的震动体验。
// 版本: 1.1
// 修改记录:
//   - 2026-05-05: 迁移至 Utils/System 并重构，完善了符合架构规范的功能说明
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
