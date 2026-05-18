// PageDetailCoordinator.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：页面详情功能协调器，负责 PageDetailView 的业务编排与 UI 交互状态。
// 版本: 1.1
// 修改记录:
//   - 2026-05-15: 从 PageDetailViewModel 演进，承接 AI 任务的异步编排与 UI 反馈（Toast）。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import SwiftUI
import Observation

@MainActor
@Observable
final class PageDetailCoordinator {
    var page: KnowledgePage
    var isEditing = false
    var showBacklinks = false
    var showDeleteConfirmation = false
    var showAliasEditor = false
    var newAlias = ""
    var showIconPicker = false
    var showSnapshotHistory = false
    
    // AI 任务相关状态由注入的 aiStore 提供

    @ObservationIgnored @Inject private var store: AppStore
    @ObservationIgnored @Inject private var aiStore: AIWorkflowStore

    init(page: KnowledgePage) {
        self.page = page
    }

    var backlinks: [KnowledgePage] {
        store.pages.filter { page in
            page.content.contains("[[\(self.page.title)]]") || page.content.contains("[[\(self.page.title)|")
        }
    }

    // ── 核心业务 ──

    func deletePage() async {
        await store.deletePage(page)
    }

    func togglePin() async {
        var updated = page
        updated.isPinned.toggle()
        await store.savePage(updated)
        page = updated
    }

    // ── AI 任务编排 ──

    func generateSummary() {
        Task {
            ToastManager.shared.show(type: .processing, message: L10n.Common.aiThinking, duration: 0)
            do {
                _ = try await aiStore.runPageAISummary(content: page.content)
                HapticFeedback.shared.trigger(.success)
                ToastManager.shared.dismiss()
            } catch {
                ToastManager.shared.show(type: .error, message: error.localizedDescription)
            }
        }
    }

    func extractActions() {
        Task {
            ToastManager.shared.show(type: .processing, message: L10n.Common.aiThinking, duration: 0)
            do {
                _ = try await aiStore.runPageAIExtractActions(content: page.content)
                HapticFeedback.shared.trigger(.success)
                ToastManager.shared.dismiss()
            } catch {
                ToastManager.shared.show(type: .error, message: error.localizedDescription)
            }
        }
    }

    func expandContent() {
        Task {
            ToastManager.shared.show(type: .processing, message: L10n.Common.aiThinking, duration: 0)
            do {
                _ = try await aiStore.runPageAIExpansion(content: page.content)
                HapticFeedback.shared.trigger(.success)
                ToastManager.shared.dismiss()
            } catch {
                ToastManager.shared.show(type: .error, message: error.localizedDescription)
            }
        }
    }

    func performSynthesis(type: SynthesisStore.SynthesisType) {
        Task {
            ToastManager.shared.show(type: .processing, message: L10n.Common.aiThinking, duration: 0)
            do {
                _ = try await aiStore.performPageSynthesis(type: type, title: page.title, content: page.content)
                HapticFeedback.shared.trigger(.success)
                ToastManager.shared.dismiss()
            } catch {
                ToastManager.shared.show(type: .error, message: error.localizedDescription)
            }
        }
    }
    
    func findRelatedLinks() {
        Task {
            await aiStore.runAIScan()
        }
    }
}
