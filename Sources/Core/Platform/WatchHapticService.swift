// WatchHapticService.swift
//
// 作者: Wang Chong
// 功能说明: HapticFeedbackProtocol 的 watchOS 原生实现。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

#if os(watchOS)
import WatchKit

/// watchOS 触感反馈实现：使用 WKInterfaceDevice.current().play()
final class WatchHapticService: HapticFeedbackProtocol {
    func trigger(_ pattern: HapticPattern) {
        let device = WKInterfaceDevice.current()
        switch pattern {
        case .success:
            device.play(.success)
        case .error:
            device.play(.failure)
        case .warning:
            device.play(.retry)
        case .lock:
            device.play(.click)
        case .unlock:
            device.play(.start)
        case .processing, .pulse:
            device.play(.directionDown)
        case .link:
            device.play(.directionUp)
        case .selection:
            device.play(.click)
        }
    }
}
#endif
