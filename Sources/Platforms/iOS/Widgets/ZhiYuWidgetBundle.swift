// ZhiYuWidgetBundle.swift
//
// 作者: Wang Chong
// 功能说明: Widget 扩展主入口。
//           集成并导出所有支持的 Widget 类型，包括桌面小组件与实时活动 (Live Activity)。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI
import WidgetKit

@main
struct ZhiYuWidgetBundle: WidgetBundle {
    var body: some Widget {
        // 注册实时活动 Widget
        AIProcessingActivityWidget()
        
        // 后续可在此处添加桌面静态 Widget (如: KnowledgeStatsWidget)
    }
}
