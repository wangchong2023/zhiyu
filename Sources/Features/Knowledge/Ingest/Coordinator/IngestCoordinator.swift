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

    // MARK: - 图片提取

    private let imageExtractor = ImageExtractor()
    @ObservationIgnored @Inject private var fileStore: any ImportFileStore

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
        let recordID = UUID().uuidString

        // 1. 保存多媒体及文本的本地临时文件
        guard let prep = prepareImportFiles(recordID: recordID) else {
            return
        }

        let title = newTitle
        let content = newContent
        let type = newType
        let icon = newCustomIcon
        let smart = useSmartIngest
        let category = sourceHint.rawValue

        // 2. 创建本地历史导入记录
        let record = ImportRecord(
            id: recordID, category: category, title: title,
            status: ImportRecordStatus.processing, rawText: prep.rawText,
            sourceURL: nil, filePath: prep.savedPath,
            vaultID: VaultService.shared.selectedVaultID?.uuidString
        )
        Task { try? await importRecordRepo.save(record) }

        // 3. 执行真正的知识库写入及双链提取
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

    /// 预备保存导入的多媒体及文本文件
    /// - Parameter recordID: 导入记录唯一标识
    /// - Returns: 返回保存的路径和带有来源信息的原始文本内容，如果因大小超限失败则返回 nil
    private func prepareImportFiles(recordID: String) -> (savedPath: String?, rawText: String)? {
        let content = newContent
        let sourceName = sourceHint.displayName
        
        // rawText 以 Markdown 格式存储，带来源头
        let rawText = "> \(L10n.Ingest.sourcePrefix)\(sourceName) | \(Date().formatted(date: .numeric, time: .shortened))\n\n\(content)"
        let textPath = fileStore.saveContent(rawText, category: sourceHint, ext: "md")

        // OCR：额外保存原始图片文件
        if sourceHint == .ocr, let imgData = pendingImageData {
            if imgData.count > AppConstants.Keys.ImportLimits.maxOCRImageSizeBytes {
                pendingImageData = nil
                isIngesting = false
                lastImportTime = .distantPast
                errorMessage = L10n.Ingest.imageTooLarge
                showError = true
                return nil
            }
            _ = fileStore.saveData(imgData, category: .ocr, ext: "jpg")
            pendingImageData = nil
        }

        return (textPath, rawText)
    }

    /// 处理File导入
    /// - Parameter result: 导入结果元组
    func handleFileImport(_ result: Result<[URL], Error>) {
        guard !isImporting else {
            ToastManager.shared.show(type: .info, message: L10n.Ingest.importCooldown)
            return
        }
        switch result {
        case .success(let urls):
            for url in urls {
                importSingleFile(at: url)
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    /// 处理单个本地文档文件的安全导入与 OCR 处理
    /// - Parameter url: 文档文件的沙盒 URL 路径
    private func importSingleFile(at url: URL) {
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
            return
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
            
            // 异步执行后续的文件导入任务
            executeImportTask(at: url, recordID: recordID, textContent: textContent, taskID: taskID)
        }
    }

    /// 异步执行文件导入的后台任务，包括 OCR 提取及最终文档摄入
    /// - Parameters:
    ///   - url: 文档文件的沙盒 URL
    ///   - recordID: 导入记录的唯一标识
    ///   - textContent: 文件已有的原始文本内容
    ///   - taskID: 关联的任务 ID
    private func executeImportTask(
        at url: URL,
        recordID: String,
        textContent: String?,
        taskID: UUID
    ) {
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

    /// 批量导入 URL
    func handleBatchURLImport(_ urls: [URL]) {
        guard !isImporting else {
            ToastManager.shared.show(type: .info, message: L10n.Ingest.importCooldown)
            return
        }
        showURLImport = false
        lastImportTime = Date()

        Task {
            let scraper = WebScraperProcessor()
            let vaultID = VaultService.shared.selectedVaultID?.uuidString
            let store = fileStore
            let completed = await withTaskGroup(of: (ok: Bool, idx: Int).self) { group in
                for (i, url) in urls.enumerated() {
                    group.addTask { [self] in
                        let urlString = url.absoluteString
                        let recordID = UUID().uuidString
                        let rawResult = try? await scraper.fetchMarkdown(from: urlString)
                        let rawBody = rawResult.map { "> \(L10n.Ingest.urlSourcePrefix)\(urlString)\n> \(L10n.Ingest.scrapeTimePrefix)\(Date().formatted(date: .numeric, time: .shortened))\n\n\($0.markdown)" }
                        let ocrText = (try? await self.extractImagesFromURL(urlString)) ?? ""
                        let rawMarkdown = rawBody.map { $0 + ocrText }
                        let filePath = rawMarkdown.flatMap { store.saveContent($0, category: .link, ext: "md") }
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
