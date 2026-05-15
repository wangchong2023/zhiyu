// MacHapticService.swift
//
// 作者: Wang Chong
// 功能说明: [L0.5] 系统集成层：HapticFeedbackProtocol 的 macOS 原生实现。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

#if os(macOS)
import AppKit

/// macOS 触感反馈实现：使用 NSHapticFeedbackManager
final class MacHapticService: HapticFeedbackProtocol {
    func trigger(_ pattern: HapticPattern) {
        let performer = NSHapticFeedbackManager.defaultPerformer
        switch pattern {
        case .success, .unlock:
            performer.perform(.alignment, performanceTime: .now)
        case .error, .warning, .lock:
            performer.perform(.levelChange, performanceTime: .now)
        case .processing, .link, .selection, .pulse:
            performer.perform(.generic, performanceTime: .now)
        }
    }
}
#endif
