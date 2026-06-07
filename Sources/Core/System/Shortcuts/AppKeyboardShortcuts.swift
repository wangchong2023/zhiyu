//
//  AppKeyboardShortcuts.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0.5] 系统集成层
//  核心职责：键盘快捷键定义，提供 Mac Catalyst 菜单命令绑定。
//
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
