// KeyboardShortcutsView.swift
//
// 作者: Wang Chong
// 功能说明: 本文件定义了键盘快捷键的视图修饰符，用于在应用中全局响应键盘操作。
// 日期: 2026-05-07
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

// MARK: - Keyboard Shortcuts View Modifier
/// 键盘快捷键视图修饰符
/// 负责监听系统快捷键通知并触发对应的 UI 操作，如显示新建页面面板
struct KeyboardShortcutsViewModifier: ViewModifier {
    @Environment(AppStore.self) var store
    @State private var showCreateSheet = false

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

// MARK: - SwiftUI Shortcut Mapping
extension AppKeyboardShortcuts {
    /// 将快捷键动作映射到 SwiftUI 的 EventModifiers
    static func modifiers(for action: Action) -> EventModifiers {
        switch action {
        case .newPage, .search, .save, .closeWindow, .openSettings, .undo, .quit:
            return .command
        case .redo:
            return [.command, .shift]
        }
    }
}
