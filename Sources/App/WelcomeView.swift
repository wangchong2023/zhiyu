// WelcomeView.swift
//
// 作者: Wang Chong
// 功能说明: [L3] 应用调度层：知识管理系统的欢迎页面（首页），提供系统概览、统计数据、最近更新及快速入门指南。
// 版本: 1.2
// 修改记录:
//   - 2026-05-16: 规范化治理：使用 DesignSystem 令牌替换硬编码图标，适配重构后的统计属性。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI
import Charts

struct WelcomeView: View {
    @Environment(AppStore.self) var store
    @Binding var selectedTab: AppTab
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showInjectSuccess = false
    @State private var injectedCount = 0
    
    var body: some View {
        @Bindable var store = store
        ScrollView {
            VStack(spacing: Spacing.huge) {
                WelcomeHeroSection()
                WelcomeStatsSection()
                if !store.pages.isEmpty {
                    WelcomeGrowthChartSection(data: store.growthSeries)
                    WelcomeRecentUpdatesSection(selectedTab: $selectedTab)
                } else {
                    WelcomeQuickStartGuideSection(showInjectSuccess: $showInjectSuccess, injectedCount: $injectedCount)
                }
                WelcomeQuickActionsSection(selectedTab: $selectedTab)
            }
            .padding(.bottom, DesignSystem.Layout.welcomeHeaderTopPadding)
        }
        .background(themeManager.pageBackground())
        .alert(L10n.Common.success, isPresented: $showInjectSuccess) {
            Button(L10n.Common.awesome, role: .cancel) { }
        } message: {
            Text(L10n.Settings.InjectDemo.successMessage(injectedCount))
        }
    }
}

// MARK: - 子视图组件

struct WelcomeHeroSection: View {
    var body: some View {
        VStack(spacing: DesignSystem.standardPadding) {
            ZStack {
                AppDotPattern(dotColor: Color.appBorder, spacing: DesignSystem.wide, dotSize: DesignSystem.atomic)
                    .frame(width: DesignSystem.Metrics.welcomeHeroDotWidth, height: DesignSystem.Metrics.welcomeHeroDotHeight)
                    .opacity(DesignSystem.halfOpacity)
                
                Circle().fill(Color.appAccent.opacity(DesignSystem.glassOpacity * 0.8))
                    .frame(width: DesignSystem.Metrics.welcomeHeroCircleSize, height: DesignSystem.Metrics.welcomeHeroCircleSize)
                    .blur(radius: DesignSystem.wide)
                
                Image(systemName: DesignSystem.Icons.knowledge)
                    .font(.system(size: DesignSystem.Metrics.welcomeHeroIconSize))
                    .foregroundStyle(LinearGradient(colors: [.appAccent, .appConcept], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: .appAccent.opacity(DesignSystem.softOpacity), radius: DesignSystem.standardPadding)
            }
            .frame(height: DesignSystem.Metrics.welcomeHeroDotHeight)
            
            Text(L10n.Common.appName)
                .font(.system(size: DesignSystem.huge + DesignSystem.tiny, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appText)
            
            Text(L10n.Onboarding.subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.appSecondary)
        }
        .padding(.top, DesignSystem.Layout.welcomeHeaderTopPadding)
    }
}

struct WelcomeStatsSection: View {
    @Environment(AppStore.self) var store
    private let columns = [GridItem(.adaptive(minimum: DesignSystem.Metrics.statCardMinWidth, maximum: .infinity), spacing: DesignSystem.wide)]
    var body: some View {
        LazyVGrid(columns: columns, spacing: DesignSystem.wide) {
            StatCard(title: L10n.Common.Stat.totalPages, value: "\(store.totalPages)", icon: DesignSystem.Icons.source, color: .appAccent)
            StatCard(title: L10n.Common.Stat.entities, value: "\(store.entityCount)", icon: DesignSystem.Icons.entity, color: .appEntity)
            StatCard(title: L10n.Common.Stat.concepts, value: "\(store.conceptCount)", icon: DesignSystem.Icons.concept, color: .appConcept)
            StatCard(title: L10n.Common.Stat.sources, value: "\(store.sourceCount)", icon: DesignSystem.Icons.source, color: .appSource)
        }
        .padding(.horizontal)
    }
}

struct WelcomeGrowthChartSection: View {
    let data: [AppStore.KnowledgeGrowthPoint]
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            HStack(spacing: DesignSystem.small) {
                Image(systemName: DesignSystem.Icons.chartLine)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appText)
                Text(L10n.Onboarding.growthTrend)
                    .font(.headline)
                    .foregroundStyle(Color.appText)
                Spacer()
            }
            Chart(data) { point in
                LineMark(x: .value("Date", point.date), y: .value("Count", point.count))
                    .foregroundStyle(Color.appAccent)
            }
            .frame(height: DesignSystem.Metrics.boxHeight)
        }
        .padding(DesignSystem.wide)
        .appContainer(background: Color.appCard)
        .padding(.horizontal)
    }
}

struct WelcomeRecentUpdatesSection: View {
    @Environment(AppStore.self) var store
    @Environment(Router.self) var router
    @Binding var selectedTab: AppTab
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            HStack(spacing: DesignSystem.small) {
                Image(systemName: DesignSystem.Icons.history)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appText)
                Text(L10n.Common.recentUpdates)
                    .font(.headline)
                    .foregroundStyle(Color.appText)
                Spacer()
            }.padding(.horizontal)
            ForEach(store.pages.sorted { $0.updatedAt > $1.updatedAt }.prefix(5)) { page in
                Button(action: { router.navigateToPage(id: page.id) }) {
                    PageRowView(page: page, compact: true).padding(.horizontal)
                }.buttonStyle(.plain)
            }
        }
    }
}

struct WelcomeQuickStartGuideSection: View {
    @Environment(AppStore.self) var store
    @Binding var showInjectSuccess: Bool
    @Binding var injectedCount: Int
    
    var body: some View {
        VStack(spacing: DesignSystem.wide) {
            HStack {
                Image(systemName: DesignSystem.Icons.sparkles)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appText)
                Text(L10n.Onboarding.quickStart)
                    .font(.headline)
                    .foregroundStyle(Color.appText)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.medium) {
                GuideStepRow(number: 1, text: L10n.Onboarding.Guide.createPage, icon: DesignSystem.Icons.docBadgePlus)
                GuideStepRow(number: 2, text: L10n.Onboarding.Guide.knowledgeLink, icon: DesignSystem.Icons.link)
            }
            
            // 快捷注入演示数据入口
            Button(action: {
                HapticFeedback.shared.trigger(.selection)
                Task {
                    injectedCount = await store.generateDemoData()
                    HapticFeedback.shared.trigger(.success)
                    showInjectSuccess = true
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                        Text(L10n.Onboarding.Demo.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.appAccent)
                        Text(L10n.Onboarding.Demo.desc)
                            .font(.caption2)
                            .foregroundStyle(Color.appSecondary)
                    }
                    Spacer()
                    Image(systemName: DesignSystem.Icons.forwardCircle)
                        .font(.title3)
                        .foregroundStyle(Color.appAccent)
                }
                .padding()
                .background(Color.appAccent.opacity(DesignSystem.glassOpacity * 0.5))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.cardRadius)
                        .stroke(Color.appAccent.opacity(DesignSystem.glassOpacity), lineWidth: DesignSystem.borderWidth)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(DesignSystem.wide)
        .appContainer(background: Color.appCard)
        .padding(.horizontal)
    }
}

struct WelcomeQuickActionsSection: View {
    @Environment(AppStore.self) var store
    @Binding var selectedTab: AppTab
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            QuickActionRow(icon: DesignSystem.Icons.plusCircle, title: L10n.Action.createPage, subtitle: L10n.Action.createPageSubtitle, color: .appAccent) { store.showCreateSheet = true }
            QuickActionRow(icon: DesignSystem.Icons.importIcon, title: L10n.Action.ingestKnowledge, subtitle: L10n.Action.ingestKnowledgeSubtitle, color: .appSource) { selectedTab = .ingest }
        }.padding(.horizontal)
    }
}
