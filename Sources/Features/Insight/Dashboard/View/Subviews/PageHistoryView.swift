// PageSnapshotHistoryView.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：页面快照历史视图，负责展示和管理页面的历史版本。
// 版本: 1.0
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI

/// 页面快照历史视图
struct PageHistoryView: View {
    let page: KnowledgePage
    @Environment(AppStore.self) var store
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var history: [SnapshotInfo] = []
    @State private var selectedSnapshot: SnapshotInfo?
    @State private var compareContent: String?
    
    var body: some View {
        NavigationStack {
            List {
                if history.isEmpty {
                    Text(Localized.tr("page.history.none"))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(history) { snapshot in
                        Button(action: {
                            selectedSnapshot = snapshot
                            compareContent = store.snapshotService.rollback(to: snapshot)
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(snapshot.date.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened, locale: Localized.currentLocale)))
                                        .font(.subheadline.weight(.medium))
                                    Text(Localized.tr("page.history.physical"))
                                        .font(.caption2)
                                        .foregroundStyle(.appSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.appBorder)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.pageBackground())
            .navigationTitle(Localized.tr("page.history"))
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(L10n.Common.tr("close")) { dismiss() }
                }
            }
            .sheet(item: $selectedSnapshot) { snapshot in
                SnapshotDetailView(page: page, snapshot: snapshot, content: compareContent ?? "", onRollback: {
                    var rolledBack = page
                    rolledBack.content = compareContent ?? ""
                    Task { await store.updatePage(rolledBack, forceDeepScan: false) }
                    dismiss()
                })
            }
        }
        .onAppear {
            history = store.snapshotService.getHistory(for: page.id)
        }
    }
}

private struct SnapshotDetailView: View {
    let page: KnowledgePage
    let snapshot: SnapshotInfo
    let content: String
    let onRollback: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label(Localized.tr("page.history.version"), systemImage: "clock")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.appAccent)
                            Spacer()
                            Text(snapshot.date.formatted(Date.FormatStyle(locale: Localized.currentLocale)))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.bottom, 8)
                        
                        MarkdownRendererView(content: content, isPrivate: page.isPrivate, onLinkTap: { _ in })
                    }
                    .padding()
                }
                
                Divider()
                
                HStack(spacing: 16) {
                    Button(action: { dismiss() }) {
                        Text(L10n.Common.tr("cancel"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onRollback) {
                        Text(Localized.tr("page.history.rollback"))
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle(Localized.tr("page.snapshot.preview"))
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .background(themeManager.pageBackground())
        }
    }
}
