// ZhiYuWatchView.swift
//
// 作者: Wang Chong
// 功能说明: Apple Watch 简易视图，展示知识库关键统计和最近页面
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
//   - 更新: 2026-05-04
// 日期: 2026-05-04
// 版权: Copyright © 2026 Wang Chong. All rights reserved.

import SwiftUI

// MARK: - 手表端专用颜色
private extension Color {
    static let watchAccent = Color.blue
    static let watchText = Color.primary
    static let watchSecondary = Color.secondary
}

// MARK: - 手表端简易统计视图
/// 手表端简易统计视图
/// 负责展示知识库的核心元数据统计（页面总数、字数）及最近更新记录
struct WatchKnowledgeStatsView: View {
    @State private var totalPages = 0
    @State private var totalWords = 0
    @State private var recentTitles: [String] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppUI.medium) {
                // 1. 页面总数环形图
                ZStack {
                    Circle()
                        .stroke(Color.watchAccent.opacity(AppUI.glassOpacity), lineWidth: AppUI.borderWidth * 3)
                        .frame(width: AppUI.huge * 2 + AppUI.small, height: AppUI.huge * 2 + AppUI.small)
                    
                    Circle()
                        .trim(from: 0, to: min(1.0, Double(totalPages) / 100.0))
                        .stroke(Color.watchAccent, style: StrokeStyle(lineWidth: AppUI.borderWidth * 3, lineCap: .round))
                        .frame(width: AppUI.huge * 2 + AppUI.small, height: AppUI.huge * 2 + AppUI.small)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: AppUI.atomic) {
                        Text("\(totalPages)")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.watchText)
                        Text(L.tr("watch.pages"))
                            .font(.caption2)
                            .foregroundStyle(Color.watchSecondary)
                    }
                }
                
                // 2. 总字数统计
                HStack(spacing: AppUI.small) {
                    VStack(spacing: AppUI.atomic) {
                        Text(formatNumber(totalWords))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.watchText)
                        Text(L.tr("watch.words"))
                            .font(.caption2)
                            .foregroundStyle(Color.watchSecondary)
                    }
                }
                
                Divider()
                
                // 3. 最近更新列表
                VStack(alignment: .leading, spacing: AppUI.tiny + AppUI.atomic) {
                    Text(L.tr("watch.recentUpdates"))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.watchSecondary)
                    
                    ForEach(recentTitles.prefix(5), id: \.self) { title in
                        HStack(spacing: AppUI.tiny + AppUI.atomic) {
                            Circle()
                                .fill(Color.watchAccent)
                                .frame(width: AppUI.tiny + AppUI.atomic / 2, height: AppUI.tiny + AppUI.atomic / 2)
                            Text(title)
                                .font(.caption2)
                                .foregroundStyle(Color.watchText)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppUI.small)
        }
        .navigationTitle("ZhiYu")
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        let defaults = UserDefaults.standard
        totalPages = defaults.integer(forKey: "watch_totalPages")
        totalWords = defaults.integer(forKey: "watch_totalWords")
        recentTitles = defaults.stringArray(forKey: "watch_recentTitles") ?? []
    }
    
    private func formatNumber(_ n: Int) -> String {
        if n >= 10000 {
            return String(format: "%.1f" + L.tr("watch.tenThousand"), Double(n) / 10000.0)
        } else if n >= 1000 {
            return String(format: "%.1fk", Double(n) / 1000.0)
        }
        return "\(n)"
    }
}

// MARK: - 本地化助手 (手表端精简版)
private enum L {
    static func tr(_ key: String) -> String {
        let table: [String: String] = [
            "watch.pages": "页面",
            "watch.words": "字",
            "watch.recentUpdates": "最近更新",
            "watch.tenThousand": "万",
        ]
        return table[key] ?? key
    }
}
