//
//  SourceCardView.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：构建 SourceCard 界面的 UI 视图层组件。
//
import SwiftUI

struct SourceCardView: View {
    let page: KnowledgePage
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.tightPadding) {
            HStack {
                ZStack {
                    Circle().fill(Color.fromModelColorName(page.pageType.colorName).opacity(DesignSystem.glassOpacity * 1.2)).frame(width: DesignSystem.Metrics.smallIconBoxSize, height: DesignSystem.Metrics.smallIconBoxSize)
                    Image(systemName: page.pageType.icon).font(.system(size: DesignSystem.iconTiny, weight: .bold)).foregroundStyle(Color.fromModelColorName(page.pageType.colorName))
                }
                Spacer()
                if let url = page.sourceURL { Image(systemName: url.contains("http") ? "link" : "doc.fill").font(.system(size: DesignSystem.iconTiny - DesignSystem.atomic)).foregroundStyle(.appSecondary.opacity(DesignSystem.dimmedOpacity)) }
            }
            Text(page.title).font(.system(size: DesignSystem.captionFontSize + DesignSystem.atomic / 2, weight: .bold)).lineLimit(2).foregroundStyle(.appText)
            Spacer()
            HStack {
                Text(page.createdAt.formatted(.relative(presentation: .named).locale(Localized.currentLocale))).font(.system(size: DesignSystem.microFontSize)).foregroundStyle(.appSecondary)
                Spacer()
                Text(L10n.Knowledge.Page.wordCount(page.wordCount)).font(.caption2.weight(.medium)).foregroundStyle(.appSecondary)
            }
        }.padding(DesignSystem.medium).frame(width: DesignSystem.Metrics.sourceCardWidth, height: DesignSystem.Metrics.sourceCardHeight).appMetricCardStyle(color: Color.fromModelColorName(page.pageType.colorName), cornerRadius: DesignSystem.standardRadius)
    }
}