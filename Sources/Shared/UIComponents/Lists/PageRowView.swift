// PageRowView.swift
//
// 作者: Wang Chong
// 功能说明: 本文件定义了知识库页面行视图，用于在列表中展示 WikiPage 的核心摘要信息。
// MARK: [PR-03] 统一页面项展示规范，优化列表渲染性能与视觉反馈
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 知识库页面行视图组件
/// 展示页面图标、标题、类型、更新时间及状态指示器。
struct PageRowView: View {
    // MARK: - Properties
    
    let page: KnowledgePage
    var compact: Bool = false
    
    // MARK: - Initialization
    
    init(page: KnowledgePage, compact: Bool = false) {
        self.page = page
        self.compact = compact
    }
    
    // MARK: - Body
    
    public var body: some View {
        HStack(spacing: Spacing.medium) {
            // 类型图标容器
            Image(systemName: page.displayIcon)
                .font(.body)
                .foregroundStyle(Color.fromModelColorName(page.pageType.colorName))
                .frame(width: Spacing.largeIconSize, height: Spacing.largeIconSize) // 32
                .background(Color.fromModelColorName(page.pageType.colorName).opacity(Colors.glassOpacity * 1.5))
                .clipShape(RoundedRectangle(cornerRadius: Spacing.smallRadius))
            
            VStack(alignment: .leading, spacing: Spacing.atomic * 1.5) { // 3
                // 页面标题
                Text(page.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.appText)
                    .lineLimit(1)
                
                // 紧凑模式下隐藏辅助信息
                if !compact {
                    HStack(spacing: Spacing.small) {
                        // 页面类型标签
                        Text(page.pageType.displayName)
                            .font(.caption2)
                            .padding(.horizontal, DesignSystem.Chip.horizontalPadding)
                            .padding(.vertical, DesignSystem.Chip.verticalPadding)
                            .background(Color.fromModelColorName(page.pageType.colorName).opacity(Colors.glassOpacity * 2))
                            .clipShape(Capsule())
                            .foregroundStyle(Color.fromModelColorName(page.pageType.colorName))
                        
                        // 更新时间
                        Text(page.updatedAt.formatted(Date.FormatStyle(date: .numeric, time: .omitted, locale: Localized.currentLocale)))
                            .font(.caption2)
                            .foregroundStyle(.appSecondary)
                        
                        // 标签预览
                        if !page.tags.isEmpty {
                            Text(page.tags.prefix(2).joined(separator: ", "))
                                .font(.caption2)
                                .foregroundStyle(.appSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            
            Spacer()
            
            // 导航箭头（标准 chevron 替代绿点，语义更清晰）
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.appSecondary.opacity(0.4))
        }
        .padding(.horizontal, DesignSystem.small)
        .padding(.vertical, DesignSystem.small)
        .background(Color.appCard.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: Spacing.smallRadius))
        .contentShape(Rectangle()) // 确保整行可点击
    }
}
