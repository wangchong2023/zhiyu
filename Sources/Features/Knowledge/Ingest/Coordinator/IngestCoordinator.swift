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

    // ── UI 控制状态 ──
    var isIngesting = false
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
    var newCustomIcon: String? = nil
    var newURL = ""
    var useSmartIngest = false

    var isLLMConfigured: Bool {
        llmService.isEnabled && !llmService.apiKey.isEmpty
    }

    init() {}

    // ── 业务动作 ──

    /// 执行导入摄取
    func performIngest() {
        isIngesting = true
        let title = newTitle, content = newContent, type = newType, icon = newCustomIcon, smart = useSmartIngest
        let category = newURL.isEmpty ? ImportCategory.manual.rawValue : ImportCategory.link.rawValue
        let recordID = UUID().uuidString

        // 创建导入记录
        let record = ImportRecord(
            id: recordID, category: category, title: title,
            status: ImportRecordStatus.processing, rawText: content,
            sourceURL: newURL.isEmpty ? nil : newURL,
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
        if case .success(let urls) = result {
            for url in urls {
                let _ = url.startAccessingSecurityScopedResource()
                let fileName = url.lastPathComponent
                let taskID = TaskCenter.shared.addTask(type: .ingest, name: L10n.Ingest.importingFile, target: fileName)
                let recordID = UUID().uuidString

                // 获取文件大小
                let fileSize: Int64? = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize.map(Int64.init)

                let record = ImportRecord(
                    id: recordID, category: ImportCategory.file.rawValue,
                    title: fileName, status: ImportRecordStatus.processing,
                    filePath: url.path, fileSize: fileSize,
                    vaultID: VaultService.shared.selectedVaultID?.uuidString
                )
                Task { try? await importRecordRepo.save(record) }

                Task {
                    defer { url.stopAccessingSecurityScopedResource() }
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

    /// 处理URL导入
    func handleURLImport() {
        guard let url = URL(string: newURL) else {
            errorMessage = L10n.Ingest.invalidURL
            showError = true
            return
        }
        showURLImport = false
        let recordID = UUID().uuidString
        let taskID = TaskCenter.shared.addTask(type: .ingest, name: L10n.Ingest.fetchingURL, target: url.host ?? url.absoluteString)

        // 创建导入记录
        let record = ImportRecord(
            id: recordID, category: ImportCategory.link.rawValue,
            title: url.absoluteString, status: ImportRecordStatus.processing,
            sourceURL: url.absoluteString,
            vaultID: VaultService.shared.selectedVaultID?.uuidString
        )
        Task { try? await importRecordRepo.save(record) }

        Task {
            let page = try? await store.ingestService.ingestURL(urlString: url.absoluteString, pageStore: store)
            await MainActor.run {
                if let page = page {
                    Task { @MainActor in
                        try? await importRecordRepo.updateStatus(id: recordID, status: ImportRecordStatus.done, completedAt: Date())
                        try? await importRecordRepo.updatePageID(id: recordID, pageID: page.id.uuidString)
                    }
                    TaskCenter.shared.updateTask(taskID, status: .completed)
                    HapticFeedback.shared.trigger(.success)
                    self.newURL = ""
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

    /// 执行Clipboard导入
    func performClipboardImport() {
        if let content = AppPasteboard.string, !content.isEmpty {
            self.newTitle = String(content.prefix(20))
            self.newContent = content
            self.manualFormTitle = L10n.Ingest.manualEntry
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
