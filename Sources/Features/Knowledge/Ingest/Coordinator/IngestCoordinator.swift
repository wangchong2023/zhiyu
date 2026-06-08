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
    var newCustomIcon: String?
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
                _ = url.startAccessingSecurityScopedResource()
                let taskID = TaskCenter.shared.addTask(type: .ingest, name: L10n.Ingest.importingFile, target: url.lastPathComponent)
                Task {
                    defer { url.stopAccessingSecurityScopedResource() }
                    let page = await store.ingestService.ingestDocument(at: url, pageStore: store)
                    await MainActor.run {
                        if page != nil {
                            TaskCenter.shared.updateTask(taskID, status: .completed)
                            HapticFeedback.shared.trigger(.success)
                        } else {
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
        let taskID = TaskCenter.shared.addTask(type: .ingest, name: L10n.Ingest.fetchingURL, target: url.host ?? url.absoluteString)
        Task {
            let page = try? await store.ingestService.ingestURL(urlString: url.absoluteString, pageStore: store)
            await MainActor.run {
                if page != nil {
                    TaskCenter.shared.updateTask(taskID, status: .completed)
                    HapticFeedback.shared.trigger(.success)
                    self.newURL = ""
                } else {
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
