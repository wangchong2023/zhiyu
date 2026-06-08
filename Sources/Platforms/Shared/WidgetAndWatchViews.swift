//
//  WidgetAndWatchViews.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：SwiftUI 视图，负责 WidgetAndWatchs 界面的布局与渲染。
//
import SwiftUI
import WidgetKit

#if !os(watchOS)
// MARK: - Apple Watch Quick View
/// Lightweight view for Apple Watch showing key knowledge stats and recent pages
@MainActor
struct WatchKnowledgeStatsView: View {
    @State private var totalPages = 0
    @State private var totalWords = 0
    @State private var recentTitles: [String] = []
    
    /// 允许传入 Mock 数据的构造器
    public init(totalPages: Int = 0, totalWords: Int = 0, recentTitles: [String] = []) {
        self._totalPages = State(initialValue: totalPages)
        self._totalWords = State(initialValue: totalWords)
        self._recentTitles = State(initialValue: recentTitles)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.medium) {
                // Stats circle
                ZStack {
                    Circle()
                        .stroke(Color.appAccent.opacity(DesignSystem.glassOpacity), lineWidth: DesignSystem.borderWidth * 3)
                        .frame(width: DesignSystem.huge * 2 + DesignSystem.small, height: DesignSystem.huge * 2 + DesignSystem.small)
                    
                    Circle()
                        .trim(from: 0, to: min(1.0, Double(totalPages) / 100.0))
                        .stroke(Color.appAccent, style: StrokeStyle(lineWidth: DesignSystem.borderWidth * 3, lineCap: .round))
                        .frame(width: DesignSystem.huge * 2 + DesignSystem.small, height: DesignSystem.huge * 2 + DesignSystem.small)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: DesignSystem.atomic) {
                        Text("\(totalPages)")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.appText)
                        Text(L10n.Widget.pages)
                            .font(.caption2)
                            .foregroundStyle(Color.appSecondary)
                    }
                }
                
                // Word count
                HStack(spacing: DesignSystem.small) {
                    VStack(spacing: DesignSystem.atomic) {
                        Text(formatNumber(totalWords))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.appText)
                        Text(L10n.Widget.words)
                            .font(.caption2)
                            .foregroundStyle(Color.appSecondary)
                    }
                }
                
                Divider()
                
                // Recent pages
                VStack(alignment: .leading, spacing: DesignSystem.tiny + DesignSystem.atomic) {
                    Text(L10n.Widget.recentUpdates)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.appSecondary)
                    
                    ForEach(recentTitles.prefix(5), id: \.self) { title in
                        HStack(spacing: DesignSystem.tiny + DesignSystem.atomic) {
                            Circle()
                                .fill(Color.appAccent)
                                .frame(width: DesignSystem.tiny + DesignSystem.atomic / 2, height: DesignSystem.tiny + DesignSystem.atomic / 2)
                            Text(title)
                                .font(.caption2)
                                .foregroundStyle(Color.appText)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(DesignSystem.small)
        }
        .navigationTitle(L10n.Widget.title)
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        let defaults = UserDefaults.standard
        totalPages = defaults.integer(forKey: AppConstants.Keys.Storage.watchTotalPages)
        totalWords = defaults.integer(forKey: AppConstants.Keys.Storage.watchTotalWords)
        recentTitles = defaults.stringArray(forKey: AppConstants.Keys.Storage.watchRecentTitles) ?? []
    }
    
    private func formatNumber(_ n: Int) -> String {
        if n >= 10000 {
            return String(format: "%.1f%@", Double(n) / 10000.0, L10n.Common.unitTenThousand)
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
        VStack(alignment: .leading, spacing: DesignSystem.small) {
            HStack {
                Image(systemName: DesignSystem.Icons.libraryCircle)
                    .font(.title3)
                    .foregroundStyle(Color.appAccent)
                Text(L10n.Widget.title)
                    .font(.caption.weight(.bold))
                Spacer()
                Text(L10n.Widget.pages( totalPages))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            HStack(spacing: DesignSystem.medium) {
                VStack(spacing: DesignSystem.atomic) {
                    Text("\(totalWords)").font(.caption.weight(.bold))
                    Text(L10n.Widget.characters).font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: DesignSystem.atomic) {
                    Text("\(activeCount)").font(.caption.weight(.bold))
                    Text(L10n.Widget.active).font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: DesignSystem.atomic) {
                    Text("\(stubCount)").font(.caption.weight(.bold))
                    Text(L10n.Widget.stub).font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            if !recentTitles.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.tiny) {
                    Text(L10n.Widget.recentUpdates)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    ForEach(recentTitles, id: \.self) { title in
                        HStack(spacing: DesignSystem.tiny) {
                            Circle().fill(.purple).frame(width: DesignSystem.atomic * 2, height: DesignSystem.atomic * 2)
                            Text(title).font(.caption2).lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.small)
    }
}

#Preview(L10n.Common.unknown) {
    AppWidgetPreview(
        totalPages: 9,
        totalWords: 4500,
        activeCount: 7,
        stubCount: 2,
        recentTitles: [L10n.Common.unknown, "nanoGPT", L10n.Widget.knowledgeCompile]
    )
}
