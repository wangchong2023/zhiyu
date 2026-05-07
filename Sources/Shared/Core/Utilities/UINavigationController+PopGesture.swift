// UINavigationController+PopGesture.swift
//
// 作者: Wang Chong
// 功能说明: 扩展 UINavigationController 以支持在使用自定义返回按钮时保留侧滑返回手势。
// 版本: 1.0
// 日期: 2026-05-06
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import UIKit

// MARK: - 全局手势支持
/// 解决 SwiftUI 中隐藏标准返回按钮导致侧滑返回失灵的问题
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        // 将手势代理设为自身，以便在任何情况下都能拦截手势判断
        interactivePopGestureRecognizer?.delegate = self
    }

    /// 判断是否应该开始侧滑手势
    /// - Parameter gestureRecognizer: 手势识别器
    /// - Returns: 当视图控制器栈深度大于 1 时允许返回
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
    
    /// 允许与其他手势识别器同时存在
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
