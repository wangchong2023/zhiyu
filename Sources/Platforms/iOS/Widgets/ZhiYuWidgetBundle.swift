//
//  ZhiYuWidgetBundle.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：属于 Widgets 模块，提供相关的结构体或工具支撑。
//
import SwiftUI
import WidgetKit

@main
struct ZhiYuWidgetBundle: WidgetBundle {
    var body: some Widget {
        // 注册实时活动 Widget
        AIProcessingActivityWidget()
        
        // 注册桌面静态 Widget
        KnowledgeStatsWidget()
    }
}
