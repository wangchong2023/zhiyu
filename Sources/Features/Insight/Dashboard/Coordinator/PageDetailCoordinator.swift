//
//  PageDetailCoordinator.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：负责 PageDetail 业务流的导航路由与协作管理。
//
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

    /// 删除Page
    func deletePage() async {
        await store.deletePage(page)
    }

    /// 切换置顶
    func togglePin() async {
        var updated = page
        updated.isPinned.toggle()
        await store.savePage(updated)
        page = updated
    }

    // ── AI 任务编排 ──

    /// 生成Summary
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

    /// 提取Actions
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

    /// expandContent
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

    /// 执行Synthesis
    /// /// - Parameter type: type
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
    
    /// 查找RelatedLinks
    func findRelatedLinks() {
        Task {
            await aiStore.runAIScan()
        }
    }
}
