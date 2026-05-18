// WatchContentView.swift
//
// 作者: Wang Chong
// 功能说明: [Shared] ZhiYuWatch 主界面 (Apple Watch)
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
// 日期: 2026-05-04
// 版权: Copyright © 2026 Wang Chong. All rights reserved.

import SwiftUI

// MARK: - 手表端主视图
/// Apple Watch 核心内容视图
/// 负责在手表端展示最近更新的知识页面，并提供语音采集（Dictation）的入口
struct WatchContentView: View {
    @Environment(AppStore.self) var store
    @State private var isShowingDictation = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text(L10n.Watch.recents)) {
                    let recentPages = Array(store.pages.sorted(by: { $0.updatedAt > $1.updatedAt }).prefix(5))
                    ForEach(recentPages) { page in
                        NavigationLink(value: page) {
                            HStack {
                                let icon = page.displayIcon
                                Image(systemName: icon)
                                    .foregroundStyle(Color.appAccent)
                                    .accessibilityHidden(true)
                                Text(page.title)
                                    .font(.caption.weight(.medium))
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(page.title)
                        }
                    }
                }
                
                Section {
                    Button(action: { isShowingDictation = true }) {
                        Label(L10n.Watch.capture, systemImage: "mic.fill")
                            .foregroundStyle(.appAccent)
                    }
                }
            }
            .navigationTitle(L10n.Common.appName)
            .navigationDestination(for: KnowledgePage.self) { page in
                WatchPageDetailView(page: page)
            }
            .sheet(isPresented: $isShowingDictation) {
                WatchDictationView()
            }
        }
    }
}

/// 手表端页面详情
struct WatchPageDetailView: View {
    let page: KnowledgePage
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(page.title)
                    .font(.headline)
                    .foregroundStyle(.appAccent)
                
                Divider()
                
                // 手表端仅显示摘要或精简内容
                Text(String(page.content.prefix(200)) + "...")
                    .font(.caption2)
            }
            .padding()
        }
    }
}
