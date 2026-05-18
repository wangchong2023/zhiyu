// KnowledgePageManager.swift
//
// 作者: Wang Chong
// 功能说明: [L1.5] 领域中心层：知识页面管理服务，负责页面 CRUD 操作的事务性编排、双向链接维护及撤销/重做调度。
// 版本: 1.0
// 修改记录:
//   - 2026-05-18: 从 AppStore 剥离核心业务逻辑，实现 Facade 瘦身。
// 版权: © 2026 Wang Chong。保留所有权利。

import Foundation
import Observation
import Combine

/// 知识页面管理服务 (L1.5-Domain)
/// 负责页面生命周期管理及跨服务逻辑协同。
@MainActor
public final class KnowledgePageManager {
    
    @ObservationIgnored @Inject private var pageStore: any AnyPageStoreCapabilities
    @ObservationIgnored @Inject private var linkService: LinkService
    @ObservationIgnored @Inject private var undoService: UndoService
    @ObservationIgnored @Inject private var backupService: BackupService
    @ObservationIgnored @Inject private var ingestService: IngestService
    @ObservationIgnored @Inject private var logger: any LoggerProtocol
    @ObservationIgnored @Inject private var tagStore: TagStore
    @ObservationIgnored @Inject private var aiWorkflowStore: any AIWorkflowCapabilities

    public init() {}

    // MARK: - 核心 CRUD

    /// 根据标题查询页面
    public func pageByTitle(_ title: String, in pages: [KnowledgePage]) async -> KnowledgePage? {
        await linkService.pageByTitle(title, in: pages)
    }

    /// 创建页面
    @discardableResult
    public func createPage(
        title: String,
        pageType: PageType,
        customIcon: String? = nil,
        content: String = "",
        tags: [String] = [],
        sourceURL: String? = nil,
        rawSnippet: String? = nil,
        fileSize: Int64? = nil,
        sourceType: String? = nil,
        currentPages: [KnowledgePage]
    ) async throws -> KnowledgePage {
        undoService.pushSnapshot(currentPages)

        let page = try await pageStore.createPage(
            title: title,
            pageType: pageType,
            customIcon: customIcon,
            content: content,
            tags: tags,
            sourceURL: sourceURL,
            rawSnippet: rawSnippet,
            fileSize: fileSize,
            sourceType: sourceType
        )

        backupService.markDirty()
        
        let totalLinks = (try? await pageStore.fetchAllPages())?.reduce(0) { $0 + $1.outgoingLinks.count } ?? 0
        AppEventBus.shared.publish(.pageCreated(id: page.id, title: page.title, nodeCount: currentPages.count + 1, linkCount: totalLinks))

        return page
    }

    /// 更新页面
    public func updatePage(_ page: KnowledgePage, currentPages: [KnowledgePage]) async throws {
        undoService.pushSnapshot(currentPages)
        try await pageStore.updatePage(page)
        backupService.markDirty()
        
        let totalLinks = currentPages.reduce(0) { $0 + $1.outgoingLinks.count }
        AppEventBus.shared.publish(.pageUpdated(id: page.id, nodeCount: currentPages.count, linkCount: totalLinks))
    }

    /// 保存页面 (含插件事件触发)
    public func savePage(_ page: KnowledgePage, currentPages: [KnowledgePage]) async throws {
        try await updatePage(page, currentPages: currentPages)
        PluginRegistry.shared.emitEvent("onPageSave", data: page.id.uuidString)
    }

    /// 删除页面
    public func deletePage(_ page: KnowledgePage, currentPages: [KnowledgePage]) async throws {
        undoService.pushSnapshot(currentPages)
        try await pageStore.deletePage(page)
        AppEventBus.shared.publish(.pageDeleted(id: page.id))
        PluginRegistry.shared.emitEvent("onPageDelete", data: page.id.uuidString)
    }

    /// 重命名页面 (处理双向链接)
    public func renamePage(_ page: KnowledgePage, to newTitle: String, currentPages: [KnowledgePage]) async throws {
        let oldTitle = page.title
        let modifiedPages = await linkService.prepareRename(page: page, to: newTitle, in: currentPages)

        try await pageStore.performBatchWrite { db in
            for p in modifiedPages { try p.save(db) }
        }
        logger.addLog(action: .update, target: newTitle, details: "Renamed from \(oldTitle)", module: "Knowledge")
        backupService.markDirty()
    }

    // MARK: - 撤销 / 重做

    public func undo(currentPages: [KnowledgePage]) async throws -> [KnowledgePage]? {
        if let prev = undoService.undo(currentPages: currentPages) {
            await pageStore.replaceAllPages(prev)
            return prev
        }
        return nil
    }

    public func redo(currentPages: [KnowledgePage]) async throws -> [KnowledgePage]? {
        if let next = undoService.redo(currentPages: currentPages) {
            await pageStore.replaceAllPages(next)
            return next
        }
        return nil
    }

    // MARK: - 业务协同

    /// 应用潜在链接建议
    public func applyPotentialLink(_ suggestion: PotentialLinkSuggestion, currentPages: [KnowledgePage]) async throws {
        guard var page = currentPages.first(where: { $0.id == suggestion.sourcePageID }) else { return }
        
        let oldContent = page.content
        let newContent = oldContent.replacingOccurrences(
            of: suggestion.targetTitle,
            with: "[[\(suggestion.targetTitle)]]",
            options: .caseInsensitive
        )
        
        if oldContent != newContent {
            page.content = newContent
            try await updatePage(page, currentPages: currentPages)
            logger.addLog(action: .update, target: page.title, details: "Applied potential link to [[\(suggestion.targetTitle)]]", module: "Knowledge")
        }
    }

    /// 应用 AI 重构建议
    public func applyRefactorSuggestion(_ suggestion: RefactorSuggestion, currentPages: [KnowledgePage]) async throws {
        if suggestion.type == "rename", let page = currentPages.first(where: { $0.title == suggestion.target }) {
            try await renamePage(page, to: suggestion.suggestion, currentPages: currentPages)
        }
        aiWorkflowStore.removeRefactorSuggestion(id: suggestion.id)
    }

    /// 导入文件夹
    public func ingestFolder(at url: URL, pageStore: any AnyPageStore) async {
        _ = await ingestService.ingestFolder(at: url, pageStore: pageStore)
    }

    // MARK: - 标签管理转发

    public func renameTag(_ oldTag: String, to newTag: String) async {
        await tagStore.renameTag(old: oldTag, to: newTag)
    }

    public func deleteTag(_ tag: String) async {
        await tagStore.deleteTag(tag)
    }

    public func bulkDeleteTags(_ tags: [String]) async {
        await tagStore.bulkDeleteTags(tags)
    }
}
