// PageDetailHeader.swift
//
// 作者: Wang Chong
// 功能说明: Page detail header displaying type/status/confidence badges, title, aliases, tags, and meta info.
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

// MARK: - Page Detail Header
/// Page detail header displaying type/status/confidence badges, title, aliases, tags, and meta info.
/// 页面详情顶栏组件
/// 负责展示知识页面的标题、类型标识、最近修改时间及操作入口（如书签、分享、删除）
/// 页面详情页顶部头部组件
/// 负责在详情页显著位置展示核心元数据（标题、类型、状态、置信度、别名、标签及统计信息），支持 Hero 动画
struct PageDetailHeader: View {
    let page: KnowledgePage
    var heroNamespace: Namespace.ID? = nil
    @ObservedObject private var taskCenter = TaskCenter.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            breadcrumb
            typeStatusConfidenceRow
            titleView
            tagsAndAliasesView
            
            // Metadata section with industrial-grade collapsible control
            #if os(watchOS)
            VStack(alignment: .leading) {
                HStack {
                    Label(Localized.tr("page.metaInfo"), systemImage: "info.circle")
                        .font(.caption2.bold())
                        .foregroundStyle(.appSecondary)
                    Spacer()
                }
                metaInfoView.padding(.top, 4)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.appCard.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.smallRadius))
            #else
            DisclosureGroup(
                isExpanded: $isMetaExpanded,
                content: { metaInfoView.padding(.top, 4) },
                label: {
                    HStack {
                        Label(Localized.tr("page.metaInfo"), systemImage: "info.circle")
                            .font(.caption2.bold())
                            .foregroundStyle(.appSecondary)
                        Spacer()
                    }
                }
            )
            .tint(.appSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.appCard.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.smallRadius))
            #endif
        }
        .padding()
    }
    
    @State private var isMetaExpanded = false
    
    // MARK: - Breadcrumb
    private var breadcrumb: some View {
        HStack(spacing: 4) {
            Image(systemName: "books.vertical.fill")
                .font(.caption2)
                .foregroundStyle(.appSecondary)
            Text(Localized.tr("page.knowledge"))
                .font(.caption2)
                .foregroundStyle(.appSecondary)
            Image(systemName: "chevron.right")
                .font(.system(size: 8))
                .foregroundStyle(.appSecondary)
            
            // AI Status Indicator
            if taskCenter.tasks.contains(where: { if case .running = $0.status { return true }; return false }) {
                HStack(spacing: 4) {
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 10))
                    Text(L10n.AI.Task.tr("status.running"))
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundStyle(.appAccent)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.appAccent.opacity(0.1))
                .clipShape(Capsule())
                .transition(.opacity.combined(with: .scale))
            }

            if page.isPinned {
                Spacer()
                Image(systemName: "pin.fill")
                    .font(.caption2)
                    .foregroundStyle(.appComparison)
            }
        }
    }
    
    // MARK: - Type / Status / Confidence Row
    private var typeStatusConfidenceRow: some View {
        HStack(spacing: 10) {
            // Type badge
            TypeBadge(page: page, heroNamespace: heroNamespace)
            
            // Status badge
            StatusBadge(page: page)
            
            // Confidence badge
            ConfidenceBadge(page: page)
            
            Spacer()
        }
    }
    
    // MARK: - Title
    private var titleView: some View {
        Text(page.title)
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundStyle(.appText)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel(Localized.trf("page.titleAccessibility", page.title))
    }
    
    // MARK: - Aliases & Tags (Unified Flow)
    @ViewBuilder
    private var tagsAndAliasesView: some View {
        let combinedTags = Array(Set(page.tags + page.aliases)).filter { $0 != page.title }.sorted()
        
        if !combinedTags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(combinedTags, id: \.self) { item in
                        let isAlias = page.aliases.contains(item)
                        HStack(spacing: 4) {
                            if isAlias {
                                Image(systemName: "arrow.branch")
                                    .font(.system(size: 8))
                            } else {
                                Text("#")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            Text(item)
                        }
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            isAlias ? 
                            Color.appSource.opacity(0.1) : 
                            Color.appAccent.opacity(0.1)
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(
                                    isAlias ? 
                                    Color.appSource.opacity(0.2) : 
                                    Color.appAccent.opacity(0.2), 
                                    lineWidth: 0.5
                                )
                        )
                        .foregroundStyle(isAlias ? .appSource : .appAccent)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    // MARK: - Meta Info
    private var metaInfoView: some View {
        HStack(spacing: 16) {
            Label(Localized.trf("page.createdFormat", page.created.formatted(.dateTime.year().month().day().locale(Localized.currentLocale))), systemImage: "calendar")
            Label(Localized.trf("page.updatedFormat", page.updated.formatted(.dateTime.year().month().day().locale(Localized.currentLocale))), systemImage: "clock")
            Label(Localized.trf("page.wordCount", page.wordCount), systemImage: "textformat")
            Label(Localized.trf("page.outLinksCount", page.outgoingLinks.count), systemImage: "link")
        }
        .font(.caption)
        .foregroundStyle(.appSecondary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Localized.trf("page.metaAccessibility", page.created.formatted(.dateTime.year().month().day().locale(Localized.currentLocale)), page.wordCount, page.outgoingLinks.count))
    }
}

// MARK: - Type Badge
/// 页面类型标识徽章小组件
/// 负责以胶囊形态展示页面所属分类图标及名称，并适配 Hero 动画转场标识
private struct TypeBadge: View {
    let page: KnowledgePage
    var heroNamespace: Namespace.ID?
    
    var body: some View {
        HStack(spacing: 4) {
            if let ns = heroNamespace {
                Image(systemName: page.displayIcon)
                    .font(.caption)
                    .matchedGeometryEffect(id: page.id, in: ns)
            } else {
                Image(systemName: page.displayIcon)
                    .font(.caption)
            }
            Text(page.type.displayName)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.fromModelColorName(page.type.colorName).opacity(0.2))
        .clipShape(Capsule())
        .foregroundStyle(Color.fromModelColorName(page.type.colorName))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Localized.trf("page.typeAccessibility", page.type.displayName))
    }
}

// MARK: - Status Badge
/// 页面状态标识徽章小组件
/// 负责展示页面的生命周期状态（如草稿、已发布、已废弃），并提供颜色编码的视觉提示
private struct StatusBadge: View {
    let page: KnowledgePage
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.fromModelColorName(page.status.colorName))
                .frame(width: 6, height: 6)
            Text(page.status.displayName)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.fromModelColorName(page.status.colorName).opacity(DesignSystem.Opacity.glass))
        .clipShape(Capsule())
        .foregroundStyle(Color.fromModelColorName(page.status.colorName))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Localized.trf("page.statusAccessibility", page.status.displayName))
    }
}

// MARK: - Confidence Badge
/// 页面置信度标识徽章小组件
/// 负责展示内容的可靠性指标，通常由 AI 自动打分或人工审核确认
private struct ConfidenceBadge: View {
    let page: KnowledgePage
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "cellularbars")
                .font(.caption2)
            Text(page.confidence.displayName)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.fromModelColorName(page.confidence.colorName).opacity(DesignSystem.Opacity.glass))
        .clipShape(Capsule())
        .foregroundStyle(Color.fromModelColorName(page.confidence.colorName))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Localized.trf("page.confidenceAccessibility", page.confidence.displayName))
    }
}
