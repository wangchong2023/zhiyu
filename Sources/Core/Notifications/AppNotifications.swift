// AppNotifications.swift
//
// 作者: Wang Chong
// 功能说明: App Notifications.swift
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-03
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

extension Notification.Name {
    static let searchWithTag = Notification.Name("searchWithTag")
    static let toggleSidebar = Notification.Name("toggleSidebar")
    static let splashDismissed = Notification.Name("splashDismissed")
    static let toggleDisplayMode = Notification.Name("toggleDisplayMode")
    static let importFromClipboard = Notification.Name("importFromClipboard")
}
