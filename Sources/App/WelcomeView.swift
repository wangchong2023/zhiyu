// WelcomeView.swift
//
// 作者: Wang Chong
// 功能说明: 知识管理系统的欢迎页面（首页），提供系统概览、统计数据、最近更新及快速入门指南。
// 版本: 1.1 (工业级重构，消除魔鬼数字并适配新 UI 模式)

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
            .padding(.bottom, Spacing.huge + Spacing.small)
        }
        .background(themeManager.pageBackground())
        .alert(L10n.Common.tr("success"), isPresented: $showInjectSuccess) {
            Button(L10n.Common.tr("awesome"), role: .cancel) { }
        } message: {
            Text(Localized.trf("settings.injectDemo.successMessage", injectedCount))
        }
    }
}

// MARK: - Sub-views

struct WelcomeHeroSection: View {
    var body: some View {
        VStack(spacing: Spacing.standardPadding) {
            ZStack {
                AppDotPattern(dotColor: Color.appBorder, spacing: Spacing.wide, dotSize: Spacing.atomic)
                    .frame(width: Spacing.Metrics.heroValueSize * 7.7, height: Spacing.Metrics.heroValueSize * 3.85).opacity(Colors.fullOpacity * 0.5)
                Circle().fill(Color.appAccent.opacity(Colors.glassOpacity * 0.8))
                    .frame(width: Spacing.Metrics.heroValueSize * 5.4, height: Spacing.Metrics.heroValueSize * 5.4)
                    .blur(radius: Spacing.wide)
                Image(systemName: "books.vertical.circle.fill")
                    .font(.system(size: Spacing.Metrics.heroValueSize * 2.76))
                    .foregroundStyle(LinearGradient(colors: [.appAccent, .appConcept], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: .appAccent.opacity(Colors.glassOpacity * 4), radius: Spacing.standardPadding, x: 0, y: Spacing.small)
            }
            .frame(height: Spacing.Metrics.heroValueSize * 3.85)
            Text(Localized.tr("page.knowledge"))
                .font(.system(size: Spacing.huge + Spacing.tiny, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appText)
            Text(Localized.tr("welcome.subtitle"))
                .font(.subheadline)
                .foregroundStyle(Color.appSecondary)
        }
        .padding(.top, Spacing.huge + Spacing.small)
    }
}

struct WelcomeStatsSection: View {
    @Environment(AppStore.self) var store
    private let columns = [GridItem(.adaptive(minimum: Spacing.Metrics.heroValueSize * 6.15, maximum: .infinity), spacing: Spacing.wide)] // 160
    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.wide) {
            StatCard(title: Localized.tr("stat.totalPages"), value: "\(store.totalPages)", icon: "doc.richtext.fill", color: .appAccent)
            StatCard(title: Localized.tr("stat.entities"), value: "\(store.entityCount)", icon: "person.text.rectangle.fill", color: .appEntity)
            StatCard(title: Localized.tr("stat.concepts"), value: "\(store.conceptCount)", icon: "lightbulb.fill", color: .appConcept)
            StatCard(title: Localized.tr("stat.sources"), value: "\(store.sourceCount)", icon: "doc.plaintext.fill", color: .appSource)
        }
        .padding(.horizontal)
    }
}

struct WelcomeGrowthChartSection: View {
    let data: [AppStore.KnowledgeGrowthPoint]
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack(spacing: Spacing.small) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appText)
                Text(Localized.tr("welcome.growthTrend"))
                    .font(.headline)
                    .foregroundStyle(Color.appText)
                Spacer()
            }
            Chart(data) { point in
                LineMark(x: .value("Date", point.date), y: .value("Count", point.count))
                    .foregroundStyle(Color.appAccent)
            }
            .frame(height: Spacing.Metrics.boxHeight)
        }
        .padding(Spacing.wide)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cardRadius))
        .padding(.horizontal)
    }
}

struct WelcomeRecentUpdatesSection: View {
    @Environment(AppStore.self) var store
    @Environment(AppRouter.self) var router
    @Binding var selectedTab: AppTab
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack(spacing: Spacing.small) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appText)
                Text(Localized.tr("recentUpdates"))
                    .font(.headline)
                    .foregroundStyle(Color.appText)
                Spacer()
            }.padding(.horizontal)
            ForEach(Array(store.pages.sorted { $0.updated > $1.updated }.prefix(5))) { page in
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
        VStack(spacing: Spacing.wide) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appText)
                Text(Localized.tr("welcome.quickStart"))
                    .font(.headline)
                    .foregroundStyle(Color.appText)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: Spacing.medium) {
                GuideStepRow(number: 1, text: Localized.tr("welcome.guide.createPage"), icon: "doc.badge.plus")
                GuideStepRow(number: 2, text: Localized.tr("welcome.guide.knowledgeLink"), icon: "link")
            }
            
            // 快捷注入演示数据入口
            Button(action: {
                HapticFeedback.shared.trigger(.selection)
                injectedCount = store.generateDemoData()
                HapticFeedback.shared.trigger(.success)
                showInjectSuccess = true
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.tiny) {
                        Text(Localized.tr("welcome.demo.title"))
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.appAccent)
                        Text(Localized.tr("welcome.demo.desc"))
                            .font(.caption2)
                            .foregroundStyle(Color.appSecondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.appAccent)
                }
                .padding()
                .background(Color.appAccent.opacity(Colors.glassOpacity / 2))
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cardRadius)
                        .stroke(Color.appAccent.opacity(Colors.glassOpacity), lineWidth: Spacing.borderWidth)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(DesignSystem.wide)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardRadius))
        .padding(.horizontal)
    }
}

struct WelcomeQuickActionsSection: View {
    @Environment(AppStore.self) var store
    @Binding var selectedTab: AppTab
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            QuickActionRow(icon: "plus.circle.fill", title: L10n.Action.tr("createPage"), subtitle: L10n.Action.tr("createPage.subtitle"), color: .appAccent) { store.showCreateSheet = true }
            QuickActionRow(icon: "tray.and.arrow.down.fill", title: L10n.Action.tr("ingestKnowledge"), subtitle: L10n.Action.tr("ingestKnowledge.subtitle"), color: .appSource) { selectedTab = .ingest }
        }.padding(.horizontal)
    }
}
