// AppKeyboardShortcuts.swift
//
// 作者: Wang Chong
// 功能说明: [L0.5] 系统集成层：Centralized keyboard shortcuts configuration for App
// 版本: 1.1
// 修改记录:
//   - 创建: 2026-05-02
//   - 更新: 2026-05-07: 移除 SwiftUI 依赖，将视图修饰符移至 KeyboardShortcutsView.swift
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

// MARK: - Keyboard Shortcuts Manager
/// Centralized keyboard shortcuts configuration for App
/// Supports Mac Catalyst with proper modifier flags
enum AppKeyboardShortcuts {
    // MARK: - Shortcut Actions
    enum Action {
        case newPage
        case search
        case undo
        case redo
        case save
        case closeWindow
        case openSettings
        case quit
    }

    /// Get keyboard shortcut key for action
    static func shortcutKey(for action: Action) -> String? {
        switch action {
        case .newPage: return "n"
        case .search: return "f"
        case .undo: return "z"
        case .redo: return "Z"
        case .save: return "s"
        case .closeWindow: return "w"
        case .openSettings: return ","
        case .quit: return "q"
        }
    }
}

// MARK: - Notification Names for Keyboard Shortcuts
extension Notification.Name {
    static let createNewPage = Notification.Name("AppCreateNewPage")
    static let performSave = Notification.Name("AppPerformSave")
    static let focusSearch = Notification.Name("AppFocusSearch")
    static let performUndo = Notification.Name("AppPerformUndo")
    static let performRedo = Notification.Name("AppPerformRedo")
    static let closeWindow = Notification.Name("AppCloseWindow")
    static let openSettings = Notification.Name("AppOpenSettings")
    static let quitApp = Notification.Name("AppQuitApp")
}
