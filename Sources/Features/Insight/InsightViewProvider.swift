// InsightViewProvider.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：Insight 领域的视图提供者。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

struct InsightViewProvider: ViewProvider {
    func makeView(for route: AppRoute) -> AnyView? {
        guard route.domain == .insight else { return nil }
        
        switch route {
        case .dashboard:
            return AnyView(KnowledgeDashboardView())
        case .log:
            return AnyView(LogView())
        case .lint:
            return AnyView(LintWrapper())
        case .medalWall:
            return AnyView(Text("Medal Wall")) // 假设实现
        default:
            return nil
        }
    }
}
