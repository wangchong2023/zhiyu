//
//  SystemViewProvider.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：属于 System 模块，提供相关的结构体或工具支撑。
//
import SwiftUI

struct SystemViewProvider: ViewProvider {

    /// 创建View
    /// - Returns: 可选值
    func makeView(for route: AnyHashable) -> AnyView? {
        guard let route = route as? AppRoute, route.domain == .system else { return nil }
        
        switch route {
        case .settings:
            return AnyView(SettingsViewWrapper())
        case .about:
            return AnyView(AboutView().navigationTitle(L10n.Common.about))
        case .help:
            return AnyView(Text("Help_Coming_Soon").navigationTitle(L10n.Common.help))
        case .collab:
            return AnyView(CollaborationView())
        case .pluginMarket:
            return AnyView(PluginCenterView())
        default:
            return nil
        }
    }
}
