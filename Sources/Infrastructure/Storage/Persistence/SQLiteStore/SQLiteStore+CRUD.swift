// SQLiteStore+CRUD.swift
//
// 作者: Wang Chong
// 功能说明: SQLiteStore 扩展：负责知识库页面的增删改查核心业务逻辑。
// MARK: [SR-02] 混合检索 (RAG) 链路调度与 AI 摄入
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import GRDB

extension SQLiteStore {
    
    // MARK: - 创建 (Create)

    @discardableResult
    func createPage(
        title: String,
        type: PageType,
        customIcon: String? = nil,
        content: String = "",
        tags: [String] = [],
        sourceURL: String? = nil,
        rawSnippet: String? = nil,
        fileSize: Int64? = nil,
        sourceType: String? = nil,
        forceDeepScan: Bool = false
    ) async -> KnowledgePage {
        let startTime = Date()
        let page = KnowledgePage(
            title: title,
            type: type,
            customIcon: customIcon,
            content: content,
            tags: tags,
            status: content.isEmpty ? .stub : .active,
            sourceURL: sourceURL,
            rawTextSnippet: rawSnippet,
            fileSize: fileSize,
            sourceType: sourceType
        )

        do {
            let actualID = try repository.save(page)
            var savedPage = page
            savedPage.id = actualID

            // 同步等待向量更新 (结构化并发治理)
            await embeddingManager.updateEmbedding(for: savedPage)

            // 触发深度扫描
            if forceDeepScan || content.count > 500 {
                await performDeepScan(for: page)
            }

            logOperation(action: .create, target: title, startTime: startTime, details: "\(Localized.tr("detail.pageType")): \(type.displayName)")
            
            if !DatabaseManager.shared.isInTesting {
                SecurityManager.shared.updateSignature(for: dbPath)
            }
        } catch {
            logError(action: .create, target: title, startTime: startTime, error: error)
        }
        return page
    }

    // MARK: - 更新 (Update)

    func updatePage(_ page: KnowledgePage, forceDeepScan: Bool) async {
        let startTime = Date()
        guard pages.contains(where: { $0.id == page.id }) else { return }
        
        var updated = page
        updated.updated = Date()
        updated.lamportTimestamp += 1

        do {
            try repository.save(updated)
            // 同步等待向量更新
            await embeddingManager.updateEmbedding(for: updated)

            if forceDeepScan || updated.content.count > 500 {
                await performDeepScan(for: updated)
            }

            if !DatabaseManager.shared.isInTesting {
                SecurityManager.shared.updateSignature(for: dbPath)
            }
            logOperation(action: .update, target: page.title, startTime: startTime, details: "Success")
        } catch {
            logError(action: .update, target: page.title, startTime: startTime, error: error)
        }
    }

    func syncRemotePage(_ remotePage: KnowledgePage) async {
        if let localIndex = pages.firstIndex(where: { $0.id == remotePage.id }) {
            let localPage = pages[localIndex]
            let mergedPage = localPage.merge(with: remotePage)

            if mergedPage.lamportTimestamp != localPage.lamportTimestamp || mergedPage.updated != localPage.updated {
                Logger.shared.debug("♻️ [LWW] 页面 \(remotePage.title) 发生冲突，自动收敛")
                do {
                    try repository.save(mergedPage)
                    await embeddingManager.updateEmbedding(for: mergedPage)
                } catch {
                    Logger.shared.addLog(action: .error, target: "SQLiteStore", details: "Sync failed: \(error.localizedDescription)")
                }
            }
        } else {
            do {
                try repository.save(remotePage)
                await embeddingManager.updateEmbedding(for: remotePage)
            } catch {
                Logger.shared.addLog(action: .error, target: "SQLiteStore", details: "Insert remote failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 删除 (Delete)

    func deletePage(_ page: KnowledgePage) {
        let startTime = Date()
        // 清理反向引用
        for i in pages.indices {
            if pages[i].relatedPageIDs.contains(page.id) {
                var refPage = pages[i]
                refPage.relatedPageIDs.removeAll { $0 == page.id }
                _ = try? repository.save(refPage)
            }
        }

        do {
            try repository.delete(id: page.id)
            logOperation(action: .delete, target: page.title, startTime: startTime, details: "Success")
        } catch {
            logError(action: .delete, target: page.title, startTime: startTime, error: error)
        }
    }

    func clearAllData() {
        try? repository.deleteAll()
        onSaveNeeded?()
    }

    // MARK: - 批处理 (Transactions)

    /// 执行批量数据库写入操作，确保事务原子性 (@RR-01)
    func performBatchWrite(_ updates: @escaping (Database) throws -> Void) throws {
        do {
            try DatabaseManager.shared.dbWriter?.write(updates)
        } catch {
            Logger.shared.addLog(action: .error, target: "SQLiteStore", details: "Batch write failed: \(error.localizedDescription)")
            throw error // 重新抛出，以便调用者感知失败
        }
    }

    // MARK: - 私有辅助

    private func logOperation(action: LogAction, target: String, startTime: Date, details: String) {
        let endTime = Date()
        addLog(
            action: action,
            target: target,
            details: details,
            duration: endTime.timeIntervalSince(startTime),
            startTime: startTime,
            endTime: endTime,
            module: "SQLiteStore"
        )
    }

    private func logError(action: LogAction, target: String, startTime: Date, error: Error) {
        logOperation(action: .error, target: target, startTime: startTime, details: "Failed: \(error.localizedDescription)")
    }
}
