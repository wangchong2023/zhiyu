//
//  PencilManager.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：iOS 平台实现：后台任务、Widget、文件归档、Spotlight 索引。
//
import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Apple Pencil 交互管理器 (Expert Design Item #3)
/// 支持双击切换工具（如在图谱中切换“全库”与“聚类”模式）。
@MainActor
final class PencilManager: NSObject {
    static let shared = PencilManager()
    
    private override init() {
        super.init()
        #if os(iOS)
        setupPencilInteraction()
        #endif
    }
    
    #if os(iOS)
    private var interaction: UIPencilInteraction?
    var onDoubleTap: (() -> Void)?
    
    private func setupPencilInteraction() {
        // 由于需要绑定到具体的 UIView，通常在 UIViewController 或 RootView 中注册
        // 这里提供一个全局可调用的逻辑闭包
    }
    #endif
    
#if os(iOS)

    /// 注册
    func register(to view: UIView) {
        let interaction = UIPencilInteraction()
        interaction.delegate = self
        view.addInteraction(interaction)
    }
#endif
}

#if os(iOS)
extension PencilManager: UIPencilInteractionDelegate {

    /// pencilInteractionDidTap
    /// - Parameter interaction: interaction
    func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        // 响应双击
        Logger.shared.debug("ApplePencil")
        onDoubleTap?()
    }
}
#endif
