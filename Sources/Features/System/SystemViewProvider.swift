// SystemViewProvider.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：System 领域的视图提供者。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

struct SystemViewProvider: ViewProvider {
    func makeView(for route: AnyHashable) -> AnyView? {
        guard let route = route as? AppRoute, route.domain == .system else { return nil }
        
        switch route {
        case .settings:
            return AnyView(SettingsViewWrapper())
        case .about:
            return AnyView(AboutView().navigationTitle(L10n.Common.about))
        case .help:
            return AnyView(Text("Help Coming Soon").navigationTitle(L10n.Common.help))
        case .collab:
            return AnyView(CollaborationView())
        case .pluginMarket:
            return AnyView(PluginCenterView())
        default:
            return nil
        }
    }
}
