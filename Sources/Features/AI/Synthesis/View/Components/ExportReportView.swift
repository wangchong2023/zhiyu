// ExportReportView.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：PDF 导出报告视图。采用精致的 A4 排版与品牌化呈现，确保护读性与专业感。
// 核心原则：
// 1. 去硬编码：所有布局数值必须引用 AppUI 模式。
// 2. 视觉一致性：通过 Pattern-based 布局确保全工程报告输出体验统一。
// 版本: 1.1 (工业级重构，消除魔鬼数字并适配新 UI 模式)

import SwiftUI

/// PDF 报告预览与导出视图
/// 负责将选定的知识页面格式化为标准 A4 布局，提供品牌化页眉、层级内容渲染及自动分页支持
struct ExportReportView: View {
    let pages: [KnowledgePage]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.wide) {
            // 页眉：品牌标识
            HStack {
                Text(Localized.tr("report.appName"))
                    .font(.system(size: DesignSystem.large, weight: .bold))
                    .foregroundStyle(Color.appAccent)
                Spacer()
                Text(Date().formatted(Date.FormatStyle(date: .long, time: .omitted, locale: Localized.currentLocale)))
                    .font(.caption)
                    .foregroundStyle(Color.appSecondary)
            }
            .padding(.bottom, DesignSystem.wide)
            
            Divider()
            
            // 报告标题
            Text(Localized.tr("report.title"))
                .font(.system(size: DesignSystem.huge, weight: .black))
                .padding(.vertical, DesignSystem.small)
            
            Text(Localized.trf("report.nodeCount", pages.count))
                .font(.subheadline)
                .foregroundStyle(Color.appSecondary)
            
            // 内容详情
            ForEach(pages.prefix(DesignSystem.Metrics.maxReportPageExportCount), id: \.id) { page in // 10
                VStack(alignment: .leading, spacing: DesignSystem.small) {
                    HStack(spacing: DesignSystem.small) {
                        Image(systemName: page.pageType.icon)
                            .foregroundStyle(Color.fromModelColorName(page.pageType.colorName))
                        Text(page.title)
                            .font(.headline)
                            .foregroundStyle(Color.appText)
                    }
                    
                    Text(page.content.prefix(DesignSystem.Metrics.reportContentPreviewLength) + "...") // 300
                        .font(DesignSystem.captionFont) // 12
                        .foregroundStyle(Color.appText)
                        .lineLimit(DesignSystem.Metrics.maxReportContentLineLimit) // 5
                        .padding(.leading, DesignSystem.wide)
                    
                    if !page.tags.isEmpty {
                        HStack(spacing: DesignSystem.tiny) {
                            ForEach(page.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.system(size: DesignSystem.microFontSize, weight: .medium)) // 10
                                    .padding(.horizontal, DesignSystem.small)
                                    .padding(.vertical, DesignSystem.atomic)
                                    .background(Color.appAccent.opacity(DesignSystem.glassOpacity * 0.8)) // 0.12
                                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.microRadius))
                            }
                        }
                        .padding(.leading, DesignSystem.wide)
                    }
                }
                .padding(.vertical, DesignSystem.small)
            }
            
            Spacer()
            
            // 页脚
            Divider()
            Text(Localized.tr("report.footer"))
                .font(.caption2)
                .foregroundStyle(Color.appBorder)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(DesignSystem.huge)
        .frame(width: DesignSystem.Metrics.A4Width, height: DesignSystem.Metrics.A4Height) // 595, 842
        .background(Color.white)
    }
}
