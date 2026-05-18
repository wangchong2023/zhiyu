// GraphFilterPillsView.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：知识图谱类型过滤器药丸视图。
// 版本: 1.0
// 修改记录:
//   - 2026-05-18: 从 GraphView 剥离，实现组件化。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
