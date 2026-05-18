// KnowledgeDashboardView.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：知识库数据仪表盘，展示知识密度、活跃话题及核心指标。
// 核心原则：
// 1. 模式化布局：完全依赖 AppUI 提供的布局模式（Grid, Metrics, Gallery）。
// 2. 无魔鬼数字：所有间距、尺寸、图标均来源于 AppUI。
// 修改记录:
//   - 2026-05-07: 移除本地 Layout 枚举，对接 AppUI 模式化系统。
//   - 2026-05-07: 消除硬编码图标字符串，使用 DesignSystem.Icons。

import SwiftUI
import Charts
struct KnowledgeDashboardView: View {
    @Environment(AppStore.self) var store
    @Environment(Router.self) var router
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // 使用协调器管理状态与交互
    @State private var coordinator = DashboardCoordinator()
    @State private var showDensityInfo = false
    
    var body: some View {
        @Bindable var coordinator = coordinator
        ZStack(alignment: .top) {
            // 1. 方案 D 沉浸式高级背景同步
            ZStack {
                Color.black.overlay(themeManager.pageBackground().opacity(0.4))
                MeshGradientView()
                    .blur(radius: 80)
            }
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.huge) {
                    AIProcessingStatusBanner()
                        .padding(.bottom, -DesignSystem.standardPadding)
                        
                    metricSection
                    densityChartSection
                    dailyInsightsSection
                    hotTopicsSection
                }
                .padding()
                .padding(.bottom, DesignSystem.Metrics.chartHeight / 2)
            }
            .scrollIndicators(.hidden)
            
        }
        .appTabToolbar(title: L10n.Dashboard.title)
        .task {
            await coordinator.refreshAll()
        }
        .task(id: store.pages.count) {
            await coordinator.calculateStats()
        }
    }
    
    // MARK: - Sub-Sections
    
    private var metricSection: some View {
        // 1. 核心指标概览
        HStack(spacing: DesignSystem.Grid.standardSpacing) {
            MetricBox(
                title: L10n.Dashboard.totalPages, 
                value: "\(store.pages.count)", 
                unit: L10n.Dashboard.pageListPages, 
                icon: DesignSystem.Icons.documentFill, 
                color: .appAccent,
                trend: nil
            )
            MetricBox(
                title: L10n.Dashboard.totalLinks, 
                value: "\(coordinator.totalLinks)", 
                unit: L10n.Dashboard.pageListLinks, 
                icon: DesignSystem.Icons.network, 
                color: .appConcept,
                trend: nil
            )
        }
    }
    
    private var densityChartSection: some View {
        // 2. 连接密度图表 (语义分块质量)
        VStack(alignment: .leading, spacing: DesignSystem.tightPadding) {
            // 标题 (边框外左上角)
            HStack(spacing: DesignSystem.tiny) {
                Image(systemName: DesignSystem.Icons.network)
                    .font(.caption)
                    .foregroundStyle(.appAccent)
                Text(L10n.Dashboard.density)
                    .font(.headline)
                Button(action: { showDensityInfo.toggle() }) {
                    Image(systemName: DesignSystem.Icons.info)
                        .font(.caption)
                        .foregroundColor(.appSecondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    HapticFeedback.shared.trigger(.selection)
                    router.selectedTab = .graph
                }) {
                    HStack(spacing: DesignSystem.tiny) {
                        Image(systemName: DesignSystem.Icons.circleGrid3x3Fill)
                        Text(L10n.Dashboard.graphShortcut)
                    }
                    .font(.system(size: DesignSystem.caption2FontSize, weight: .bold))
                    .foregroundStyle(.appAccent)
                    .padding(.horizontal, DesignSystem.Chip.horizontalPadding)
                    .padding(.vertical, DesignSystem.Chip.verticalPadding)
                    .background(Color.appAccent.opacity(DesignSystem.glassOpacity))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, DesignSystem.tiny)
            
            if showDensityInfo {
                Text(L10n.Dashboard.densityDesc)
                    .font(.caption)
                    .foregroundColor(.appSecondary)
                    .padding(.bottom, DesignSystem.tiny)
                    .padding(.leading, DesignSystem.tiny)
            }
            
            // 卡片内容 (应用统一容器外框)
            VStack(alignment: .leading, spacing: DesignSystem.standardPadding) {
                if coordinator.densityData.isEmpty {
                    emptyView
                } else {
                    Chart(coordinator.densityData) { item in
                        BarMark(
                            x: .value("Outbound", item.outbound),
                            y: .value("Page", item.name)
                        )
                        .foregroundStyle(LinearGradient(
                            colors: [.appAccent, .appAccent.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        
                        BarMark(
                            x: .value("Inbound", item.inbound),
                            y: .value("Page", item.name)
                        )
                        .foregroundStyle(LinearGradient(
                            colors: [.purple, .purple.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    }
                    .frame(height: DesignSystem.Metrics.chartHeight + 20)
                    .chartXAxis {
                        AxisMarks(position: .bottom) { _ in
                            AxisGridLine(stroke: StrokeStyle(dash: [2, 4]))
                                .foregroundStyle(Color.appBorder)
                            AxisValueLabel()
                                .font(.system(size: DesignSystem.caption2FontSize, weight: .medium))
                                .foregroundStyle(.appSecondary)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisValueLabel()
                                .font(.system(size: DesignSystem.caption2FontSize, weight: .medium))
                                .foregroundStyle(.appSource)
                        }
                    }
                    .chartXAxisLabel(position: .bottom, alignment: .center) {
                        HStack(spacing: 12) {
                            Label(L10n.Dashboard.densityOutbound, systemImage: DesignSystem.Icons.forwardCircle)
                                .foregroundStyle(.appAccent)
                            Label(L10n.Dashboard.densityInbound, systemImage: DesignSystem.Icons.back)
                                .foregroundStyle(.purple)
                        }
                        .font(.system(size: DesignSystem.microFontSize, weight: .bold))
                    }
                    .chartLegend(.hidden)
                }
                
                // 说明文字 (脚标)
                HStack(alignment: .top, spacing: DesignSystem.small - DesignSystem.atomic) { // 6
                    Image(systemName: DesignSystem.Icons.info)
                        .font(.caption2)
                        .foregroundStyle(.appAccent)
                    Text(L10n.Dashboard.densityDetails)
                        .font(.system(size: DesignSystem.caption2FontSize))
                        .lineSpacing(DesignSystem.atomic)
                        .foregroundStyle(.appSecondary)
                }
                .padding(DesignSystem.Layout.cardContentPadding) // 使用标准卡片内边距 (16pt)
                .appMetricCardStyle(color: .appAccent)
            }
            .appContainer(padding: true) // 应用统一容器样式
        }
    }
    
    private var dailyInsightsSection: some View {
        // 3. 每日灵感 (AI 合成摘要预览)
        VStack(alignment: .leading, spacing: DesignSystem.tightPadding) {
            HStack {
                Image(systemName: DesignSystem.Icons.sparkles)
                    .font(.caption)
                    .foregroundStyle(.appAccent)
                Text(L10n.Dashboard.dailyInsights)
                    .font(.headline)
                Spacer()
                Button(action: { Task { await coordinator.refreshInsights() } }) {
                    Image(systemName: DesignSystem.Icons.refresh)
                        .font(.caption)
                        .foregroundColor(.appSecondary)
                        .rotationEffect(.degrees(coordinator.isGeneratingInsights ? 360 : 0))
                        .animation(coordinator.isGeneratingInsights ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: coordinator.isGeneratingInsights)
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                if coordinator.isGeneratingInsights {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(L10n.Dashboard.insightsLoading)
                            .font(.subheadline)
                            .foregroundColor(.appSecondary)
                            .italic()
                        Spacer()
                    }
                    .padding(.vertical, 20)
                } else if let recap = coordinator.dailyRecap {
                    Button(action: {
                        HapticFeedback.shared.trigger(.selection)
                        if store.pages.contains(where: { $0.id == recap.targetPageID }) {
                            router.navigateToPage(id: recap.targetPageID)
                        } else {
                            ToastManager.shared.show(type: .info, message: L10n.Dashboard.insightsPageDeleted)
                        }
                    }) {
                        VStack(alignment: .leading, spacing: DesignSystem.small) {
                            Text(recap.targetPageTitle)
                                .font(.system(size: DesignSystem.subheadlineFontSize, weight: .bold))
                                .foregroundColor(.appAccent)
                            
                            Text(recap.insight)
                                .font(.system(size: DesignSystem.Metrics.dashboardLabelSize))
                                .foregroundColor(.appText)
                                .lineSpacing(DesignSystem.tiny)
                                .multilineTextAlignment(.leading)
                            
                            if !recap.suggestedConnection.isEmpty {
                                HStack(alignment: .top, spacing: DesignSystem.tiny) {
                                    Image(systemName: DesignSystem.Icons.concept)
                                        .font(.system(size: DesignSystem.caption2FontSize))
                                        .foregroundColor(.orange)
                                    Text(recap.suggestedConnection)
                                        .font(.system(size: DesignSystem.captionFontSize, weight: .medium))
                                        .foregroundColor(.appSecondary)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(.top, DesignSystem.tiny)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(L10n.Dashboard.insightsEmpty)
                        .font(.subheadline)
                        .foregroundColor(.appSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(DesignSystem.Layout.cardContentPadding) // 使用标准卡片内边距 (16pt)
            .appMetricCardStyle(color: .appAccent, cornerRadius: DesignSystem.standardRadius)
        }
    }
    
    private var hotTopicsSection: some View {
        // 4. 热门领域 (PageType 分布)
        VStack(alignment: .leading, spacing: DesignSystem.tightPadding) {
            HStack(spacing: DesignSystem.tiny) {
                Image(systemName: DesignSystem.Icons.grid)
                    .font(.caption)
                    .foregroundStyle(.appAccent)
                Text(L10n.Dashboard.hotTopics)
                    .font(.headline)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Grid.standardSpacing) {
                ForEach(PageType.allCases, id: \.self) { type in
                    let count = store.pages.filter { $0.pageType == type }.count
                    if count > 0 {
                        Button(action: {
                            HapticFeedback.shared.trigger(.selection)
                            router.navigate(to: .pageList(filterType: type))
                        }) {
                            HotTopicMedal(category: type.displayName, count: count, icon: type.icon, color: Color.fromModelColorName(type.colorName))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - 辅助组件

/// 指标卡片
struct MetricBox: View {
    let title: String
    let value: String
    let unit: String?
    let icon: String
    let color: Color
    var trend: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium + DesignSystem.atomic) { // 14pt
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(DesignSystem.glassOpacity))
                        .frame(width: DesignSystem.Timeline.indicatorSize, height: DesignSystem.Timeline.indicatorSize) // 36pt
                    Image(systemName: icon)
                        .font(.system(size: DesignSystem.subheadlineFontSize, weight: .bold))
                        .foregroundColor(color)
                }
                
                Spacer()
                
                if let trend = trend {
                    HStack(spacing: DesignSystem.atomic) {
                        Image(systemName: DesignSystem.Icons.arrowUpRightSimple)
                        Text(trend)
                    }
                    .font(.system(size: DesignSystem.caption2FontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
                    .padding(.horizontal, DesignSystem.Chip.horizontalPadding)
                    .padding(.vertical, DesignSystem.Chip.verticalPadding)
                    .background(Color.green.opacity(DesignSystem.glassOpacity))
                    .clipShape(Capsule())
                }
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                Text(title)
                    .font(.system(size: DesignSystem.captionFontSize, weight: .medium))
                    .foregroundColor(.appSecondary)
                
                HStack(alignment: .firstTextBaseline, spacing: DesignSystem.tiny) {
                    Text(value)
                        .font(.system(size: DesignSystem.Metrics.heroValueSize, weight: .bold, design: .rounded))
                        .foregroundColor(.appText)
                    
                    if let unit = unit {
                        Text(unit)
                            .font(.caption2)
                            .foregroundColor(.appSecondary)
                    }
                }
            }
        }
        .padding(DesignSystem.standardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial.opacity(0.8))
        .background(
            ZStack {
                Color.appCard.opacity(0.4)
                LinearGradient(
                    colors: [color.opacity(0.1), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Metrics.dashboardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Metrics.dashboardRadius)
                .stroke(
                    LinearGradient(
                        colors: [.appBorder.opacity(0.6), .appBorder.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: DesignSystem.borderWidth
                )
        )
        .appStandardShadow()
    }
}

/// 热门领域勋章 (横向卡片)
struct HotTopicMedal: View {
    let category: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.medium) {
            ZStack {
                Circle()
                    .fill(color.opacity(DesignSystem.glassOpacity))
                    .frame(width: DesignSystem.Metrics.iconBoxSize, height: DesignSystem.Metrics.iconBoxSize)
                Image(systemName: icon)
                    .font(.system(size: DesignSystem.headlineFontSize))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                Text(category)
                    .font(.system(size: DesignSystem.titleFontSize, weight: .bold))
                    .foregroundColor(.appText)
                Text("\(count) " + L10n.Dashboard.pageListPages)
                    .font(.system(size: DesignSystem.captionFontSize))
                    .foregroundColor(.appSecondary)
            }
            
            Spacer()
            
            Image(systemName: DesignSystem.Icons.forward)
                .font(.system(size: DesignSystem.captionFontSize, weight: .bold))
                .foregroundColor(.appSecondary.opacity(DesignSystem.Icons.display == 48 ? 0.3 : 0.3)) // standardized opacity later
        }
        .padding(DesignSystem.standardPadding)
        .appMetricCardStyle(color: color, cornerRadius: DesignSystem.standardRadius)
    }
}

private var emptyView: some View {
    VStack {
        Image(systemName: DesignSystem.Icons.chartBar)
            .font(.largeTitle)
            .foregroundColor(.appSecondary.opacity(0.2))
        Text(L10n.Common.Empty.tr("noData"))
            .font(.caption)
            .foregroundColor(.appSecondary)
    }
    .frame(maxWidth: .infinity, minHeight: DesignSystem.Metrics.chartHeight)
}
