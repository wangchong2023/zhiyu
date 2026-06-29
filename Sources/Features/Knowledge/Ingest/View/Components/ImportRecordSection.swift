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

    private func previewContent(_ record: ImportRecord, forceRaw: Bool = false) {
        let handler = ImportPreviewHandler(urlOpener: urlOpener, shareSheet: shareSheet, router: router)
        let action = handler.resolveAction(for: record, forceRaw: forceRaw)
        
        print("DEBUG_INGEST: ClickedRecordTitle=\(record.title), ResolvedAction=\(action)")
        
        switch action {
        case .navigateToPage(let uuid):
            router.navigateToPage(id: uuid)
        case .manualEdit:
            onManualEdit?(record)
        case .localTextFile(let path):
            previewFilePath = path
            previewText = nil
            showTextPreview = true
        case .localBinaryFile(let url):
            quickLookURL = url
            showQuickLook = true
        case .openURL(let url):
            Task { await urlOpener.open(url) }
        case .rawTextPreview(let text):
            previewText = text
            previewFilePath = nil
            showTextPreview = true
        case .none:
            break
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
                onPreview: { previewContent(record, forceRaw: true) },
                onOpenWith: {
                    guard let path = record.filePath else { return }
                    let fileURL = URL(fileURLWithPath: path)
                    Task { await shareSheet.presentShareSheet(items: [fileURL]) }
                },
                onEdit: { onManualEdit?(record) }
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

// MARK: - 预览动作分发处理器（支持单元测试）

enum PreviewAction: Equatable {
    case navigateToPage(id: UUID)
    case manualEdit
    case localTextFile(path: String)
    case localBinaryFile(url: URL)
    case openURL(url: URL)
    case rawTextPreview(text: String)
    case none
}

struct ImportPreviewHandler {
    let urlOpener: any URLOpenerProtocol
    let shareSheet: any ShareSheetProtocol
    let router: Router
    
    /// 根据导入记录的状态和内容，决定预览分发动作
    func resolveAction(for record: ImportRecord, forceRaw: Bool = false, fileExists: (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }) -> PreviewAction {
        // 1. 优先：若有成功关联的知识页面，且非强预览类（文件/OCR/语音），则直接跳转至页面详情
        let isForcePreviewCategory = record.category == ImportCategory.file.rawValue ||
                                     record.category == ImportCategory.ocr.rawValue ||
                                     record.category == ImportCategory.voice.rawValue
        
        if !forceRaw && !isForcePreviewCategory, let pageID = record.pageID, let uuid = UUID(uuidString: pageID), record.status == ImportRecordStatus.done {
            return .navigateToPage(id: uuid)
        }

        // 2. 对于用户手工录入的记录，优先分派编辑事件以拉起表单
        if !forceRaw, record.category == ImportCategory.manual.rawValue {
            return .manualEdit
        }

        // 3. 处理本地磁盘文件
        if let path = record.filePath, fileExists(path) {
            if isTextFile(path: path) {
                return .localTextFile(path: path)
            }
            return .localBinaryFile(url: URL(fileURLWithPath: path))
        }
        
        // 4. 链接 → 浏览器
        if let urlStr = record.sourceURL, let url = URL(string: urlStr) {
            return .openURL(url: url)
        }
        
        // 5. 文本 → 兜底弹窗预览
        if let rawText = record.rawText {
            return .rawTextPreview(text: rawText)
        }
        
        return .none
    }
    
    private func isTextFile(path: String) -> Bool {
        let textExtensions = ["txt", "md", "json", "csv", "js", "py", "html", "xml", "css", "log", "swift", "yaml", "yml"]
        let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
        return textExtensions.contains(ext)
    }
}
