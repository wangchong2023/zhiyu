// WeeklyInsightCard.swift
//
// 作者: Wang Chong
// 功能说明: 知识周报卡片 (PM 视角：价值闭环)
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
//   - 更新: 2026-05-03
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 知识周报卡片 (PM 视角：价值闭环)
/// 知识周报卡片容器
/// 集成 AI 摘要与核心增长指标的可视化面板
struct WeeklyInsightCard: View {
    @Environment(AppStore.self) var store
    @Environment(AIWorkflowStore.self) var aiStore
    @Environment(AppRouter.self) var router
    @State private var isGenerating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppUI.loosePadding) {
            HStack {
                AppGlow(icon: "sparkles", color: .purple, size: AppUI.largeIconSize - AppUI.tiny) // 28
                VStack(alignment: .leading, spacing: AppUI.atomic) {
                    Text(L10n.Dashboard.tr("insight.weeklyTitle"))
                        .font(.title3.bold())
                        .foregroundStyle(.appText)
                    if let insight = aiStore.weeklyInsight {
                        Text(insight.dateRange)
                            .font(.caption)
                            .foregroundStyle(.appSecondary)
                    }
                }
                Spacer()
                
                if isGenerating {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Button(action: { generateInsight(forceRefresh: true) }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption.bold())
                            .foregroundStyle(.appSecondary)
                            .padding(AppUI.small)
                            .background(Circle().fill(Color.appBorder.opacity(AppUI.glassOpacity * 2))) // 0.2
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if isGenerating {
                VStack(alignment: .leading, spacing: 12) {
                    SkeletonBox(width: 200, height: 20)
                    SkeletonBox(width: 300, height: 16)
                    SkeletonBox(width: 260, height: 16)
                    SkeletonBox(width: 280, height: 16)
                }
            } else if let insight = aiStore.weeklyInsight {
                VStack(alignment: .leading, spacing: AppUI.standardPadding + AppUI.small) { // 24
                    // 核心指标 (奖牌化设计)
                    VStack(alignment: .leading, spacing: AppUI.standardPadding) {
                        HStack(spacing: AppUI.standardPadding + AppUI.small) { // 24
                            InsightStat(label: Localized.tr("stat.newPages"), value: "\(insight.totalNewPages)", icon: "doc.badge.plus", color: .blue)
                            Divider().frame(height: AppUI.Action.buttonHeight * 0.9) // 36
                            InsightStat(label: Localized.tr("stat.growth"), value: insight.growthTraction, icon: "chart.line.uptrend.xyaxis", color: .green)
                        }
                        
                        if !insight.topKeywords.isEmpty {
                            FlowLayout(spacing: AppUI.small) {
                                ForEach(Array(Set(insight.topKeywords)).sorted(), id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.system(size: AppUI.microFontSize + 1))
                                        .padding(.horizontal, AppUI.small + AppUI.atomic) // 10
                                        .padding(.vertical, AppUI.tiny + AppUI.atomic) // 6
                                        .background(Color.appAccent.opacity(AppUI.glassOpacity))
                                        .foregroundStyle(.appAccent)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding(AppUI.loosePadding) // 添加内边距，解决内容过于拥挤的问题
                    .background(AppUI.containerBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppUI.standardRadius + AppUI.small)) // 16
                    .overlay(
                        RoundedRectangle(cornerRadius: AppUI.standardRadius + AppUI.small)
                            .stroke(AppUI.containerBorder, lineWidth: AppUI.borderWidth)
                    )

                    // 摘要正文
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "quote.opening")
                                .font(.title2)
                                .foregroundStyle(.appAccent.opacity(0.3))
                            Spacer()
                        }
                        
                        MarkdownRendererView(content: insight.aiSummary, isPrivate: false, onLinkTap: { title in
                            if let page = store.pages.first(where: { $0.title == title }) {
                                router.navigateToPage(id: page.id)
                            }
                        })
                        .padding(.horizontal, 4)
                        
                        HStack {
                            Spacer()
                            Image(systemName: "quote.closing")
                                .font(.title2)
                                .foregroundStyle(.appAccent.opacity(AppUI.disabledOpacity))
                        }
                    }
                    .padding(AppUI.loosePadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: AppUI.standardRadius + AppUI.small)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppUI.standardRadius + AppUI.small)
                                    .stroke(LinearGradient(colors: [AppUI.containerBorder, .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: AppUI.borderWidth)
                            )
                    }
                    .shadow(color: .black.opacity(AppUI.shadowOpacity * 1.25), radius: AppUI.shadowRadius, y: AppUI.shadowY) // 0.05, 10, 4
                }
                .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
            } else {
                Button(action: { generateInsight(forceRefresh: true) }) {
                    HStack {
                        VStack(alignment: .leading, spacing: AppUI.tiny) {
                            Text(L10n.Dashboard.tr("insight.generateReport"))
                                .font(.headline)
                            Text(Localized.tr("weekly.aiAnalysis"))
                                .font(.caption)
                        }
                        Spacer()
                        Image(systemName: "sparkles")
                            .font(.title2)
                    }
                    .padding(AppUI.standardPadding + AppUI.small) // 24
                    .background(
                        RoundedRectangle(cornerRadius: AppUI.standardRadius + AppUI.small)
                            .fill(LinearGradient(colors: [.appAccent.opacity(AppUI.glassOpacity * 1.5), .appAccent.opacity(AppUI.glassOpacity / 2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .overlay(RoundedRectangle(cornerRadius: AppUI.standardRadius + AppUI.small).stroke(AppUI.containerBorder, lineWidth: AppUI.borderWidth))
                    )
                    .foregroundStyle(.appAccent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppUI.standardPadding + AppUI.small) // 24
        .background(
            ZStack {
                AppUI.containerBackground
                LinearGradient(colors: [.purple.opacity(AppUI.glassOpacity / 2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: AppUI.loosePadding)) // 20
        .shadow(color: .black.opacity(AppUI.shadowOpacity * 1.25), radius: AppUI.shadowRadius * 1.5, x: 0, y: AppUI.shadowY * 2) // 0.05, 15, 8
        .onAppear {
            if aiStore.weeklyInsight == nil && !store.pages.isEmpty {
                generateInsight()
            }
        }
    }
    
    /**
     * @description: 触发周报生成任务，通过 AIWorkflowStore 调度分析逻辑
     * @param {Bool} forceRefresh 是否强制重新生成，忽略缓存
     * @return {*}
     */
    private func generateInsight(forceRefresh: Bool = false) {
        withAnimation { isGenerating = true }
        Task {
            await aiStore.generateWeeklyInsight(forceRefresh: forceRefresh)
            await MainActor.run {
                withAnimation { isGenerating = false }
            }
        }
    }
}

/// 周报指标项小组件
struct InsightStat: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppUI.medium) {
            Image(systemName: icon)
                .font(.system(size: AppUI.largeIconSize * 0.625, weight: .semibold)) // 20
                .foregroundStyle(color)
                .frame(width: AppUI.Metrics.iconBoxSize + 4, height: AppUI.Metrics.iconBoxSize + 4) // 44
                .background(
                    Circle()
                        .fill(color.opacity(AppUI.glassOpacity * 1.5))
                        .overlay(Circle().stroke(color.opacity(AppUI.disabledOpacity), lineWidth: AppUI.borderWidth))
                )
            
            VStack(alignment: .leading, spacing: AppUI.tiny) {
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.appText)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
            }
        }
    }
}

/// 知识周报详情全屏视图
struct WeeklyReportView: View {
    @Environment(AppStore.self) var store
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                WeeklyInsightCard()
                
                // 深度建议
                VStack(alignment: .leading, spacing: AppUI.standardPadding) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.orange)
                        Text(L10n.Dashboard.tr("insight.tips.title"))
                            .font(.headline)
                    }
                    
                    Text(L10n.Dashboard.tr("insight.tips.content"))
                        .font(.subheadline)
                        .lineSpacing(AppUI.tiny + AppUI.atomic) // 5
                        .foregroundStyle(.appSecondary)
                        .padding(AppUI.loosePadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppUI.containerBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppUI.standardRadius + AppUI.small)) // 16
                        .overlay(
                            RoundedRectangle(cornerRadius: AppUI.standardRadius + AppUI.small)
                                .stroke(AppUI.containerBorder, lineWidth: AppUI.borderWidth)
                        )
                }
                .padding(.top, AppUI.medium - AppUI.atomic) // 10
                
                // 底部占位，增加留白感
                Spacer(minLength: AppUI.largeIconSize + AppUI.small) // 40
            }
            .padding(AppUI.loosePadding)
        }
        .background(Color.appBackground)
        .navigationTitle(Localized.tr("sidebar.weeklyInsight"))
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}
