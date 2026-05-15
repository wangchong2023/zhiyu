// IngestCoordinator.swift
//
// 作者: Wang Chong
// 功能说明: 摄入功能协调器，负责 IngestView 的状态管理与业务流程编排。
// 版本: 1.0
// 修改记录:
//   - 2026-05-15: 初始版本，从 IngestView 剥离 UI 状态与业务逻辑。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI
import Observation
import UniformTypeIdentifiers

@MainActor
@Observable
final class IngestCoordinator {
    // ── 基础设施依赖 ──
    @ObservationIgnored @Inject var store: AppStore
    @ObservationIgnored @Inject var ingestStore: IngestStore
    @ObservationIgnored @Inject var llmService: LLMService

    // ── UI 控制状态 ──
    var isIngesting = false
    var showManualForm = false
    var manualFormTitle = L10n.Ingest.tr("manualEntry")
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

    func performIngest() {
        isIngesting = true
        let title = newTitle, content = newContent, type = newType, icon = newCustomIcon, smart = useSmartIngest
        
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
                await MainActor.run {
                    self.isIngesting = false
                    self.errorMessage = L10n.Ingest.tr("importFailed")
                    self.showError = true
                    HapticFeedback.shared.trigger(.error)
                }
            }
        }
    }

    func handleFileImport(_ result: Result<[URL], Error>) {
        if case .success(let urls) = result {
            for url in urls {
                let _ = url.startAccessingSecurityScopedResource()
                let taskID = TaskCenter.shared.addTask(type: .ingest, name: L10n.Ingest.tr("importingFile"), target: url.lastPathComponent)
                Task {
                    defer { url.stopAccessingSecurityScopedResource() }
                    let page = await store.ingestService.ingestDocument(at: url, pageStore: store)
                    await MainActor.run {
                        if let _ = page {
                            TaskCenter.shared.updateTask(taskID, status: .completed)
                            HapticFeedback.shared.trigger(.success)
                        } else {
                            TaskCenter.shared.updateTask(taskID, status: .failed(error: L10n.Ingest.tr("importFailed")))
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

    func handleURLImport() {
        guard let url = URL(string: newURL) else {
            errorMessage = L10n.Ingest.tr("invalidURL")
            showError = true
            return
        }
        showURLImport = false
        let taskID = TaskCenter.shared.addTask(type: .ingest, name: L10n.Ingest.tr("fetchingURL"), target: url.host ?? url.absoluteString)
        Task {
            let page = try? await store.ingestService.ingestURL(urlString: url.absoluteString, pageStore: store)
            await MainActor.run {
                if let _ = page {
                    TaskCenter.shared.updateTask(taskID, status: .completed)
                    HapticFeedback.shared.trigger(.success)
                    self.newURL = ""
                } else {
                    TaskCenter.shared.updateTask(taskID, status: .failed(error: L10n.Ingest.tr("importFailed")))
                    HapticFeedback.shared.trigger(.error)
                }
            }
        }
    }

    func performClipboardImport() {
        if let content = AppPasteboard.string, !content.isEmpty {
            self.newTitle = String(content.prefix(20))
            self.newContent = content
            self.manualFormTitle = L10n.Ingest.tr("manualEntry")
            self.showManualForm = true
        }
    }

    func resetForm() {
        newTitle = ""
        newContent = ""
        newCustomIcon = nil
        useSmartIngest = false
    }
}
