// GraphEmptyStateView.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：知识图谱空状态占位视图。
// 版本: 1.0
// 修改记录:
//   - 2026-05-18: 从 GraphView 剥离，实现组件化。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 知识图谱空状态占位视图
@MainActor
struct GraphEmptyStateView: View {
    @Environment(AppStore.self) var store
    @Binding var selectedTab: AppTab
    
    var body: some View {
        VStack(spacing: DesignSystem.loosePadding) {
            Image(systemName: DesignSystem.Icons.circleGrid3x3Fill)
                .font(.system(size: DesignSystem.Graph.emptyIconSize))
                .foregroundStyle(.appAccent.gradient)
            
            VStack(spacing: DesignSystem.tightPadding) {
                Text(L10n.Graph.emptyTitle).font(.title2.bold())
                Text(L10n.Graph.emptyDesc)
                    .font(.subheadline)
                    .foregroundStyle(.appSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.loosePadding * 1.5)
            }
            
            Button(action: { store.showCreateSheet = true }) {
                Text(L10n.Graph.startBuilding)
                    .font(.headline)
                    .padding(.horizontal, DesignSystem.loosePadding + DesignSystem.small)
                    .padding(.vertical, DesignSystem.standardPadding - DesignSystem.atomic)
                    .background(Capsule().fill(Color.appAccent))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
    }
}
