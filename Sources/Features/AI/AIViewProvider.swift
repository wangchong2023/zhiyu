//
//  AIViewProvider.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：属于 AI 模块，提供相关的结构体或工具支撑。
//
import SwiftUI

struct AIViewProvider: ViewProvider {
    func makeView(for route: AnyHashable) -> AnyView? {
        guard let route = route as? AppRoute, route.domain == .ai else { return nil }
        
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
