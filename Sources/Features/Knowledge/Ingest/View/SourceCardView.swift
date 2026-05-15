// SourceCardView.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：知识来源展示卡片组件。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

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
                Text(L10n.Common.trf("wordCount", page.wordCount)).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(.appSecondary)
            }
        }.padding(DesignSystem.medium).frame(width: DesignSystem.Metrics.sourceCardWidth, height: DesignSystem.Metrics.sourceCardHeight).appMetricCardStyle(color: Color.fromModelColorName(page.pageType.colorName), cornerRadius: DesignSystem.standardRadius)
    }
}
