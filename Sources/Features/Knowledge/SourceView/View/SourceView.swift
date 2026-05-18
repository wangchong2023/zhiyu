// SourceView.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：信源视图，对标 NotebookLM 的信源面板
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

struct SourceView: View {
    @State private var sourceStore = SourceStore.shared
    @Environment(Router.self) var router
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            
            if sourceStore.activeSources.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignSystem.medium) {
                        ForEach(sourceStore.activeSources) { source in
                            SourceRow(source: source) { pageID in
                                // 跳转到原文
                                router.navigate(to: .pageDetail(id: pageID))
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .background(PageBackgroundView(accentColor: .appAccent))
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(Localized.tr("source.view.title", table: "Plugin"))
                    .font(.headline)
                    .foregroundStyle(.appText)
                Text(Localized.tr("source.view.subtitle", table: "Plugin"))
                    .font(.caption2)
                    .foregroundStyle(.appSecondary)
            }
            Spacer()
            
            Button(action: { sourceStore.clear() }) {
                Image(systemName: DesignSystem.Icons.delete)
                    .font(.caption)
                    .foregroundStyle(.appSecondary)
            }
        }
        .padding()
        .background(Color.appCard.opacity(DesignSystem.glassOpacity))
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: DesignSystem.Icons.quoteOpening)
                .font(.system(size: 40))
                .foregroundStyle(.appSecondary.opacity(0.3))
            
            Text(Localized.tr("source.view.empty", table: "Plugin"))
                .font(.subheadline)
                .foregroundStyle(.appSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
