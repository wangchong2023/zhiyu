//
//  ImportRecordSection.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/10.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：导入原始内容分段 Tab + 卡片列表区域

import SwiftUI

struct ImportRecordSection: View {
    @State private var selectedCategory: String = "all"
    @State private var records: [ImportRecord] = []

    @Inject private var repo: any ImportRecordRepository

    private let tabs: [(key: String, label: String)] = {
        var items: [(String, String)] = [("all", L10n.Ingest.importAll)]
        for cat in ImportCategory.allCases {
            items.append((cat.rawValue, cat.displayName))
        }
        return items
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.medium) {
            Label(L10n.Ingest.importRecords, systemImage: "archivebox")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.small) {
                    ForEach(tabs, id: \.key) { tab in
                        categoryTab(tab.key, tab.label)
                    }
                }
            }

            if records.isEmpty {
                Text(L10n.Ingest.noImportRecords)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, DesignSystem.large)
                    .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: DesignSystem.small) {
                    ForEach(records, id: \.id) { record in
                        ImportRecordCard(record: record)
                    }
                }
            }
        }
        .task { await loadRecords() }
        .onChange(of: selectedCategory) { _, _ in Task { await loadRecords() } }
    }

    private func categoryTab(_ key: String, _ label: String) -> some View {
        let selected = selectedCategory == key
        return Button(action: { selectedCategory = key }) {
            Text(label)
                .font(.caption.weight(selected ? .semibold : .regular))
                .padding(.horizontal, DesignSystem.medium)
                .padding(.vertical, DesignSystem.tightPadding)
                .background(selected ? Capsule().fill(Color.appAccent) : Capsule().fill(Color.appCard))
                .foregroundStyle(selected ? .white : .secondary)
        }
    }

    private func loadRecords() async {
        let cat: String? = selectedCategory == "all" ? nil : selectedCategory
        records = (try? await repo.fetchAll(category: cat, limit: 50)) ?? []
    }
}
