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
    @State private var previewText: String?
    @State private var showTextPreview = false
    @State private var quickLookURL: URL?
    @State private var showQuickLook = false
    @Environment(Router.self) var router
    var onAITag: ((ImportRecord) -> Void)?

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
            AppSectionHeader(title: L10n.Ingest.importRecords, icon: "arrow.down.doc")

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
            } else if selectedCategory == "all" {
                tagGroupedList
            } else {
                flatCardList(records)
            }
        }
        .sheet(isPresented: $showTextPreview) {
            NavigationStack {
                ScrollView {
                    Text(previewText ?? "")
                        .font(.body.monospaced())
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .navigationTitle(L10n.Ingest.rawContentTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(L10n.Common.close) { showTextPreview = false }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showQuickLook) {
            if let url = quickLookURL {
                QuickLookPreview(fileURL: url)
            }
        }
        .task { await loadRecords() }
        .onChange(of: selectedCategory) { _, _ in Task { await loadRecords() } }
    }

    // MARK: - 预览分发

    private func previewContent(_ record: ImportRecord) {
        // 文件 → QuickLook（含链接导入的 .md、文件导入的原始文件）
        if let path = record.filePath, FileManager.default.fileExists(atPath: path) {
            quickLookURL = URL(fileURLWithPath: path)
            showQuickLook = true
            return
        }
        // 链接 → Safari（仅当无本地文件时）
        if let urlStr = record.sourceURL, let url = URL(string: urlStr) {
            #if os(iOS)
            UIApplication.shared.open(url)
            #endif
            return
        }
        // 文本 → Sheet
        if record.rawText != nil {
            previewText = record.rawText
            showTextPreview = true
            return
        }
    }

    // MARK: - 标签分组（仅在"全部"tab）

    private var tagGroupedList: some View {
        let grouped = ImportRecordTagGrouper.group(records, untaggedLabel: L10n.Ingest.untagged)
        return VStack(spacing: DesignSystem.small) {
            ForEach(grouped.keys.sorted(), id: \.self) { tag in
                VStack(alignment: .leading, spacing: DesignSystem.tightPadding) {
                    Text(tag)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.appAccent)
                        .padding(.horizontal, DesignSystem.tiny)
                    flatCardList(grouped[tag] ?? [])
                }
            }
        }
    }

    // MARK: - 平铺列表

    private func flatCardList(_ items: [ImportRecord]) -> some View {
        ForEach(items, id: \.id) { record in
            ImportRecordCard(
                record: record,
                onTap: { previewContent(record) },
                onViewPage: {
                    guard let pageID = record.pageID, let uuid = UUID(uuidString: pageID) else { return }
                    router.navigateToPage(id: uuid)
                },
                onOpenWith: {
                    guard let path = record.filePath else { return }
                    let fileURL = URL(fileURLWithPath: path)
                    #if os(iOS)
                    let controller = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let root = scene.windows.first?.rootViewController {
                        root.present(controller, animated: true)
                    }
                    #endif
                },
                onAITag: { onAITag?(record) }
            )
        }
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
