//
//  PageDetailMetadataSection.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：仪表盘：页面列表、知识统计、每周洞察、回链视图。
//
import SwiftUI

/// 页面详情元数据展示区
struct PageDetailMetadataSection: View {
    let page: KnowledgePage
    let backlinks: [KnowledgePage]
    let recommendations: [KnowledgePage]
    
    var body: some View {
        VStack(spacing: 0) {
            provenanceSection
            semanticRecommendationsSection
            backlinksSection
        }
    }
    
    private var provenanceSection: some View {
        Group {
            if let sourceURL = page.sourceURL, let url = URL(string: sourceURL) {
                VStack(alignment: .leading, spacing: DesignSystem.tightPadding) {
                    HStack {
                        Image(systemName: DesignSystem.Icons.safari).foregroundStyle(.appAccent)
                        Text(L10n.Knowledge.Page.Source.title).font(.headline).foregroundStyle(.appText)
                        Spacer()
                        Link(destination: url) {
                            HStack(spacing: DesignSystem.tiny) {
                                Text(L10n.Knowledge.Page.Source.open)
                                Image(systemName: DesignSystem.Icons.arrowUpRightCircle)
                            }
                            .font(.caption)
                            .foregroundStyle(.appAccent)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.tightPadding) {
                        Text(sourceURL).font(.caption2).foregroundStyle(.appSecondary).lineLimit(1).truncationMode(.middle)
                        
                        if let snippet = page.rawTextSnippet, !snippet.isEmpty {
                            Text(snippet).font(.caption).foregroundStyle(.appSecondary).padding(DesignSystem.small).frame(maxWidth: .infinity, alignment: .leading).background(Color.appCard).clipShape(RoundedRectangle(cornerRadius: DesignSystem.microRadius)).lineLimit(3)
                        }
                    }
                    .appContainer(padding: true)
                }
                .padding()
            }
        }
    }
    
    private var semanticRecommendationsSection: some View {
        Group {
            if !recommendations.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.medium) {
                    HStack(spacing: DesignSystem.small) {
                        ZStack {
                            Circle().fill(Color.appAccent.opacity(0.1)).frame(width: 24, height: 24)
                            Image(systemName: DesignSystem.Icons.sparkles).font(.system(size: DesignSystem.iconTiny)).foregroundStyle(.appAccent)
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(L10n.Knowledge.Page.AI.insights).font(.headline).foregroundStyle(.appText)
                            Text(L10n.Knowledge.Page.AI.insightsDesc).font(.caption2).foregroundStyle(.appSecondary)
                        }
                    }
                    .padding(.bottom, DesignSystem.tiny)
                    
                    VStack(spacing: DesignSystem.tightPadding) {
                        ForEach(recommendations) { recPage in
                            recommendationRow(for: recPage)
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: DesignSystem.largeRadius).fill(Color.appAccent.opacity(0.03)))
                .overlay(RoundedRectangle(cornerRadius: DesignSystem.largeRadius).stroke(LinearGradient(colors: [.appAccent.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
                .padding()
            }
        }
    }
    
    private func recommendationRow(for recPage: KnowledgePage) -> some View {
        NavigationLink(value: AppRoute.pageDetail(id: recPage.id)) {
            HStack {
                Image(systemName: recPage.displayIcon).foregroundStyle(Color.fromModelColorName(recPage.pageType.colorName))
                VStack(alignment: .leading, spacing: DesignSystem.atomic) {
                    Text(recPage.title).font(.subheadline.weight(.medium))
                    let summaryText = String(recPage.content.prefix(60)) + "..."
                    Text(summaryText).font(.caption2).foregroundStyle(.appSecondary)
                }
                Spacer()
                Image(systemName: DesignSystem.Icons.forward).font(.caption2).foregroundStyle(.appSecondary)
            }
            .padding(DesignSystem.medium)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.tightPadding))
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.tightPadding).stroke(LinearGradient(colors: [.appAccent.opacity(0.3), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
    
    private var backlinksSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            HStack {
                Image(systemName: DesignSystem.Icons.link).foregroundStyle(.appAccent)
                Text(L10n.Knowledge.Page.backlinks).font(.headline).foregroundStyle(.appText)
                Text("(\(backlinks.count))").font(.subheadline).foregroundStyle(.appSecondary)
            }
            
            if backlinks.isEmpty {
                Text(L10n.Knowledge.Page.noBackLinks).font(.caption).foregroundStyle(.appSecondary).padding(.vertical, DesignSystem.small)
            } else {
                ForEach(backlinks) { linkedPage in
                    NavigationLink(value: AppRoute.pageDetail(id: linkedPage.id)) {
                        HStack(spacing: DesignSystem.medium) {
                            Image(systemName: linkedPage.displayIcon).foregroundStyle(Color.fromModelColorName(linkedPage.pageType.colorName)).frame(width: 28, height: 28).background(Color.fromModelColorName(linkedPage.pageType.colorName).opacity(DesignSystem.Opacity.glass)).clipShape(RoundedRectangle(cornerRadius: DesignSystem.microRadius))
                            Text(linkedPage.title).font(.subheadline).foregroundStyle(.appText)
                            Spacer()
                            Image(systemName: DesignSystem.Icons.forward).font(.caption2).foregroundStyle(.appSecondary)
                        }
                        .padding(.horizontal, DesignSystem.tightPadding).padding(.vertical, DesignSystem.small).background(Color.appCard).clipShape(RoundedRectangle(cornerRadius: DesignSystem.smallRadius))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.Knowledge.Page.backlinkAccessibility(linkedPage.title, linkedPage.pageType.displayName))
                    .accessibilityHint(L10n.Knowledge.Page.doubleTapToNavigate)
                }
            }
        }
        .padding()
    }
}
