//
//  GraphFilterPillsView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：构建 GraphFilterPills 界面的 UI 视图层组件。
//
import SwiftUI

/// 知识图谱类型过滤器药丸视图
@MainActor
struct GraphFilterPillsView: View {
    @Binding var filterType: PageType?
    @ObservedObject var tooltipManager: TooltipManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.small) {
                FilterPill(title: L10n.Search.all, isSelected: filterType == nil) { filterType = nil }
                ForEach(PageType.allCases) { type in
                    FilterPill(title: type.displayName, icon: type.icon, color: Color.fromModelColorName(type.colorName), isSelected: filterType == type) { filterType = type }
                }
            }
            .padding(.vertical, DesignSystem.tiny)
        }
    }
}
