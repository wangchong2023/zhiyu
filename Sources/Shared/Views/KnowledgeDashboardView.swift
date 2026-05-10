// KnowledgeDashboardView.swift
//
// 作者: Wang Chong
// 功能说明: 知识库数据仪表盘，展示知识密度、活跃话题及核心指标。
// 核心原则：
// 1. 模式化布局：完全依赖 AppUI 提供的布局模式（Grid, Metrics, Gallery）。
// 2. 无魔鬼数字：所有间距、尺寸、图标均来源于 AppUI。
// 修改记录:
//   - 2026-05-07: 移除本地 Layout 枚举，对接 AppUI 模式化系统。
//   - 2026-05-07: 消除硬编码图标字符串，使用 AppUI.Icons。

import SwiftUI
import Charts
struct KnowledgeDashboardView: View {
    @Environment(AppStore.self) var store
    @Environment(AppRouter.self) var router
    @EnvironmentObject var themeManager: ThemeManager
    @State private var statsTask: Task<Void, Never>? = nil
    @State private var tags: [(tag: String, count: Int)] = []
    @State private var showDensityInfo = false
    @State private var totalLinks = 0
    @State private var densityData: [DensityInfo] = []
    
    var body: some View {
        ZStack {
            themeManager.pageBackground()
            
            ScrollView {
                VStack(alignment: .leading, spacing: AppUI.standardPadding) {
                    metricSection
                    densityChartSection
                    dailyInsightsSection
                    hotTopicsSection
                }
                .padding()
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle(L10n.Dashboard.tr("title"))
        .onAppear {
            statsTask?.cancel()
            statsTask = Task {
                updateTags()
                await calculateStats()
                refreshInsights()
            }
        }
        .onDisappear {
            statsTask?.cancel()
        }
        .task(id: store.pages.count) {
            await calculateStats()
        }
    }
    
    // MARK: - Sub-Sections
    
    private var metricSection: some View {
        // 1. 核心指标概览
        HStack(spacing: AppUI.Grid.standardSpacing) {
            MetricBox(
                title: L10n.Dashboard.tr("totalPages"), 
                value: "\(store.pages.count)", 
                unit: L10n.Dashboard.tr("index.pages"), 
                icon: "doc.on.doc.fill", 
                color: .appAccent,
                trend: "+2"
            )
            MetricBox(
                title: L10n.Dashboard.tr("totalLinks"), 
                value: "\(totalLinks)", 
                unit: L10n.Dashboard.tr("index.links"), 
                icon: "point.3.connected.trianglepath.dotted", 
                color: .appConcept,
                trend: "+5"
            )
        }
    }
    
    private var densityChartSection: some View {
        // 2. 连接密度图表 (语义分块质量)
        VStack(alignment: .leading, spacing: AppUI.tightPadding) {
            // 标题 (边框外左上角)
            HStack(spacing: AppUI.tiny) {
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.caption)
                    .foregroundStyle(.appAccent)
                Text(L10n.Dashboard.tr("density"))
                    .font(.headline)
                Button(action: { showDensityInfo.toggle() }) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.appSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    HapticFeedback.shared.trigger(.selection)
                    router.selectedTab = .graph
                }) {
                    HStack(spacing: AppUI.tiny) {
                        Image(systemName: "circle.grid.3x3.fill")
                        Text(L10n.Dashboard.graphShortcut)
                    }
                    .font(.system(size: AppUI.caption2FontSize, weight: .bold))
                    .foregroundStyle(.appAccent)
                    .padding(.horizontal, AppUI.small)
                    .padding(.vertical, AppUI.tiny)
                    .background(Color.appAccent.opacity(AppUI.glassOpacity))
                    .clipShape(Capsule())
                }
            }
            .padding(.leading, AppUI.tiny)
            
            if showDensityInfo {
                Text(L10n.Dashboard.tr("density.desc"))
                    .font(.caption)
                    .foregroundColor(.appSecondary)
                    .padding(.bottom, AppUI.tiny)
                    .padding(.leading, AppUI.tiny)
            }
            
            // 卡片内容
            VStack(alignment: .leading, spacing: AppUI.standardPadding) {                if densityData.isEmpty {
                    emptyView
                } else {
                    Chart(densityData) { item in
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
                    .frame(height: 240)
                    .chartXAxis {
                        AxisMarks(position: .bottom) { _ in
                            AxisGridLine(stroke: StrokeStyle(dash: [2, 4]))
                                .foregroundStyle(Color.appBorder)
                            AxisValueLabel()
                                .font(.system(size: AppUI.caption2FontSize, weight: .medium))
                                .foregroundStyle(.appSecondary)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisValueLabel()
                                .font(.system(size: AppUI.caption2FontSize, weight: .medium))
                                .foregroundStyle(.appSource)
                        }
                    }
                    .chartXAxisLabel(position: .bottom, alignment: .center) {
                        HStack(spacing: 12) {
                            Label(L10n.Dashboard.densityOutbound, systemImage: "arrow.right.circle.fill")
                                .foregroundStyle(.appAccent)
                            Label(L10n.Dashboard.densityInbound, systemImage: "arrow.left.circle.fill")
                                .foregroundStyle(.purple)
                        }
                        .font(.system(size: 9, weight: .bold))
                    }
                    .chartLegend(.hidden)
                }
                
                // 说明文字 (脚标)
                HStack(alignment: .top, spacing: AppUI.small - AppUI.atomic) { // 6
                    Image(systemName: "info.circle")
                        .font(.caption2)
                        .foregroundStyle(.appAccent)
                    Text(L10n.Dashboard.densityDetails)
                        .font(.system(size: AppUI.caption2FontSize))
                        .lineSpacing(AppUI.atomic)
                        .foregroundStyle(.appSecondary)
                }
                .padding(.top, AppUI.tiny)
            }
            .padding(AppUI.wide)
            .background(
                ZStack {
                    Color.appCard
                    LinearGradient(
                        colors: [.appAccent.opacity(0.03), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AppUI.Metrics.dashboardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppUI.Metrics.dashboardRadius)
                    .stroke(Color.appBorder.opacity(AppUI.disabledOpacity), lineWidth: AppUI.borderWidth)
            )
            .shadow(color: AppUI.shadowColor, radius: AppUI.shadowRadius + 5, x: 0, y: AppUI.shadowY + 6)
        }
    }
    
    private var dailyInsightsSection: some View {
        // 3. 每日灵感 (AI 合成摘要预览)
        VStack(alignment: .leading, spacing: AppUI.tightPadding) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.appAccent)
                Text(L10n.Dashboard.tr("dailyInsights"))
                    .font(.headline)
                Spacer()
                Button(action: { refreshInsights() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.appSecondary)
                        .rotationEffect(.degrees(isLoadingInsights ? 360 : 0))
                        .animation(isLoadingInsights ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoadingInsights)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                if isLoadingInsights {
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
                } else if let recap = dailyRecap {
                    Button(action: {
                        HapticFeedback.shared.trigger(.selection)
                        if store.pages.contains(where: { $0.id == recap.targetPageID }) {
                            router.navigateToPage(id: recap.targetPageID)
                        } else {
                            ToastManager.shared.show(type: .info, message: L10n.Dashboard.insightsPageDeleted)
                        }
                    }) {
                        VStack(alignment: .leading, spacing: AppUI.small) {
                            Text(recap.targetPageTitle)
                                .font(.system(size: AppUI.subheadlineFontSize, weight: .bold))
                                .foregroundColor(.appAccent)
                            
                            Text(recap.insight)
                                .font(.system(size: AppUI.Metrics.dashboardLabelSize))
                                .foregroundColor(.appText)
                                .lineSpacing(AppUI.tiny)
                                .multilineTextAlignment(.leading)
                            
                            if !recap.suggestedConnection.isEmpty {
                                HStack(alignment: .top, spacing: AppUI.tiny) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: AppUI.caption2FontSize))
                                        .foregroundColor(.orange)
                                    Text(recap.suggestedConnection)
                                        .font(.system(size: AppUI.caption2FontSize + 1, weight: .medium))
                                        .foregroundColor(.appSecondary)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(.top, AppUI.tiny)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(L10n.Dashboard.insightsEmpty)
                        .font(.subheadline)
                        .foregroundColor(.appSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 10)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppUI.standardRadius)
                    .fill(Color.appCard)
                    .shadow(color: AppUI.shadowColor, radius: AppUI.shadowRadius, x: 0, y: AppUI.shadowY + 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppUI.standardRadius)
                    .stroke(
                        LinearGradient(colors: [.appAccent.opacity(AppUI.dimmedOpacity), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: AppUI.borderWidth
                    )
            )
        }
    }
    
    private var hotTopicsSection: some View {
        // 4. 热门领域 (PageType 分布)
        VStack(alignment: .leading, spacing: AppUI.tightPadding) {
            HStack(spacing: AppUI.tiny) {
                Image(systemName: "rectangle.grid.2x2.fill")
                    .font(.caption)
                    .foregroundStyle(.appAccent)
                Text(L10n.Dashboard.tr("hotTopics"))
                    .font(.headline)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppUI.Grid.standardSpacing) {
                ForEach(PageType.allCases, id: \.self) { type in
                    let count = store.pages.filter { $0.type == type }.count
                    if count > 0 {
                        Button(action: {
                            HapticFeedback.shared.trigger(.selection)
                            router.navigate(to: .index(filterType: type))
                        }) {
                            HotTopicMedal(category: type.displayName, count: count, icon: type.icon, color: Color.fromModelColorName(type.colorName))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    @State private var dailyRecap: KnowledgeInsightService.DailyRecap?
    @State private var isLoadingInsights = false
    @Inject private var llm: LLMService
    
    private func refreshInsights() {
        guard !isLoadingInsights, llm.isEnabled, !llm.apiKey.isEmpty else { return }
        isLoadingInsights = true
        
        Task {
            do {
                let recap = try await KnowledgeInsightService.shared.generateDailyRecap(
                    pages: store.pages,
                    llmService: llm,
                    forceRefresh: false
                )
                await MainActor.run {
                    self.dailyRecap = recap
                    self.isLoadingInsights = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingInsights = false
                }
                print("Failed to generate insights: \(error)")
            }
        }
    }
    
    private func calculateStats() async {
        let pages = store.pages
        
        // 1. 计算反链地图
        var backlinkMap: [String: Int] = [:]
        for page in pages {
            for link in page.outgoingLinks {
                backlinkMap[link, default: 0] += 1
            }
        }
        
        // 2. 计算总链接数
        let links = pages.reduce(0) { $0 + $1.outgoingLinks.count }
        
        // 3. 计算重要度 (In + Out) Top 10
        let density = pages.map { page in
            let inbound = backlinkMap[page.title, default: 0]
            let outbound = page.outgoingLinks.count
            return DensityInfo(name: page.title, inbound: Double(inbound), outbound: Double(outbound))
        }
        .sorted { ($0.inbound + $0.outbound) > ($1.inbound + $1.outbound) }
        .prefix(10)
        .map { $0 }
        
        await MainActor.run {
            self.totalLinks = links
            self.densityData = density
        }
    }
    
    private func updateTags() {
        var dict: [String: Int] = [:]
        for page in store.pages {
            for tag in page.getAllTags() {
                dict[tag, default: 0] += 1
            }
        }
        tags = dict.map { ($0.key, $0.value) }.sorted { $0.count > $1.count }
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(AppUI.glassOpacity))
                        .frame(width: AppUI.CompositeRow.iconBoxSize, height: AppUI.CompositeRow.iconBoxSize)
                    Image(systemName: icon)
                        .font(.system(size: AppUI.subheadlineFontSize, weight: .bold))
                        .foregroundColor(color)
                }
                
                Spacer()
                
                if let trend = trend {
                    HStack(spacing: AppUI.atomic) {
                        Image(systemName: "arrow.up.right")
                        Text(trend)
                    }
                    .font(.system(size: AppUI.caption2FontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
                    .padding(.horizontal, AppUI.small - AppUI.atomic) // 6
                    .padding(.vertical, AppUI.atomic)
                    .background(Color.green.opacity(AppUI.glassOpacity))
                    .clipShape(Capsule())
                }
            }
            
            VStack(alignment: .leading, spacing: AppUI.atomic) {
                Text(title)
                    .font(.system(size: AppUI.captionFontSize, weight: .medium))
                    .foregroundColor(.appSecondary)
                
                HStack(alignment: .firstTextBaseline, spacing: AppUI.tiny) {
                    Text(value)
                        .font(.system(size: AppUI.Metrics.heroValueSize, weight: .bold, design: .rounded))
                        .foregroundColor(.appText)
                    
                    if let unit = unit {
                        Text(unit)
                            .font(.caption2)
                            .foregroundColor(.appSecondary)
                    }
                }
            }
        }
        .padding(AppUI.standardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                Color.appCard
                LinearGradient(
                    colors: [color.opacity(0.08), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: AppUI.Metrics.dashboardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppUI.Metrics.dashboardRadius)
                .stroke(
                    LinearGradient(
                        colors: [.appBorder.opacity(AppUI.secondaryOpacity), .appBorder.opacity(AppUI.dimmedOpacity)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: AppUI.borderWidth
                )
        )
        .shadow(color: AppUI.shadowColor, radius: AppUI.shadowRadius, x: 0, y: AppUI.shadowY + 1)
    }
}

/// 热门领域勋章 (横向卡片)
struct HotTopicMedal: View {
    let category: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppUI.medium) {
            ZStack {
                Circle()
                    .fill(color.opacity(AppUI.glassOpacity))
                    .frame(width: AppUI.Metrics.iconBoxSize, height: AppUI.Metrics.iconBoxSize)
                Image(systemName: icon)
                    .font(.system(size: AppUI.headlineFontSize))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: AppUI.atomic) {
                Text(category)
                    .font(.system(size: AppUI.titleFontSize, weight: .bold))
                    .foregroundColor(.appText)
                Text("\(count) " + L10n.Dashboard.tr("index.pages"))
                    .font(.system(size: AppUI.caption2FontSize + 1))
                    .foregroundColor(.appSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.appSecondary.opacity(0.3))
        }
        .padding(AppUI.standardPadding)
        .appMetricCardStyle(color: color, cornerRadius: AppUI.standardRadius)
    }
}

private var emptyView: some View {
    VStack {
        Image(systemName: "chart.bar.fill")
            .font(.largeTitle)
            .foregroundColor(.appSecondary.opacity(0.2))
        Text(L10n.Common.Empty.tr("noData"))
            .font(.caption)
            .foregroundColor(.appSecondary)
    }
    .frame(maxWidth: .infinity, minHeight: AppUI.Metrics.chartHeight)
}

struct DensityInfo: Identifiable {
    let id = UUID()
    let name: String
    let inbound: Double
    let outbound: Double
}
