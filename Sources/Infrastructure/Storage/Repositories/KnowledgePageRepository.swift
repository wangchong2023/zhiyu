// KnowledgePageRepository.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：本文件实现了知识管理系统的核心存储仓库（KnowledgePageRepository）。
// 核心职责：负责 KnowledgePage 及其关联链接（Graph）的物理持久化。
// 遵循 KnowledgeRepository 协议，采用 GRDB ORM 模式实现。
// 版本: 1.9
// 修改记录:
//   - 2026-05-16: 物理归位重构：更名为 KnowledgePageRepository。
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
@preconcurrency import GRDB

// MARK: - 核心存储 (KnowledgePageRepository)

/// 知识库 页面存储：封装基于 GRDB 的高性能 CRUD 操作。
final class KnowledgePageRepository: KnowledgeRepository, @unchecked Sendable {
    private let dbWriter: any DatabaseWriter

    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }

    // MARK: - 页面操作 (CRUD)

    func save(_ page: KnowledgePage) async throws {
        _ = try await dbWriter.write { db in
            try self.save(page, in: db)
        }
    }

    /// 批量保存页面 (用于导入/同步)
    func saveAll(_ pages: [KnowledgePage]) async throws {
        try await dbWriter.write { db in
            for page in pages {
                try self.save(page, in: db)
            }
        }
    }

    /// 在已有数据库事务中保存页面及其关联链接，返回实际使用的 ID
    @discardableResult
    func save(_ page: KnowledgePage, in db: Database) throws -> UUID {
        let savedID = try upsert(page, in: db)
        try saveLinks(sourceID: savedID, targetTitles: page.outgoingLinks, in: db)
        return savedID
    }

    /// 执行具体的 Upsert 逻辑
    private func upsert(_ page: KnowledgePage, in db: Database) throws -> UUID {
        var p = page
        // 查找是否已存在同名标题
        if let existing = try KnowledgePage.filter(KnowledgePage.Columns.title == page.title).fetchOne(db) {
            p.id = existing.id
            p.createdAt = existing.createdAt
            p.updatedAt = Date()
            try p.update(db)
            return existing.id
        } else {
            p.createdAt = Date()
            p.updatedAt = Date()
            try p.insert(db)
            return p.id
        }
    }

    func delete(id: UUID) async throws {
        _ = try await dbWriter.write { db in
            try KnowledgePage.filter(KnowledgePage.Columns.id == id).deleteAll(db)
        }
    }

    // MARK: - 查询 (Queries)

    func fetchAll() async throws -> [KnowledgePage] {
        try await dbWriter.read { db in
            try KnowledgePage.order(KnowledgePage.Columns.updatedAt.desc).fetchAll(db)
        }
    }

    func fetch(id: UUID) async throws -> KnowledgePage? {
        try await dbWriter.read { db in
            try KnowledgePage.filter(KnowledgePage.Columns.id == id).fetchOne(db)
        }
    }

    func fetch(title: String) async throws -> KnowledgePage? {
        try await dbWriter.read { db in
            try KnowledgePage.filter(KnowledgePage.Columns.title == title).fetchOne(db)
        }
    }

    func fetchPinned() async throws -> [KnowledgePage] {
        try await dbWriter.read { db in
            try KnowledgePage.filter(KnowledgePage.Columns.isPinned == true)
                .order(KnowledgePage.Columns.updatedAt.desc)
                .fetchAll(db)
        }
    }

    func fetchRecentlyUpdated(limit: Int) async throws -> [KnowledgePage] {
        try await dbWriter.read { db in
            try KnowledgePage.order(KnowledgePage.Columns.updatedAt.desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    func fetch(type: PageType) async throws -> [KnowledgePage] {
        try await dbWriter.read { db in
            try KnowledgePage.filter(KnowledgePage.Columns.pageType == type.rawValue)
                .order(KnowledgePage.Columns.updatedAt.desc)
                .fetchAll(db)
        }
    }

    func exists(title: String) async throws -> Bool {
        try await dbWriter.read { db in
            try KnowledgePage.filter(KnowledgePage.Columns.title == title).fetchCount(db) > 0
        }
    }

    func search(query: String) async throws -> [KnowledgePage] {
        try await dbWriter.read { db in
            // FTS5 搜索：通过关联查询实现，避免裸写 SQL
            // 使用 FTS5Pattern 确保查询语法的合法性
            guard let pattern = FTS5Pattern(matchingAnyTokenIn: query) else {
                return []
            }
            
            return try KnowledgePage
                .joining(required: KnowledgePage.contentSnapshot.filter(Column("content").match(pattern)))
                .order(sql: "rank")
                .fetchAll(db)
        }
    }

    // MARK: - 反向链接 (Links)

    func fetchBacklinks(for targetID: UUID) async throws -> [UUID] {
        try await dbWriter.read { db in
            let links = try PageLink.filter(PageLink.Columns.targetID == targetID).fetchAll(db)
            return links.map { $0.sourceID }
        }
    }

    private func saveLinks(sourceID: UUID, targetTitles: [String], in db: Database) throws {
        try PageLink.filter(PageLink.Columns.sourceID == sourceID).deleteAll(db)
        for title in targetTitles {
            if let target = try KnowledgePage.filter(KnowledgePage.Columns.title == title).fetchOne(db) {
                let link = PageLink(sourceID: sourceID, targetID: target.id, createdAt: Date())
                try link.insert(db)
            }
        }
    }

    // MARK: - 标签管理 (Tag Management)

    func renameTag(_ oldTag: String, to newTag: String) async throws {
        try await dbWriter.write { db in
            let pagesToUpdate = try KnowledgePage.filter(KnowledgePage.Columns.tags.like("%\"\(oldTag)\"%")).fetchAll(db)
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
    }

    func deleteTag(_ tag: String) async throws {
        try await dbWriter.write { db in
            let pagesToUpdate = try KnowledgePage.filter(KnowledgePage.Columns.tags.like("%\"\(tag)\"%")).fetchAll(db)
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

    // MARK: - 统计 (Stats)

    func count() async throws -> Int {
        try await dbWriter.read { db in
            try KnowledgePage.fetchCount(db)
        }
    }

    func count(type: PageType) async throws -> Int {
        try await dbWriter.read { db in
            try KnowledgePage.filter(KnowledgePage.Columns.pageType == type.rawValue).fetchCount(db)
        }
    }

    func deleteAll() async throws {
        _ = try await dbWriter.write { db in
            try KnowledgePage.deleteAll(db)
            try PageLink.deleteAll(db)
        }
    }
}

// MARK: - GRDB 关联定义

extension KnowledgePage {
    /// 定义 FTS5 关联，使用物理 ID 进行连接
    /// 允许使用 Query Interface 进行混合搜索
    nonisolated(unsafe) static let contentSnapshot = belongsTo(KnowledgePageFTS.self, using: ForeignKey(["id"], to: ["id"]))
}
