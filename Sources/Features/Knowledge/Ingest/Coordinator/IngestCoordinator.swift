//
//  IngestCoordinator.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：负责 Ingest 业务流的导航路由与协作管理。
//
import SwiftUI
import Observation
import UniformTypeIdentifiers

@MainActor
@Observable
final class IngestCoordinator {
    // ── 基础设施依赖 ──
    @ObservationIgnored @Inject var store: AppStore
    @ObservationIgnored @Inject var ingestStore: IngestStore
    @ObservationIgnored @Inject var llmService: any LLMServiceProtocol
    @ObservationIgnored @Inject var importRecordRepo: any ImportRecordRepository

    // ── 频控 ──
    private let importCooldownSeconds = AppConstants.Keys.ImportLimits.importCooldownSeconds
    private var lastImportTime: Date = .distantPast

    // ── UI 控制状态 ──
    var isIngesting = false
    var isImporting: Bool {
        let elapsed = Date().timeIntervalSince(lastImportTime)
        return elapsed < importCooldownSeconds
    }
    var showManualForm = false
    var manualFormTitle = L10n.Ingest.manualEntry
    var showOCRScan = false
    var showURLImport = false
    var showFileImporter = false
    var showVoiceNote = false
    var errorMessage: String?
    var showError = false

    // ── 业务表单数据 ──
    var newTitle = ""
    var newContent = ""
    var newType: PageType = .source
    var newCustomIcon: String?
    var newURL = ""
    var useSmartIngest = false
    var sourceHint: ImportCategory = .manual
    var pendingImageData: Data?
    var pendingVoiceFileURL: URL?

    var isLLMConfigured: Bool {
        llmService.isEnabled && !llmService.apiKey.isEmpty
    }

    init() {}

    // MARK: - 原始内容文件存储

    /// 保存原始导入内容到磁盘文件，返回文件路径
    private nonisolated static func saveRawContentFile(content: String, category: ImportCategory, ext: String = "md") -> String? {
        guard let data = content.data(using: .utf8) else { return nil }
        return saveRawDataFile(data: data, category: category, ext: ext)
    }

    /// 保存原始二进制数据到磁盘文件，返回文件路径
    private nonisolated static func saveRawDataFile(data: Data, category: ImportCategory, ext: String) -> String? {
        let fm = FileManager.default
        guard let docDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let recordsDir = docDir.appendingPathComponent("import_records", isDirectory: true)
        try? fm.createDirectory(at: recordsDir, withIntermediateDirectories: true)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let ts = formatter.string(from: Date())
        let fileName = "\(category.rawValue)_\(ts).\(ext)"
        let fileURL = recordsDir.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL.path
        } catch {
            Logger.shared.error("[IngestCoordinator] 保存原始数据文件失败: \(error)", error: error)
            return nil
        }
    }

    // MARK: - 图片提取

    private let imageExtractor = ImageExtractor()

    /// 从网页 URL 提取图片并 OCR，返回追加的 Markdown 文本
    private func extractImagesFromURL(_ urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else { return "" }
        guard let (htmlData, _) = try? await URLSession.shared.data(from: url) else { return "" }
        guard let html = String(data: htmlData, encoding: .utf8) else { return "" }
        return await imageExtractor.extractImagesFromHTML(html, baseURL: url)
    }

    /// 从文件提取图片并 OCR（PDF/Office）
    private func extractImagesFromFile(url: URL) async -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case AppConstants.Keys.ImportLimits.pdfExtension:
            let pdfService = ServiceContainer.shared.resolve((any PDFServiceProtocol).self)
            return await imageExtractor.extractImagesFromPDF(at: url, pdfService: pdfService)
        case let ext where AppConstants.Keys.ImportLimits.officeExtensions.contains(ext):
            return await imageExtractor.extractImagesFromOfficeFile(at: url)
        default:
            return ""
        }
    }

    // ── 业务动作 ──

    /// 执行导入摄取
    func performIngest() {
        guard !isImporting else {
            ToastManager.shared.show(type: .info, message: L10n.Ingest.importCooldown)
            return
        }
        isIngesting = true
        lastImportTime = Date()
        let title = newTitle, content = newContent, type = newType, icon = newCustomIcon, smart = useSmartIngest
        let category = sourceHint.rawValue
        let recordID = UUID().uuidString
        let sourceName = sourceHint.displayName

        // rawText 以 Markdown 格式存储，带来源头
        let rawText = "> 来源：\(sourceName) | \(Date().formatted(date: .numeric, time: .shortened))\n\n\(content)"
        let textPath = Self.saveRawContentFile(content: rawText, category: sourceHint)

        // OCR：额外保存原始图片文件
        var imagePath: String?
        if sourceHint == .ocr, let imgData = pendingImageData {
            if imgData.count > AppConstants.Keys.ImportLimits.maxOCRImageSizeBytes {
                pendingImageData = nil
                isIngesting = false
                lastImportTime = .distantPast
                errorMessage = L10n.Ingest.imageTooLarge
                showError = true
                return
            }
            imagePath = Self.saveRawDataFile(data: imgData, category: .ocr, ext: "jpg")
            pendingImageData = nil
        }

        // 语音：录音已由 AVAudioRecorder 直接存入 Documents/import_records/
        var voicePath: String?
        if sourceHint == .voice, let audioURL = pendingVoiceFileURL {
            voicePath = audioURL.path
            pendingVoiceFileURL = nil
        }
        let savedPath = imagePath ?? voicePath ?? textPath

        // 创建导入记录
        let record = ImportRecord(
            id: recordID, category: category, title: title,
            status: ImportRecordStatus.processing, rawText: rawText,
            sourceURL: nil, filePath: savedPath,
            vaultID: VaultService.shared.selectedVaultID?.uuidString
        )
        Task { try? await importRecordRepo.save(record) }

        Task {
            do {
                let page = try await ingestStore.performIngest(
                    title: title,
                    content: content,
                    type: type,
                    tags: [],
                    customIcon: icon,
                    useSmart: smart,
                    useDeepScan: true
                )
                try? await importRecordRepo.updateStatus(id: recordID, status: ImportRecordStatus.done, completedAt: Date())
                try? await importRecordRepo.updatePageID(id: recordID, pageID: page.id.uuidString)

                if let icon = icon {
                    var updated = page
                    updated.customIcon = icon
                    await store.updatePage(updated, forceDeepScan: true)
                }

                await MainActor.run {
                    self.isIngesting = false
                    self.showManualForm = false
                    self.resetForm()
                    HapticFeedback.shared.trigger(.success)
                }
            } catch {
                try? await importRecordRepo.updateStatus(id: recordID, status: ImportRecordStatus.failed, completedAt: Date())
                await MainActor.run {
                    self.isIngesting = false
                    self.errorMessage = L10n.Ingest.importFailed
                    self.showError = true
                    HapticFeedback.shared.trigger(.error)
                }
            }
        }
    }

    /// 处理File导入
    /// - Parameter result: result
    func handleFileImport(_ result: Result<[URL], Error>) {
        guard !isImporting else {
            ToastManager.shared.show(type: .info, message: L10n.Ingest.importCooldown)
            return
        }
        if case .success(let urls) = result {
            for url in urls {
                _ = url.startAccessingSecurityScopedResource()
                let fileName = url.lastPathComponent
                lastImportTime = Date()
                let taskID = TaskCenter.shared.addTask(type: .ingest, name: L10n.Ingest.importingFile, target: fileName)
                let recordID = UUID().uuidString

                // 获取文件大小，超过限制则拒绝
                let fileSize: Int64? = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize.map(Int64.init)
                if let size = fileSize, size > AppConstants.Keys.ImportLimits.maxFileSizeBytes {
                    url.stopAccessingSecurityScopedResource()
                    lastImportTime = .distantPast
                    Task { @MainActor in
                        ToastManager.shared.show(type: .error, message: L10n.Ingest.fileTooLarge)
                    }
                    continue
                }

                // 对文本类文件读取原文作为 rawText（PDF 等二进制靠 filePath + QuickLook）
                let textContent: String? = {
                    let ext = url.pathExtension.lowercased()
                    guard ["md", "txt", "markdown", "rtf"].contains(ext) else { return nil }
                    return try? String(contentsOf: url, encoding: .utf8)
                }()

                let record = ImportRecord(
                    id: recordID, category: ImportCategory.file.rawValue,
                    title: fileName, status: ImportRecordStatus.processing,
                    rawText: textContent,
                    filePath: url.path, fileSize: fileSize,
                    vaultID: VaultService.shared.selectedVaultID?.uuidString
                )
                Task {
                    let existing = (try? await importRecordRepo.fetchAll(category: ImportCategory.file.rawValue, limit: 1000)) ?? []
                    if existing.contains(where: { $0.filePath == url.path && $0.status == ImportRecordStatus.done }) {
                        await MainActor.run {
                            ToastManager.shared.show(type: .info, message: L10n.Ingest.duplicateFile(fileName))
                        }
                        url.stopAccessingSecurityScopedResource()
                        return
                    }
                    try? await importRecordRepo.save(record)
                }

                Task {
                    defer { url.stopAccessingSecurityScopedResource() }
                    // 提取文档图片并 OCR
                    let ocrText = await extractImagesFromFile(url: url)
                    if !ocrText.isEmpty, var existingText = textContent {
                        existingText += ocrText
                        try? await importRecordRepo.updateRawText(id: recordID, rawText: existingText)
                    }
                    let page = await store.ingestService.ingestDocument(at: url, pageStore: store)
                    await MainActor.run {
                        if let page = page {
                            Task { @MainActor in
                                try? await importRecordRepo.updateStatus(id: recordID, status: ImportRecordStatus.done, completedAt: Date())
                                try? await importRecordRepo.updatePageID(id: recordID, pageID: page.id.uuidString)
                            }
                            TaskCenter.shared.updateTask(taskID, status: .completed)
                            HapticFeedback.shared.trigger(.success)
                        } else {
                            Task { @MainActor in
                                try? await importRecordRepo.updateStatus(id: recordID, status: ImportRecordStatus.failed, completedAt: Date())
                            }
                            TaskCenter.shared.updateTask(taskID, status: .failed(error: L10n.Ingest.importFailed))
                            HapticFeedback.shared.trigger(.error)
                        }
                    }
                }
            }
        } else if case .failure(let error) = result {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    /// 批量导入 URL
    func handleBatchURLImport(_ urls: [URL]) {
        guard !isImporting else {
            ToastManager.shared.show(type: .info, message: L10n.Ingest.importCooldown)
            return
        }
        showURLImport = false
        lastImportTime = Date()
        let total = urls.count
        var ok = 0, fail = 0

        Task {
            let scraper = WebScraperProcessor()
            let vaultID = VaultService.shared.selectedVaultID?.uuidString
            let completed = await withTaskGroup(of: (ok: Bool, idx: Int).self) { group in
                for (i, url) in urls.enumerated() {
                    group.addTask { [self] in
                        let urlString = url.absoluteString
                        let recordID = UUID().uuidString
                        let rawResult = try? await scraper.fetchMarkdown(from: urlString)
                        let rawBody = rawResult.map { "> 来源链接：\(urlString)\n> 抓取时间：\(Date().formatted(date: .numeric, time: .shortened))\n\n\($0.markdown)" }
                        let ocrText = (try? await self.extractImagesFromURL(urlString)) ?? ""
                        let rawMarkdown = rawBody.map { $0 + ocrText }
                        let filePath = rawMarkdown.flatMap { Self.saveRawContentFile(content: $0, category: .link) }
                        let title = rawResult?.title ?? urlString
                        let record = ImportRecord(
                            id: recordID, category: ImportCategory.link.rawValue,
                            title: title, status: ImportRecordStatus.processing,
                            rawText: rawMarkdown, sourceURL: urlString, filePath: filePath,
                            vaultID: vaultID
                        )
                        try? await self.importRecordRepo.save(record)
                        let page = try? await self.store.ingestService.ingestURL(urlString: urlString, pageStore: self.store)
                        if let page = page {
                            try? await self.importRecordRepo.updateStatus(id: recordID, status: ImportRecordStatus.done, completedAt: Date())
                            try? await self.importRecordRepo.updatePageID(id: recordID, pageID: page.id.uuidString)
                            return (true, i)
                        } else {
                            try? await self.importRecordRepo.updateStatus(id: recordID, status: ImportRecordStatus.failed, completedAt: Date())
                            return (false, i)
                        }
                    }
                }
                var results = [(ok: Bool, idx: Int)]()
                for await r in group { results.append(r) }
                return results
            }
            let ok = completed.filter(\.ok).count
            let fail = completed.count - ok
            await MainActor.run {
                ToastManager.shared.show(type: ok > 0 ? .success : .error, message: L10n.Ingest.batchResult(ok, fail))
            }
        }
    }

    /// AI 标签与分类
    func triggerAITagging(for record: ImportRecord) {
        guard let rawText = record.rawText, !rawText.isEmpty,
              llmService.isEnabled, !llmService.apiKey.isEmpty else { return }
        let id = record.id
        Task {
            await MainActor.run {
                ToastManager.shared.show(type: .info, message: L10n.Ingest.aiTagging)
            }
            let snippet = String(rawText.prefix(AppConstants.Keys.ImportLimits.aiTagSnippetLength))
            let prompt = L10n.Ingest.aiTagPrompt(snippet)
            do {
                let result = try await llmService.chat(query: prompt, history: [], pages: [])
                let json = extractJSON(from: result.content)
                if let tags = json["tags"] as? [String], !tags.isEmpty {
                    try? await importRecordRepo.updateTags(id: id, tags: tags.joined(separator: ", "))
                }
                if let alias = json["aliasTitle"] as? String, !alias.isEmpty {
                    if var r = try? await importRecordRepo.fetchByID(id) {
                        r.title = alias
                        try? await importRecordRepo.save(r)
                    }
                }
                await MainActor.run {
                    ToastManager.shared.show(type: .success, message: L10n.Ingest.aiTagSuccess)
                }
            } catch {
                await MainActor.run {
                    ToastManager.shared.show(type: .error, message: L10n.Ingest.aiTagFailed)
                }
            }
        }
    }

    /// 从 LLM 返回文本中提取 JSON
    private func extractJSON(from text: String) -> [String: Any] {
        let stripped = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let start = stripped.firstIndex(of: "{"),
              let end = stripped.lastIndex(of: "}"),
              start < end else { return [:] }
        let jsonStr = String(stripped[start...end])
        guard let data = jsonStr.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [:] }
        return obj
    }

    /// 执行Clipboard导入
    func performClipboardImport() {
        if let content = AppPasteboard.string, !content.isEmpty {
            self.sourceHint = .clipboard
            self.newTitle = String(content.prefix(20))
            self.newContent = content
            self.manualFormTitle = L10n.Ingest.clipboardImport
            self.showManualForm = true
        }
    }

    /// 重置Form
    func resetForm() {
        newTitle = ""
        newContent = ""
        newCustomIcon = nil
        useSmartIngest = false
    }
}
