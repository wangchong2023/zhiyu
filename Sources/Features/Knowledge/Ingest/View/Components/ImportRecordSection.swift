//
//  ImportRecordSection.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/10.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L3] 表现层
//  核心职责：导入原始内容分段 Tab + 卡片列表区域

import SwiftUI

struct ImportRecordSection: View {
    @State private var selectedCategory: String = "all"
    @State private var records: [ImportRecord] = []
    @State private var previewText: String?
    @State private var previewFilePath: String?
    @State private var showTextPreview = false
    @State private var quickLookURL: URL?
    @State private var showQuickLook = false
    @Environment(Router.self) var router
    var onAITag: ((ImportRecord) -> Void)?
    var onManualEdit: ((ImportRecord) -> Void)?

    @Inject private var repo: any ImportRecordRepository
    @Inject private var urlOpener: any URLOpenerProtocol
    @Inject private var shareSheet: any ShareSheetProtocol

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
                Group {
                    if let path = previewFilePath {
                        FileTextPreviewView(filePath: path)
                    } else {
                        ScrollView {
                            Text(previewText ?? "")
                                .font(.body.monospaced())
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
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

    /// 校验是否是纯文本文件后缀
    private func isTextFile(path: String) -> Bool {
        let textExtensions = ["txt", "md", "json", "csv", "js", "py", "html", "xml", "css", "log", "swift", "yaml", "yml"]
        let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
        return textExtensions.contains(ext)
    }

    /// 预览导入的原始内容
    /// - Parameter record: 导入记录实体
    private func previewContent(_ record: ImportRecord) {
        // 对于用户手工录入的记录，优先分派编辑事件以拉起表单
        if record.category == ImportCategory.manual.rawValue {
            onManualEdit?(record)
            return
        }

        // 优先处理本地磁盘文件
        if let path = record.filePath, FileManager.default.fileExists(atPath: path) {
            if isTextFile(path: path) {
                // 流式异步分块加载预览，避免 ANR/OOM
                previewFilePath = path
                previewText = nil
                showTextPreview = true
                return
            }
            
            // 降级处理：非纯文本二进制文件（如 PDF、图片）则通过 QuickLook 预览
            quickLookURL = URL(fileURLWithPath: path)
            showQuickLook = true
            return
        }
        // 链接 → 浏览器（仅当无本地文件时）
        if let urlStr = record.sourceURL, let url = URL(string: urlStr) {
            Task { await urlOpener.open(url) }
            return
        }
        // 文本 → Sheet
        if let rawText = record.rawText {
            previewText = rawText
            previewFilePath = nil
            showTextPreview = true
            return
        }
        // 回退：无原始内容可预览时，若有关联页面则导航过去
        if let pageID = record.pageID, let uuid = UUID(uuidString: pageID), record.status == ImportRecordStatus.done {
            router.navigateToPage(id: uuid)
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
                    flatCardList(grouped[tag] ?? [], groupTag: tag)
                }
            }
        }
    }

    // MARK: - 平铺列表

    /// 包装结构体，为 SwiftUI 提供结合 tag 分组的联合唯一 ID，避免 ID 重复导致手势分发失效
    fileprivate struct GroupedRecord: Identifiable {
        let record: ImportRecord
        let tag: String
        var id: String { "\(tag)-\(record.id)" }
    }

    /// 平铺渲染卡片列表
    /// - Parameters:
    ///   - items: 待显示的导入记录数组
    ///   - groupTag: 当前的分组标签，用于防止重复 ID
    private func flatCardList(_ items: [ImportRecord], groupTag: String = "") -> some View {
        let groupedItems = items.map { GroupedRecord(record: $0, tag: groupTag) }
        return ForEach(groupedItems) { wrapper in
            let record = wrapper.record
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
                    Task { await shareSheet.presentShareSheet(items: [fileURL]) }
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
