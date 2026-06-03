//
//  AppNotifications.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L0.5] 系统集成层
//  核心职责：属于 Notifications 模块，提供相关的结构体或工具支撑。
//
import Foundation

extension Notification.Name {
    static let searchWithTag = Notification.Name("searchWithTag")
    static let toggleSidebar = Notification.Name("toggleSidebar")
    static let splashDismissed = Notification.Name("splashDismissed")
    static let toggleDisplayMode = Notification.Name("toggleDisplayMode")
    static let importFromClipboard = Notification.Name("importFromClipboard")
    static let languageChanged = Notification.Name("languageChanged")
    static let vaultWillSwitch = Notification.Name("vaultWillSwitch")
}
