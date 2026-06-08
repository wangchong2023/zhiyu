//
//  InsightViewProvider.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：SwiftUI 视图，负责 InsightProvider 界面的布局与渲染。
//
import SwiftUI

struct InsightViewProvider: ViewProvider {

    /// 创建View
    /// - Returns: 可选值
    func makeView(for route: AnyHashable) -> AnyView? {
        guard let route = route as? AppRoute, route.domain == .insight else { return nil }
        
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