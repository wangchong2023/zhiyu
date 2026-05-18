// MedalWallView.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：奖章墙视图：展示用户已获得和待挑战的成就
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-03
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

// MARK: - 勋章墙
/// 奖章墙视图
/// 负责展示用户的知识成就体系、勋章获得情况及成长里程碑进度
struct MedalWallView: View {
    @Environment(AppStore.self) var store
    @StateObject private var medalService = MedalService.shared
    
    let columns = [
        GridItem(.flexible(), spacing: DesignSystem.standardPadding),
        GridItem(.flexible(), spacing: DesignSystem.standardPadding)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.loosePadding) {
                // 顶部统计
                HStack(spacing: DesignSystem.widePadding) {
                    statBox(title: L10n.Insight.Medal.totalEarned, value: "\(medalService.earnedMedalIDs.count)", icon: "trophy.fill", color: .orange)
                    statBox(title: L10n.Insight.Medal.progress, value: "\(Int(Double(medalService.earnedMedalIDs.count) / 7.0 * 100))%", icon: "chart.bar.fill", color: .blue)
                }
                .padding(.horizontal, DesignSystem.standardPadding)
                
                // 分类展示
                medalSection(title: L10n.Insight.Medal.Category.explore, category: .explore)
                medalSection(title: L10n.Insight.Medal.Category.accumulation, category: .accumulation)
                medalSection(title: L10n.Insight.Medal.Category.connection, category: .connection)
                
                Spacer(minLength: DesignSystem.huge)
            }
            .padding(.vertical, DesignSystem.standardPadding)
        }
        .background(PageBackgroundView(accentColor: .appAccent))
        .navigationTitle(L10n.Insight.Medal.Wall.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
    
    private func medalSection(title: String, category: MedalService.Medal.Category) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.standardPadding) {
            Text(title)
                .font(.title3.bold())
                .padding(.horizontal, DesignSystem.standardPadding)
            
            LazyVGrid(columns: columns, spacing: DesignSystem.standardPadding) {
                ForEach(getMedals(for: category)) { medal in
                    MedalCard(medal: medal, isEarned: medalService.earnedMedalIDs.contains(medal.id))
                }
            }
            .padding(.horizontal, DesignSystem.standardPadding)
        }
    }
    
    private func getMedals(for category: MedalService.Medal.Category) -> [MedalService.Medal] {
        medalService.allMedals.filter { $0.category == category }
    }
    
    private func statBox(title: String, value: String, icon: String, color: Color) -> some View {
        let shadowRadius = DesignSystem.microRadius + DesignSystem.atomic
        let shadowY = DesignSystem.borderWidth * 2
        let shadowOpacity = DesignSystem.shadowOpacity / 2
        
        return VStack(alignment: .leading, spacing: DesignSystem.tightPadding) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
            }
            Text(value)
                .font(.system(size: DesignSystem.titleFontSize, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.standardPadding)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
        .shadow(color: .black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: shadowY)
    }
}
