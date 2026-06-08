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
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.standardPadding) {
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
        .padding(DesignSystem.medium)
        .background(color.opacity(DesignSystem.glassOpacity / 3))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
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
