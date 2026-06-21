//
//  GraphComponents.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：知识图谱：3D 可视化、社区发现、力导向布局。
//
import SwiftUI

// MARK: - Graph Legend Row
/// 图谱图例行组件
private struct GraphLegendRow: View {
    let color: Color
    let title: String
    
    var body: some View {
        HStack(spacing: DesignSystem.tiny + DesignSystem.atomic) {
            Circle()
                .fill(color)
                .frame(width: DesignSystem.microIconSize, height: DesignSystem.microIconSize)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.appSecondary)
        }
    }
}

// MARK: - Graph Legend
/// 图谱图例，支持类型与聚类两种模式。
/// 图谱图例组件
/// 负责展示节点颜色所代表的含义（如页面类型或聚类分组），增强图谱的可解释性
struct GraphLegend: View {
    let useClustering: Bool
    let clusters: [GraphClusteringService.Cluster]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            HStack(spacing: DesignSystem.tiny + DesignSystem.atomic) {
                Image(systemName: DesignSystem.Icons.listBulletRectanglePortrait)
                    .font(.caption)
                    .foregroundStyle(.appAccent)
                Text(L10n.Graph.legend)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.appText)
            }
            .padding(.bottom, DesignSystem.atomic)
            
            if useClustering {
                ForEach(clusters) { cluster in
                    GraphLegendRow(color: .fromModelColorName(cluster.colorName), title: cluster.name)
                }
            } else {
                ForEach(PageType.allCases) { type in
                    GraphLegendRow(color: .fromModelColorName(type.colorName), title: type.displayName)
                }
            }
        }
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.standardRadius))
        .shadow(color: .black.opacity(DesignSystem.glassOpacity * 2), radius: DesignSystem.smallRadius)
    }
}

// MARK: - Graph Selected Node Card
/// 选中节点的详情卡片。
/**
 * @description: 节点选中状态下的详情预览卡片，包含标题、类型、统计信息及跳转箭头
 * @return {View}
 */
/// 图谱选中节点详情卡片组件
/// 负责在选中节点时于底部弹出信息摘要卡片，展示页面核心元数据并提供跳转入口
struct GraphSelectedNodeCard: View {
    let page: KnowledgePage
    var heroNamespace: Namespace.ID?

    var body: some View {
        NavigationLink(value: AppRoute.pageDetail(id: page.id)) {
            cardContent
        }
        .buttonStyle(.plain)
        .padding(.horizontal, DesignSystem.standardPadding)
        .padding(.bottom, DesignSystem.standardPadding)
    }

    /**
     * @description: 渲染卡片内部的主体布局与阴影装饰
     * @return {View}
     */
    private var cardContent: some View {
        HStack(spacing: DesignSystem.medium) {
            Image(systemName: page.displayIcon)
                .foregroundStyle(Color.fromModelColorName(page.pageType.colorName))
                .frame(width: DesignSystem.Action.minTouchTarget, height: DesignSystem.Action.minTouchTarget)
                .background(Color.fromModelColorName(page.pageType.colorName).opacity(DesignSystem.glassOpacity))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))

            VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                Text(page.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.appText)
                Text("\(page.pageType.displayName)  \(page.wordCount) \(L10n.Knowledge.Page.wordCountUnit)  \(page.outgoingLinks.count) \(L10n.Knowledge.Page.outLinkUnit)")
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
            }

            Spacer()

            Image(systemName: DesignSystem.Icons.forward)
                .foregroundStyle(.appSecondary)
        }
        .padding()
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
        .shadow(color: .black.opacity(DesignSystem.glassOpacity * 2), radius: DesignSystem.mediumRadius)
    }
}

// MARK: - Graph Insights Panel
/// 图谱洞察面板，显示知识库的发现结果：意外关联、孤立页面、稀疏社区、桥接节点。
/// 知识图谱洞察分析面板
/// 集中展示图谱布局中的孤点、异常连接、聚类中心等核心发现。
/// 知识图谱洞察分析面板组件
/// 负责展示基于布局分析产生的深度发现，如意外关联、知识孤岛及核心桥接节点等
struct GraphInsightsPanel: View {
    let surprising: [UUID]
    let orphans: [UUID]
    let sparse: [UUID]
    let bridges: [UUID]
    let nodes: [GraphNode]
    let onSelectNode: (UUID) -> Void
    
    @State private var expandedSections: Set<String> = ["surprising", "orphans", "sparse", "bridges"]
    @State private var showGuide = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.standardPadding) {
                // 概念图解指南入口卡片
                Button {
                    showGuide = true
                } label: {
                    HStack(spacing: DesignSystem.medium) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.appAccent)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                            Text(L10n.Graph.guide.entryTitle)
                                .font(.subheadline.bold())
                                .foregroundStyle(.appText)
                            Text(L10n.Graph.guide.entrySubtitle)
                                .font(.caption)
                                .foregroundStyle(.appSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: DesignSystem.Icons.forward)
                            .foregroundStyle(.appSecondary)
                    }
                    .padding()
                    .background(Color.appCard.opacity(DesignSystem.surfaceOpacity))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.mediumRadius)
                            .stroke(Color.appAccent.opacity(DesignSystem.translucentOpacity), lineWidth: DesignSystem.borderWidth)
                    )
                }
                .buttonStyle(.plain)
                .padding(.bottom, DesignSystem.small)
                .sheet(isPresented: $showGuide) {
                    GraphConceptGuideSheet()
                }

                insightSection(
                        id: "surprising",
                        icon: DesignSystem.Icons.link,
                        title: L10n.Graph.insightSurprising,
                        count: surprising.count,
                        description: L10n.Graph.insightSurprisingDesc,
                        color: .appComparison
                    )
                    
                    insightSection(
                        id: "orphans",
                        icon: DesignSystem.Icons.questionCircle,
                        title: L10n.Graph.insightOrphans,
                        count: orphans.count,
                        description: L10n.Graph.insightOrphansDesc,
                        color: .appSecondary
                    )
                    
                    insightSection(
                        id: "sparse",
                        icon: DesignSystem.Icons.chartBarXaxis,
                        title: L10n.Graph.insightSparse,
                        count: sparse.count,
                        description: L10n.Graph.insightSparseDesc,
                        color: .orange
                    )
                    
                    insightSection(
                        id: "bridges",
                        icon: DesignSystem.Icons.arrowTriangleBranch,
                        title: L10n.Graph.insightBridges,
                        count: bridges.count,
                        description: L10n.Graph.insightBridgesDesc,
                        color: .appAccent
                    )
                }
                .padding()
            }
            .background(PageBackgroundView(accentColor: .appAccent))
        }
    
    /// 渲染图分析报告中的单项洞察板块
    /// - Parameters:
    ///   - id: 洞察类型的唯一标识
    ///   - icon: 图标名称
    ///   - title: 洞察板块的标题
    ///   - count: 相关元素的统计数量
    ///   - description: 详细的文字说明
    ///   - color: 洞察板块的主题颜色
    private func insightSection(id: String, icon: String, title: String, count: Int, description: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.mediumRadius) {
            // Section header
            Button(action: {
                withAnimation { 
                    if expandedSections.contains(id) {
                        expandedSections.remove(id)
                    } else {
                        expandedSections.insert(id)
                    }
                }
            }) {
                HStack(spacing: DesignSystem.small) {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundStyle(color)
                        .frame(width: DesignSystem.iconLarge)
                    
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.appText)
                    
                    Text("\(count)")
                        .font(.footnote)
                        .foregroundStyle(color)
                        .padding(.horizontal, DesignSystem.small)
                        .padding(.vertical, DesignSystem.atomic + DesignSystem.borderWidth)
                        .background(color.opacity(DesignSystem.glassOpacity))
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    Image(systemName: expandedSections.contains(id) ? DesignSystem.Icons.down : DesignSystem.Icons.forward)
                        .font(.footnote)
                        .foregroundStyle(.appSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("insight-\(id)")
            
            if expandedSections.contains(id) {
                insightSectionExpandedContent(id: id, description: description, color: color)
            }
        }
        .padding(DesignSystem.medium)
        .background(color.opacity(DesignSystem.glassOpacity / 3))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
    }

    /// 渲染已展开分析板块的详情和节点推荐 Chips
    /// - Parameters:
    ///   - id: 洞察类型的唯一标识
    ///   - description: 详细说明文字
    ///   - color: 节点 Chips 的渲染主题色
    private func insightSectionExpandedContent(id: String, description: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.mediumRadius) {
            Text(description)
                .font(.footnote)
                .foregroundStyle(.appSecondary)
                .padding(.leading, DesignSystem.huge)
            
            // Node chips
            let nodeIDs = getNodeIDs(for: id)
            if !nodeIDs.isEmpty {
                FlowLayout(spacing: DesignSystem.small) {
                    ForEach(nodeIDs, id: \.self) { nodeID in
                        if let node = nodes.first(where: { $0.id == nodeID }) {
                            Button(action: { onSelectNode(nodeID) }) {
                                HStack(spacing: DesignSystem.tiny) {
                                    Image(systemName: node.pageType.icon)
                                        .font(.footnote)
                                    Text(node.title)
                                        .font(.footnote)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, DesignSystem.mediumRadius)
                                .padding(.vertical, DesignSystem.tiny + DesignSystem.atomic)
                                .background(color.opacity(DesignSystem.glassOpacity))
                                .clipShape(Capsule())
                                .foregroundStyle(color)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.leading, DesignSystem.huge)
            }
        }
    }
    
    private func getNodeIDs(for section: String) -> [UUID] {
        switch section {
        case "surprising": return surprising
        case "orphans": return orphans
        case "sparse": return sparse
        case "bridges": return bridges
        default: return []
        }
    }
}

// MARK: - Graph Concept Guide Sheet
/// 知识图谱概念大白话指南弹窗 Sheet
struct GraphConceptGuideSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.huge) {
                // 1. 头部标题
                HStack {
                    Label(L10n.Graph.guide.sheetTitle, systemImage: "info.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.appAccent)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: DesignSystem.Icons.errorCircle)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, DesignSystem.medium)
                
                // 2. 3D 概念指南干净的图示
                VStack(spacing: 0) {
                    Image("graph_concepts_guide_clean")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
                        .shadow(color: .black.opacity(DesignSystem.translucentOpacity), radius: DesignSystem.shadowRadius)
                }
                .appContainer(background: Color.appCard.opacity(DesignSystem.surfaceOpacity), padding: false)
                
                // 3. SwiftUI 图例对照与大白话描述
                VStack(alignment: .leading, spacing: DesignSystem.widePadding) {
                    Group {
                        guideRow(color: .appAccent, icon: "circle.fill", title: L10n.Graph.guide.legendNodeTitle, desc: L10n.Graph.guide.legendNodeDesc)
                        guideRow(color: .appSecondary, icon: "minus", title: L10n.Graph.guide.legendLinkTitle, desc: L10n.Graph.guide.legendLinkDesc)
                    }
                    Divider()
                        .background(Color.appAccent.opacity(DesignSystem.glassOpacity))
                    Group {
                        guideRow(color: .appConcept, icon: "circle.fill", title: L10n.Graph.guide.typeConceptTitle, desc: L10n.Graph.guide.typeConceptDesc)
                        guideRow(color: .appEntity, icon: "circle.fill", title: L10n.Graph.guide.typeEntityTitle, desc: L10n.Graph.guide.typeEntityDesc)
                        guideRow(color: .purple, icon: "circle.fill", title: L10n.Graph.guide.bridgeTitle, desc: L10n.Graph.guide.bridgeDesc)
                        guideRow(color: .orange, icon: "circle.fill", title: L10n.Graph.guide.sparseTitle, desc: L10n.Graph.guide.sparseDesc)
                        guideRow(color: .gray, icon: "circle.fill", title: L10n.Graph.guide.orphanTitle, desc: L10n.Graph.guide.orphanDesc)
                        guideRow(color: .appComparison, icon: "bolt.fill", title: L10n.Graph.guide.surprisingTitle, desc: L10n.Graph.guide.surprisingDesc)
                    }
                }
                .padding()
                .appContainer(background: Color.appCard.opacity(DesignSystem.surfaceOpacity), padding: false)
                
                Spacer(minLength: DesignSystem.huge)
            }
            .padding(DesignSystem.huge)
        }
        .presentationDetents([.large])
        .presentationBackground(.ultraThinMaterial)
    }
    
    private func guideRow(color: Color, icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.medium) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: DesignSystem.iconMedium, height: DesignSystem.iconMedium)
                .background(color.opacity(DesignSystem.glassOpacity))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.appText)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
