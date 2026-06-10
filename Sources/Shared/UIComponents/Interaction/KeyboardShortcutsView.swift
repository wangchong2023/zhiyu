//
//  KeyboardShortcutsView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 共享标准层
//  核心职责：构建 KeyboardShortcuts 界面的 UI 视图层组件。
//
import SwiftUI

extension Notification.Name {
    static let createNewPage = Notification.Name("AppCreateNewPage")
}

// MARK: - Keyboard Shortcuts View Modifier
/// 键盘快捷键视图修饰符
/// 负责监听系统快捷键通知并触发对应的 UI 操作，如显示新建页面面板
struct KeyboardShortcutsViewModifier: ViewModifier {
    @Environment(AppStore.self) var store
    @State private var showCreateSheet = false

    /// 视图主体
    /// - Parameter content: content
    /// - Returns: 返回值
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showCreateSheet) {
                CreatePageView()
            }
            .onReceive(NotificationCenter.default.publisher(for: .createNewPage)) { _ in
                showCreateSheet = true
            }
    }
}

extension View {
    /// 为视图注入键盘快捷键支持
    func withKeyboardShortcuts() -> some View {
        modifier(KeyboardShortcutsViewModifier())
    }
}
