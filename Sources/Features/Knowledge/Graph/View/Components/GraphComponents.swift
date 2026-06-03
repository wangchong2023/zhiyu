//
//  GraphComponents.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：属于 Components 模块，提供相关的结构体或工具支撑。
//
import SwiftUI

// MARK: - Graph Node View
/// 图谱中的单个节点渲染组件。
/// 具备三级渲染能力：
/// 1. 选中高亮态：展示发光光晕与呼吸脉冲。
/// 2. 常规态：展示类型图标与标准尺寸。
/// 3. LOD 低细节态：远景下自动精简为纯色圆点，确保千级节点下的流畅度。
/// 知识图谱节点视图组件
/// 负责单个节点的视觉呈现、LOD (细节分级) 渲染、发光动画及交互反馈。
/// 知识图谱节点视图组件
/// 负责单个节点的视觉呈现、LOD (细节分级) 渲染、发光动画及交互反馈
struct GraphNodeView: View {
    let node: GraphNode
    let isSelected: Bool
    let isAnimating: Bool
    let linkCount: Int
    let clusters: [GraphClusteringService.Cluster]
    let useClustering: Bool
    let onSelect: () -> Void
    var heroNamespace: Namespace.ID
    @State private var isHovered = false
    
    // 视口裁剪参数
    let viewportRect: CGRect? // 当前可见区域
    let scale: CGFloat
    
    private var isVisible: Bool {
        guard let rect = viewportRect else { return true }
        // 简单的包围盒检测
        let margin: CGFloat = DesignSystem.huge
        return rect.insetBy(dx: -margin, dy: -margin).contains(node.position)
    }

    private var nodeSize: CGFloat {
        isSelected ? 32 : max(18, min(30, 20 + CGFloat(linkCount) * 1.5))
    }

    var body: some View {
        Group {
            if isVisible {
                let nodeBaseColor: Color = {
                    if useClustering, let cluster = clusters.first(where: { $0.pageIDs.contains(node.id) }) {
                        return Color.fromModelColorName(cluster.colorName)
                    }
                    return Color.fromModelColorName(node.pageType.colorName)
                }()
                let isLowDetail = scale < AppConfig.UI.graphLODZoomThreshold
                
                ZStack {
                    if isLowDetail {
                        // LOD: 远景模式 - 仅显示纯色圆点，极致性能
                        Circle()
                            .fill(nodeBaseColor)
                            .frame(width: DesignSystem.iconSmall, height: DesignSystem.iconSmall)
                    } else {
                        nodeContent
                    }
                }
                .onTapGesture { 
                    HapticFeedback.shared.trigger(.link)
                    onSelect() 
                }
            }
        }
    }
    
    private var nodeContent: some View {
        ZStack {
            let nodeBaseColor = useClustering ? (clusters.first(where: { $0.pageIDs.contains(node.id) }).map { Color.fromModelColorName($0.colorName) } ?? Color.fromModelColorName(node.pageType.colorName)) : Color.fromModelColorName(node.pageType.colorName)

            // 1. 深度发光 (Aura Effect)
            if isSelected {
                Circle()
                    .fill(nodeBaseColor.opacity(DesignSystem.glassOpacity))
                    .frame(width: nodeSize * 2.2, height: nodeSize * 2.2)
                    .blur(radius: DesignSystem.cardRadius)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
            }

            // 2. 核心脉冲 (Core Pulse)
            if isSelected {
                Circle()
                    .stroke(nodeBaseColor.opacity(DesignSystem.disabledOpacity), lineWidth: DesignSystem.borderWidth * 1.5)
                    .frame(width: nodeSize, height: nodeSize)
                    .scaleEffect(isAnimating ? 1.8 : 1.0)
                    .opacity(isAnimating ? 0 : 1)
                    .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: isAnimating)
            }

            // 3. 节点本体 (Node Body)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [nodeBaseColor.opacity(0.85), nodeBaseColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                #if os(iOS)
                .matchedGeometryEffect(id: node.id, in: heroNamespace, isSource: true)
                #endif
                .frame(width: nodeSize, height: nodeSize)
                #if !os(watchOS)
                .onHover { hovering in
                    withAnimation(.spring()) {
                        isHovered = hovering
                    }
                    if hovering {
                        HapticFeedback.shared.trigger(.selection)
                    }
                }
                #endif
                .overlay {
                    hoverTooltip
                }
                .contextMenu {
                    Button(action: { onSelect() }) {
                        Label(L10n.Graph.viewDetail, systemImage: DesignSystem.Icons.weeklyInsight)
                    }
                    
                    Button(action: {
                        AppPasteboard.string = "[[\(node.title)]]"
                    }) {
                        Label(L10n.Graph.copyPageLink, systemImage: DesignSystem.Icons.link)
                    }
                    
                    Divider()
                    
                    #if os(macOS)
                    Button(action: {
                        // macOS 新窗口功能预留
                    }) {
                        Label(L10n.Common.openInNewWindow, systemImage: DesignSystem.Icons.macwindowBadgePlus)
                    }
                    #endif
                }
                .overlay(
                    Circle()
                        .stroke(.appGloss.opacity(DesignSystem.glassOpacity * 2), lineWidth: DesignSystem.borderWidth)
                )
                .shadow(color: nodeBaseColor.opacity(isSelected ? DesignSystem.fullOpacity - DesignSystem.glassOpacity : DesignSystem.disabledOpacity), radius: isSelected ? DesignSystem.standardPadding : DesignSystem.tiny + DesignSystem.atomic)
                .scaleEffect(isSelected ? 1.1 : 1.0)

            // 4. 类型图标
            Image(systemName: node.pageType.icon)
                .font(.system(size: isSelected ? DesignSystem.subheadlineFontSize : DesignSystem.microFontSize, weight: .bold))
                .foregroundStyle(.white)
        }
        .onTapGesture {
            HapticFeedback.shared.trigger(.link)
            onSelect()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(node.title), \(node.pageType.displayName)")
        .accessibilityValue(L10n.Graph.linksCountFormat(linkCount))
        .accessibilityHint(L10n.Graph.accessibility.nodeHint)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
        .accessibilityAction { onSelect() }
    }
    
    @ViewBuilder
    private var hoverTooltip: some View {
        if isHovered {
            VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                Text(node.title)
                    .font(.caption.bold())
                Text(node.pageType.displayName)
                    .font(.system(size: DesignSystem.microFontSize - 2))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, DesignSystem.small)
            .padding(.vertical, DesignSystem.tiny)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
            .offset(y: -DesignSystem.huge - DesignSystem.tiny)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Graph Node Label
/// 节点标题标签组件
/// 负责在节点下方渲染动态标题，具备自动 LOD（细节层次）切换能力。
/// 知识图谱节点标签组件
/// 负责在节点下方显示页面标题，并根据缩放比例（LOD）动态调整可见度与字号
struct GraphNodeLabel: View {
    /// 目标节点数据
    let node: GraphNode
    /// 选中状态，用于加粗字体与变色
    let isSelected: Bool
    /// 基础节点尺寸，用于计算垂直偏移
    let nodeSize: CGFloat
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// 动态字号计算：针对不同屏幕尺寸进行微调
    /// 大屏幕（iPad）下字号从 11pt 提升到 9pt，手机端保持 8pt，确保视觉比例和谐
    private var fontSize: CGFloat {
        horizontalSizeClass == .regular ? 10 : 8
    }

    var body: some View {
        Text(node.title)
            .font(.system(size: fontSize, weight: isSelected ? .semibold : .medium))
            .foregroundStyle(isSelected ? .appText : .appSecondary)
            .lineLimit(1)
            .position(x: node.position.x, y: node.position.y + nodeSize / 2 + DesignSystem.mediumRadius)
            .accessibilityHidden(true) // 节点图标已包含信息，标签设为隐藏以防冗余
    }
}

// MARK: - Graph Zoom Controls
/// 缩放控制栏。
/// 图谱缩放与交互控制组件
/// 负责提供缩放、居中、刷新布局、适应屏幕及 3D 视图切换的一站式控制功能
struct GraphZoomControls: View {
    @Binding var scale: CGFloat
    @Binding var lastScale: CGFloat
    @Binding var offset: CGSize
    @Binding var lastOffset: CGSize
    @Binding var show3D: Bool
    let onRelayout: () -> Void
    let onFitToScreen: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                withAnimation { scale = max(0.5, scale - 0.2) }
                lastScale = scale
            }) {
                Image(systemName: DesignSystem.Icons.minusMagnifyingglass)
                    .font(.body)
                    .foregroundStyle(.appSecondary)
                    .frame(width: DesignSystem.Action.minTouchTarget, height: DesignSystem.Action.minTouchTarget)
                    .background(Color.appCard)
            }
            .accessibilityIdentifier("zoom-out")
            .accessibilityLabel(L10n.Graph.accessibility.zoomOutLabel)
            .accessibilityHint(L10n.Graph.accessibility.zoomOutHint)

            Button(action: {
                withAnimation { scale = min(3.0, scale + 0.2) }
                lastScale = scale
            }) {
                Image(systemName: DesignSystem.Icons.plusMagnifyingglass)
                    .font(.body)
                    .foregroundStyle(.appSecondary)
                    .frame(width: DesignSystem.Action.minTouchTarget, height: DesignSystem.Action.minTouchTarget)
                    .background(Color.appCard)
            }
            .accessibilityIdentifier("zoom-in")
            .accessibilityLabel(L10n.Graph.accessibility.zoomInLabel)
            .accessibilityHint(L10n.Graph.accessibility.zoomInHint)

            Divider().frame(width: DesignSystem.borderWidth, height: DesignSystem.iconLarge).background(Color.appBorder)

            Button(action: {
                withAnimation {
                    scale = 1.0
                    lastScale = 1.0
                    offset = .zero
                    lastOffset = .zero
                }
            }) {
                Image(systemName: DesignSystem.Icons.scope)
                    .font(.body)
                    .foregroundStyle(.appSecondary)
                    .frame(width: DesignSystem.Action.minTouchTarget, height: DesignSystem.Action.minTouchTarget)
                    .background(Color.appCard)
            }
            .accessibilityIdentifier("reset")
            .accessibilityLabel(L10n.Graph.accessibility.resetLabel)
            .accessibilityHint(L10n.Graph.accessibility.resetHint)

            Divider().frame(width: DesignSystem.borderWidth, height: DesignSystem.iconLarge).background(Color.appBorder)

            Button(action: {
                withAnimation(.spring(response: 0.5)) { onFitToScreen() }
            }) {
                Image(systemName: DesignSystem.Icons.viewfinder)
                    .font(.body)
                    .foregroundStyle(.appSecondary)
                    .frame(width: DesignSystem.Action.minTouchTarget, height: DesignSystem.Action.minTouchTarget)
                    .background(Color.appCard)
            }
            .accessibilityIdentifier("fit-to-screen")
            .accessibilityLabel(L10n.Graph.accessibility.fitToScreenLabel)
            .accessibilityHint(L10n.Graph.accessibility.fitToScreenHint)

            Divider().frame(width: DesignSystem.borderWidth, height: DesignSystem.iconLarge).background(Color.appBorder)

            Button(action: {
                withAnimation(.spring(response: 0.6)) { onRelayout() }
            }) {
                Image(systemName: DesignSystem.Icons.refresh)
                    .font(.body)
                    .foregroundStyle(.appSecondary)
                    .frame(width: DesignSystem.Action.minTouchTarget, height: DesignSystem.Action.minTouchTarget)
                    .background(Color.appCard)
            }
            .accessibilityIdentifier("relayout")
            .accessibilityLabel(L10n.Graph.accessibility.relayoutLabel)
            .accessibilityHint(L10n.Graph.accessibility.relayoutHint)

            Divider().frame(width: DesignSystem.borderWidth, height: DesignSystem.iconLarge).background(Color.appBorder)

            Button(action: { show3D = true }) {
                Image(systemName: DesignSystem.Icons.view3d)
                    .font(.body)
                    .foregroundStyle(.appSecondary)
                    .frame(width: DesignSystem.Action.minTouchTarget, height: DesignSystem.Action.minTouchTarget)
                    .background(Color.appCard)
            }
            .accessibilityIdentifier("graph-3d")
            .accessibilityLabel(L10n.Graph.accessibility.threeDLabel)
            .accessibilityHint(L10n.Graph.accessibility.threeDHint)
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.standardRadius))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

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
    var heroNamespace: Namespace.ID? = nil

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
