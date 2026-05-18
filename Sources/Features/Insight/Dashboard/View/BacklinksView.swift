// BacklinksView.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：struct BacklinksView
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
//   - 更新: 2026-05-03
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

struct BacklinksView: View {
    let page: KnowledgePage
    @Environment(AppStore.self) var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var backlinks: [KnowledgePage] = []
    @State private var outgoingPages: [KnowledgePage] = []
    @State private var isLoading = true
    
    private func fetchData() async {
        isLoading = true
        let bl = await store.getBacklinks(for: page.id)
        
        var op: [KnowledgePage] = []
        for title in page.outgoingLinks {
            if let p = await store.pageByTitle(title) {
                op.append(p)
            }
        }
        
        await MainActor.run {
            self.backlinks = bl
            self.outgoingPages = op
            self.isLoading = false
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Outgoing links
                Section {
                    if outgoingPages.isEmpty {
                        Text(L10n.Components.noOutgoing)
                            .font(.caption)
                            .foregroundStyle(.appSecondary)
                    } else {
                        ForEach(outgoingPages) { linkedPage in
                            HStack(spacing: 10) {
                                Image(systemName: DesignSystem.Icons.arrowRight)
                                    .font(.caption)
                                    .foregroundStyle(.appAccent)
                                
                                Image(systemName: linkedPage.displayIcon)
                                    .foregroundStyle(Color.fromModelColorName(linkedPage.pageType.colorName))
                                    .frame(width: 28, height: 28)
                                    .background(Color.fromModelColorName(linkedPage.pageType.colorName).opacity(DesignSystem.Opacity.glass))
                                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.microRadius))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(linkedPage.title)
                                        .font(.subheadline)
                                        .foregroundStyle(.appText)
                                    Text(linkedPage.pageType.displayName)
                                        .font(.caption2)
                                        .foregroundStyle(.appSecondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    HStack {
                        Image(systemName: DesignSystem.Icons.arrowRight)
                        Text(L10n.Vault.Backlinks.outgoing( outgoingPages.count))
                    }
                }
                
                // Backlinks
                Section {
                    if backlinks.isEmpty {
                        Text(L10n.Components.noBackLinks)
                            .font(.caption)
                            .foregroundStyle(.appSecondary)
                    } else {
                        ForEach(backlinks) { linkingPage in
                            HStack(spacing: 10) {
                                Image(systemName: DesignSystem.Icons.arrowLeft)
                                    .font(.caption)
                                    .foregroundStyle(.appComparison)
                                
                                Image(systemName: linkingPage.displayIcon)
                                    .foregroundStyle(Color.fromModelColorName(linkingPage.pageType.colorName))
                                    .frame(width: 28, height: 28)
                                    .background(Color.fromModelColorName(linkingPage.pageType.colorName).opacity(DesignSystem.Opacity.glass))
                                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.microRadius))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(linkingPage.title)
                                        .font(.subheadline)
                                        .foregroundStyle(.appText)
                                    Text(linkingPage.pageType.displayName)
                                        .font(.caption2)
                                        .foregroundStyle(.appSecondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    HStack {
                        Image(systemName: DesignSystem.Icons.arrowLeft)
                        Text(L10n.Vault.Backlinks.count( backlinks.count))
                    }
                }
            }
#if os(iOS)
            .listStyle(.insetGrouped)
#endif
            .scrollContentBackground(.hidden)
            .background(PageBackgroundView(accentColor: .appAccent))
            .navigationTitle(page.title)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .task {
                await fetchData()
            }
        }
    }
}
