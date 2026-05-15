// AIViewProvider.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：AI 领域的视图提供者。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

struct AIViewProvider: ViewProvider {
    func makeView(for route: AppRoute) -> AnyView? {
        guard route.domain == .ai else { return nil }
        
        switch route {
        case .chat:
            return AnyView(ChatViewContent(selectedTab: .constant(.knowledge)))
        case .synthesis:
            return AnyView(SynthesisViewWrapper())
        case .taskCenter:
            return AnyView(TaskCenterView())
        case .weeklyReport:
            return AnyView(WeeklyReportView())
        case .quiz:
            // Quiz 目前可能通过辅助视图或独立的 Route 呈现
            return AnyView(Text("Quiz View")) 
        default:
            return nil
        }
    }
}
