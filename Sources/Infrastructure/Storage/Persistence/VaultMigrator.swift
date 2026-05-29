//
//  VaultMigrator.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/29.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：属于 Persistence 模块，负责专属笔记本数据库的 Schema 迁移逻辑。
//
import Foundation
import GRDB

/// 专属笔记本数据库迁移器
struct VaultMigrator {
    
    /// 获取配置好的迁移器实例
    static func makeMigrator(isInTesting: Bool) -> DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        #if DEBUG
        if !isInTesting {
            migrator.eraseDatabaseOnSchemaChange = true
        }
        #endif

        // V1: 初始工业化架构
        migrator.registerMigration("v1_initial_schema") { db in
            try createInitialTables(db)
        }

        // V2: SQLite 内嵌混合倒排高性能检索 (FTS5)
        migrator.registerMigration("v2_fts_initial") { db in
            try setupFTS(db)
        }

        // V3: 标签存储范式化
        migrator.registerMigration("v3_tag_normalization") { db in
            try normalizeTags(db)
        }

        // V4: SRS 间隔重复算法元数据
        migrator.registerMigration("v4_srs_metadata") { db in
            try setupSRS(db)
        }

        return migrator
    }
    
    // MARK: - 私有迁移步骤
    
    /// 创建核心业务表结构：pages、links、tags、undo_log
    private static func createInitialTables(_ db: Database) throws {
        // 1. 核心知识页面主表
        try db.create(table: AppConstants.Storage.Tables.pages) { t in
            t.column("id", .blob).primaryKey()
            t.column("title", .text).notNull().unique()
            t.column("page_type", .text).notNull().indexed()
            t.column("content", .text).notNull()
            t.column("aliases", .text)
            t.column("tags", .text)
            t.column("status", .text).notNull().defaults(to: "active")
            t.column("confidence", .text).notNull().defaults(to: "medium")
            t.column("sources", .text)
            t.column("related_page_ids", .text)
            t.column("is_pinned", .boolean).notNull().defaults(to: false)
            t.column("content_hash", .text)
            t.column("custom_icon", .text)
            t.column("source_url", .text)
            t.column("raw_snippet", .text)
            t.column("file_size", .integer)
            t.column("source_type", .text)
            t.column("lamport_timestamp", .integer).notNull().defaults(to: 0)
            t.column("created_at", .datetime).notNull().defaults(to: Date())
            t.column("updated_at", .datetime).notNull().defaults(to: Date())
        }

        // 2. 知识图谱双向链接映射表
        try db.create(table: AppConstants.Storage.Tables.links) { t in
            t.column("source_id", .blob).notNull().references(AppConstants.Storage.Tables.pages, column: "id", onDelete: .cascade)
            t.column("target_id", .blob).notNull().references(AppConstants.Storage.Tables.pages, column: "id", onDelete: .cascade).indexed()
            t.column("context", .text)
            t.column("created_at", .datetime).notNull().defaults(to: Date())
            t.primaryKey(["source_id", "target_id"])
        }

        // 3. 语义块切片表
        try db.create(table: AppConstants.Storage.Tables.pageChunks) { t in
            t.column("id", .text).primaryKey()
            t.column("page_id", .blob).notNull().references(AppConstants.Storage.Tables.pages, column: "id", onDelete: .cascade)
            t.column("parent_id", .text).references(AppConstants.Storage.Tables.pageChunks, column: "id", onDelete: .cascade)
            t.column("chunk_type", .text).notNull()
            t.column("content", .text).notNull()
            t.column("anchor_path", .text)
            t.column("chunk_index", .integer).notNull()
            t.column("embedding", .blob)
            t.column("start_index", .integer)
            t.column("created_at", .datetime).notNull().defaults(to: Date())
            t.column("updated_at", .datetime).notNull().defaults(to: Date())
        }

        // 4. 页面层级高维稠密向量映射表
        try db.create(table: AppConstants.Storage.Tables.pageEmbeddings) { t in
            t.column("id", .blob).primaryKey().references(AppConstants.Storage.Tables.pages, column: "id", onDelete: .cascade)
            t.column("vector_blob", .blob).notNull()
            t.column("model_name", .text).notNull()
            t.column("created_at", .datetime).notNull().defaults(to: Date())
            t.column("updated_at", .datetime).notNull().defaults(to: Date())
        }

        // 5. 资源审计表
        try db.create(table: AppConstants.Storage.Tables.tokenUsage) { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("model", .text).notNull()
            t.column("prompt_tokens", .integer).notNull()
            t.column("completion_tokens", .integer).notNull()
            t.column("total_tokens", .integer).notNull()
            t.column("created_at", .datetime).notNull().defaults(to: Date())
        }

        try db.create(table: AppConstants.Storage.Tables.llmCallLogs) { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("model", .text).notNull()
            t.column("prompt_tokens", .integer).notNull()
            t.column("completion_tokens", .integer).notNull()
            t.column("latency_ms", .integer).notNull()
            t.column("status", .text).notNull()
            t.column("created_at", .datetime).notNull().defaults(to: Date())
        }

        try db.create(table: AppConstants.Storage.Tables.ragEvaluations) { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("query", .text).notNull()
            t.column("answer", .text).notNull()
            t.column("faithfulness_score", .double).notNull()
            t.column("relevance_score", .double).notNull()
            t.column("context_precision", .double).notNull()
            t.column("evaluator_model", .text).notNull()
            t.column("created_at", .datetime).notNull().defaults(to: Date())
        }

        // 6. 触发器
        try db.execute(sql: """
            CREATE TRIGGER trigger_update_pages_timestamp
            AFTER UPDATE ON \(AppConstants.Storage.Tables.pages)
            BEGIN
                UPDATE \(AppConstants.Storage.Tables.pages) SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
            END;
        """)
    }
    
    /// 配置 FTS5 全文搜索虚拟表
    private static func setupFTS(_ db: Database) throws {
        try db.execute(sql: """
            CREATE VIRTUAL TABLE \(AppConstants.Storage.Tables.pagesFTS) USING fts5(
                id UNINDEXED, title, content, tags, aliases,
                content='\(AppConstants.Storage.Tables.pages)'
            )
        """)
        try db.execute(sql: "CREATE TRIGGER pages_ai AFTER INSERT ON \(AppConstants.Storage.Tables.pages) BEGIN INSERT INTO \(AppConstants.Storage.Tables.pagesFTS)(id, title, content, tags, aliases) VALUES (new.id, new.title, new.content, new.tags, new.aliases); END;")
        try db.execute(sql: "CREATE TRIGGER pages_ad AFTER DELETE ON \(AppConstants.Storage.Tables.pages) BEGIN INSERT INTO \(AppConstants.Storage.Tables.pagesFTS)(\(AppConstants.Storage.Tables.pagesFTS), id, title, content, tags, aliases) VALUES ('delete', old.id, old.title, old.content, old.tags, old.aliases); END;")
        try db.execute(sql: "CREATE TRIGGER pages_au AFTER UPDATE ON \(AppConstants.Storage.Tables.pages) BEGIN INSERT INTO \(AppConstants.Storage.Tables.pagesFTS)(\(AppConstants.Storage.Tables.pagesFTS), id, title, content, tags, aliases) VALUES ('delete', old.id, old.title, old.content, old.tags, old.aliases); INSERT INTO \(AppConstants.Storage.Tables.pagesFTS)(id, title, content, tags, aliases) VALUES (new.id, new.title, new.content, new.tags, new.aliases); END;")
    }
    
    /// 规范化标签数据，确保标签字段非空
    private static func normalizeTags(_ db: Database) throws {
        try db.create(table: AppConstants.Storage.Tables.tags) { t in
            t.column("id", .text).primaryKey()
            t.column("name", .text).notNull().unique()
            t.column("created_at", .datetime).notNull().defaults(to: Date())
        }

        try db.create(table: AppConstants.Storage.Tables.pageTags) { t in
            t.column("page_id", .blob).notNull().references(AppConstants.Storage.Tables.pages, column: "id", onDelete: .cascade)
            t.column("tag_id", .text).notNull().references(AppConstants.Storage.Tables.tags, column: "id", onDelete: .cascade)
            t.primaryKey(["page_id", "tag_id"])
        }

        let rows = try Row.fetchAll(db, sql: "SELECT id, tags FROM \(AppConstants.Storage.Tables.pages)")
        for row in rows {
            let pageID: Data = row["id"]
            let tagsJSON: String? = row["tags"]
            if let data = tagsJSON?.data(using: .utf8),
               let tags = try? JSONDecoder().decode([String].self, from: data) {
                 for tagName in tags {
                     try db.execute(sql: "INSERT OR IGNORE INTO \(AppConstants.Storage.Tables.tags) (id, name, created_at) VALUES (?, ?, ?)", arguments: [tagName, tagName, Date()])
                     try db.execute(sql: "INSERT OR IGNORE INTO \(AppConstants.Storage.Tables.pageTags) (page_id, tag_id) VALUES (?, ?)", arguments: [pageID, tagName])
                 }
            }
        }
    }
    
    /// 创建间隔重复记忆调度表
    private static func setupSRS(_ db: Database) throws {
        try db.create(table: AppConstants.Storage.Tables.srsMetadata) { t in
            t.column("page_id", .blob).primaryKey().references(AppConstants.Storage.Tables.pages, column: "id", onDelete: .cascade)
            t.column("ease_factor", .double).notNull().defaults(to: AppConstants.Storage.defaultEaseFactor)
            t.column("repetitions", .integer).notNull().defaults(to: 0)
            t.column("review_interval", .integer).notNull().defaults(to: 0)
            t.column("next_review_at", .datetime).notNull().indexed()
            t.column("created_at", .datetime).notNull().defaults(to: Date())
            t.column("updated_at", .datetime).notNull().defaults(to: Date())
        }
    }
}
