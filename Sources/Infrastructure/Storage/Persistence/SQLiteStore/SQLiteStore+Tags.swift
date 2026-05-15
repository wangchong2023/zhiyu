// SQLiteStore+Tags.swift
//
// 作者: Wang Chong
// 功能说明: SQLiteStore 扩展：负责全局标签的重命名与批量删除逻辑，处理跨线程数据访问。
// 版本: 1.1
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import GRDB

extension SQLiteStore {
    
    // MARK: - 标签管理 (Tag Management)

    func renameTag(_ oldTag: String, to newTag: String) {
        Logger.shared.logTimed(action: .update, target: oldTag, module: "SQLiteStore", details: "Rename to: \(newTag)") {
            try? performBatchWrite { db in
                try self.internalRenameTag(oldTag, to: newTag, in: db)
            }
        }
    }

    func deleteTag(_ tag: String) {
        Logger.shared.logTimed(action: .delete, target: tag, module: "SQLiteStore", details: "Delete Success") {
            try? performBatchWrite { db in
                try self.internalDeleteTag(tag, in: db)
            }
        }
    }

    // MARK: - 内部事务方法

    func internalRenameTag(_ oldTag: String, to newTag: String, in db: Database) throws {
        // 直接从数据库过滤包含该标签的页面，避开 MainActor 属性访问
        let pagesToUpdate = try KnowledgePage.filter(Column("tags").like("%\"\(oldTag)\"%")).fetchAll(db)
        
        for p in pagesToUpdate {
            var updatedTags = p.tags
            if let idx = updatedTags.firstIndex(of: oldTag) {
                updatedTags[idx] = newTag
                var updatedPage = p
                updatedPage.tags = updatedTags
                try updatedPage.update(db)
            }
        }
    }

    func internalDeleteTag(_ tag: String, in db: Database) throws {
        let pagesToUpdate = try KnowledgePage.filter(Column("tags").like("%\"\(tag)\"%")).fetchAll(db)
        
        for p in pagesToUpdate {
            var updatedTags = p.tags
            if let idx = updatedTags.firstIndex(of: tag) {
                updatedTags.remove(at: idx)
                var updatedPage = p
                updatedPage.tags = updatedTags
                try updatedPage.update(db)
            }
        }
    }
}
