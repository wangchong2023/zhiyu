// WidgetAndWatchViews.swift
//
// 作者: Wang Chong
// 功能说明: Lightweight view for Apple Watch showing key knowledge stats and recent pages
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI
import WidgetKit

#if !os(watchOS)
// MARK: - Apple Watch Quick View
/// Lightweight view for Apple Watch showing key knowledge stats and recent pages
struct WatchKnowledgeStatsView: View {
    @State private var totalPages = 0
    @State private var totalWords = 0
    @State private var recentTitles: [String] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppUI.medium) {
                // Stats circle
                ZStack {
                    Circle()
                        .stroke(Color.appAccent.opacity(AppUI.glassOpacity), lineWidth: AppUI.borderWidth * 3)
                        .frame(width: AppUI.huge * 2 + AppUI.small, height: AppUI.huge * 2 + AppUI.small)
                    
                    Circle()
                        .trim(from: 0, to: min(1.0, Double(totalPages) / 100.0))
                        .stroke(Color.appAccent, style: StrokeStyle(lineWidth: AppUI.borderWidth * 3, lineCap: .round))
                        .frame(width: AppUI.huge * 2 + AppUI.small, height: AppUI.huge * 2 + AppUI.small)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: AppUI.atomic) {
                        Text("\(totalPages)")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.appText)
                        Text(L10n.Widget.tr("pages"))
                            .font(.caption2)
                            .foregroundStyle(Color.appSecondary)
                    }
                }
                
                // Word count
                HStack(spacing: AppUI.small) {
                    VStack(spacing: AppUI.atomic) {
                        Text(formatNumber(totalWords))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.appText)
                        Text(L10n.Widget.tr("words"))
                            .font(.caption2)
                            .foregroundStyle(Color.appSecondary)
                    }
                }
                
                Divider()
                
                // Recent pages
                VStack(alignment: .leading, spacing: AppUI.tiny + AppUI.atomic) {
                    Text(L10n.Widget.tr("recentUpdates"))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.appSecondary)
                    
                    ForEach(recentTitles.prefix(5), id: \.self) { title in
                        HStack(spacing: AppUI.tiny + AppUI.atomic) {
                            Circle()
                                .fill(Color.appAccent)
                                .frame(width: AppUI.tiny + AppUI.atomic / 2, height: AppUI.tiny + AppUI.atomic / 2)
                            Text(title)
                                .font(.caption2)
                                .foregroundStyle(Color.appText)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppUI.small)
        }
        .navigationTitle(L10n.Widget.tr("title"))
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        let store = AppStore()
        store.loadFromDisk()
        totalPages = store.totalPages
        totalWords = store.totalWords
        recentTitles = store.pages
            .sorted { $0.updated > $1.updated }
            .prefix(5)
            .map { $0.title }
    }
    
    private func formatNumber(_ n: Int) -> String {
        if n >= 10000 {
            return String(format: "%.1f%@", Double(n) / 10000.0, L10n.Common.tr("unitTenThousand"))
        } else if n >= 1000 {
            return String(format: "%.1fk", Double(n) / 1000.0)
        }
        return "\(n)"
    }
}
#endif

// MARK: - Widget Preview Views (for development)
/// These views are designed for the Widget Extension target.
/// They read data directly from the shared JSON file.

struct AppWidgetPreview: View {
    let totalPages: Int
    let totalWords: Int
    let activeCount: Int
    let stubCount: Int
    let recentTitles: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppUI.small) {
            HStack {
                Image(systemName: "books.vertical.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.appAccent)
                Text(L10n.Widget.tr("title"))
                    .font(.caption.weight(.bold))
                Spacer()
                Text(Localized.trf("widget.pages", totalPages))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            HStack(spacing: AppUI.medium) {
                VStack(spacing: AppUI.atomic) {
                    Text("\(totalWords)").font(.caption.weight(.bold))
                    Text(L10n.Widget.tr("characters")).font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: AppUI.atomic) {
                    Text("\(activeCount)").font(.caption.weight(.bold))
                    Text(L10n.Widget.tr("active")).font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: AppUI.atomic) {
                    Text("\(stubCount)").font(.caption.weight(.bold))
                    Text(L10n.Widget.tr("stub")).font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            if !recentTitles.isEmpty {
                VStack(alignment: .leading, spacing: AppUI.tiny) {
                    Text(L10n.Widget.tr("recentUpdates"))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    ForEach(recentTitles, id: \.self) { title in
                        HStack(spacing: AppUI.tiny) {
                            Circle().fill(.purple).frame(width: AppUI.atomic * 2, height: AppUI.atomic * 2)
                            Text(title).font(.caption2).lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(AppUI.small)
    }
}

#Preview("Widget Medium") {
    AppWidgetPreview(
        totalPages: 9,
        totalWords: 4500,
        activeCount: 7,
        stubCount: 2,
        recentTitles: ["LLM 知识库", "nanoGPT", L10n.Widget.tr("knowledgeCompile")]
    )
}
