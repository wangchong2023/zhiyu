// iOSHapticService.swift
//
// 作者: Wang Chong
// 功能说明: HapticFeedbackProtocol 的 iOS/iPadOS 原生实现。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

#if os(iOS)
import UIKit

/// iOS 触感反馈实现：使用 UINotificationFeedbackGenerator 和 UIImpactFeedbackGenerator
final class iOSHapticService: HapticFeedbackProtocol {
    func trigger(_ pattern: HapticPattern) {
        #if targetEnvironment(simulator)
        return
        #endif
        
        switch pattern {
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .lock:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .unlock:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .processing, .link, .selection, .pulse:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
#endif
