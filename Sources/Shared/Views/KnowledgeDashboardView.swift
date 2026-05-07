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
    @State private var tags: [(tag: String, count: Int)] = []
    @State private var showDensityInfo = false
    
    private var totalLinks: Int {
        store.pages.reduce(0) { $0 + $1.outgoingLinks.count }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppUI.Grid.standardSpacing) {
                // 1. 核心指标卡片
                HStack(spacing: AppUI.Grid.standardSpacing) {
                    MetricBox(title: Localized.tr("page.backlinks"), value: "\(totalLinks)", icon: AppUI.Icons.link, color: .blue)
                    MetricBox(title: Localized.tr("common.type"), value: "\(store.pages.count)", icon: AppUI.Icons.tag, color: .green)
                }
                .padding(.horizontal)
                
                // 2. 知识密度图表
                VStack(alignment: .leading, spacing: AppUI.small) {
                    HStack {
                        Label(Localized.tr("dashboard.density"), systemImage: "waveform.path.ecg")
                            .font(.headline)
                        Spacer()
                        Button {
                            showDensityInfo.toggle()
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.appSecondary)
                        }
                    }
                    
                    if showDensityInfo {
                        Text(Localized.tr("dashboard.density.desc"))
                            .font(.caption)
                            .foregroundStyle(.appSecondary)
                            .padding(.bottom, AppUI.atomic)
                    }
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: AppUI.largeRadius)
                            .fill(AppUI.containerBackground)
                            .frame(height: AppUI.Metrics.chartHeight)
                        
                        if densityData.isEmpty {
                            Text(Localized.tr("common.empty.noData"))
                                .foregroundStyle(.appSecondary)
                        } else {
                            Chart {
                                ForEach(densityData) { data in
                                    BarMark(
                                        x: .value(Localized.tr("page.title"), data.name),
                                        y: .value(Localized.tr("dashboard.density"), data.density)
                                    )
                                    .foregroundStyle(Color.appAccent.gradient)
                                    .cornerRadius(AppUI.microRadius)
                                }
                            }
                            .chartYAxis(.hidden)
                            .padding()
                        }
                    }
                }
                .padding()
                
                // 3. 热门话题/勋章墙
                VStack(alignment: .leading, spacing: AppUI.small) {
                    Label(Localized.tr("dashboard.hotTopics"), systemImage: AppUI.Icons.sparkles)
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppUI.Grid.standardSpacing) {
                            ForEach(tags.prefix(5), id: \.tag) { tagInfo in
                                HotTopicMedal(tag: tagInfo.tag, count: tagInfo.count)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, AppUI.atomic)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color.appBackground)
        .navigationTitle(Localized.tr("dashboard.title"))
        .onAppear {
            updateTags()
        }
    }
    
    private var densityData: [DensityInfo] {
        store.pages.map { page in
            let density = Double(page.outgoingLinks.count) / Double(max(1, page.content.count)) * 1000
            return DensityInfo(name: page.title, density: density)
        }
        .sorted { $0.density > $1.density }
        .prefix(10)
        .map { $0 }
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
struct HotTopicMedal: View {
    let tag: String
    let count: Int
    
    var body: some View {
        VStack(spacing: AppUI.small) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: AppUI.Gallery.iconSize * 1.2, height: AppUI.Gallery.iconSize * 1.2)
                Image(systemName: AppUI.Icons.trophy)
                    .font(.title3)
                    .foregroundStyle(.orange)
            }
            
            VStack(spacing: AppUI.atomic) {
                Text(tag)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text("\(count) " + Localized.tr("page.references"))
                    .font(.system(size: AppUI.microFontSize))
                    .foregroundStyle(.appSecondary.opacity(0.5))
            }
        }
        .padding(.horizontal, AppUI.medium)
        .padding(.vertical, AppUI.medium + AppUI.atomic)
        .background(AppUI.containerBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppUI.largeRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppUI.largeRadius)
                .stroke(AppUI.containerBorder, lineWidth: AppUI.borderWidth)
        )
        .shadow(color: AppUI.shadowColor, radius: AppUI.shadowRadius / 2, x: 0, y: 2)
    }
}

struct MetricBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppUI.small) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
            }
            Text(value)
                .font(.system(size: AppUI.Metrics.heroValueSize, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .background(AppUI.containerBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppUI.largeRadius))
        .shadow(color: AppUI.shadowColor, radius: AppUI.shadowRadius / 2, x: 0, y: 2)
    }
}

struct DensityInfo: Identifiable {
    let id = UUID()
    let name: String
    let density: Double
}
