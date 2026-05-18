// DatabaseManager.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：[Infra] 持久化层核心：负责数据库连接、多租户 (Vault) 隔离策略及架构迁移。
// 遵循工业级全表审计标准化：
//   - 时间戳统一为 created_at / updated_at
//   - 关联采用物理 UUID (target_id)
//   - 规避 SQL 保留字 (type -> page_type)
// 版本: 1.6 (Industrial Refactoring)
// 修改记录:
//   - 2026-05-16: 范式化重构：引入 tags 与 page_tags 表，优化标签检索性能。
// 日期: 2026-05-15
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import GRDB

/// [Infra] 数据库管理器：负责 SQLite 连接管理与 Schema 版本控制。
@MainActor
final class DatabaseManager: Sendable {
    static let shared = DatabaseManager()
    
    /// 数据库写入连接池 (支持多线程并发写入安全)
    var dbWriter: DatabaseWriter?

    /// 数据库物理路径
    private(set) var dbURL: URL?
    
    /// 当前是否处于测试模式 (防止破坏生产库)
    var isInTesting: Bool = false
    
    private init() {}
    
    // MARK: - 初始化
    
    /// 为测试环境初始化，直接使用传入的 DatabaseWriter 并同步执行数据库架构迁移
    /// - Parameter writer: GRDB 数据库写入连接池实例
    func setupForTesting(with writer: any DatabaseWriter) throws {
        self.dbWriter = writer
        self.isInTesting = true
        // 核心步骤：对测试环境下 transient 内存/文件数据库同步跑完所有 Schema 架构迁移，建立完整的物理表、虚拟表（如 FTS5）与触发器
        try migrator.migrate(writer)
    }
    
    /// 初始化数据库连接，如果目录不存在则自动创建。
    func setup(at url: URL) throws {
        self.dbURL = url
        let path = url.path
        // 1. 确保目录存在
        let folderURL = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        
        // 2. 配置连接池
        var config = Configuration()
        
        // 注意：物理层加密 (SQLCipher) 因当前依赖版本限制暂时关闭 (@P0)。
        // 安全性由 KnowledgePageRepository 的应用级 AES-GCM 加密保障，
        // 以及 SecurityManager 提供的文件级 HMAC 指纹校验保障。
        
        config.prepareDatabase { db in
            // 启用外键约束
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }
        
        // 3. 建立连接
        let dbPool = try DatabasePool(path: path, configuration: config)
        self.dbWriter = dbPool
        
        // 4. 执行架构迁移
        try migrator.migrate(dbPool)
    }
    
    // MARK: - 架构迁移 (Migrator)
    
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        // 如果架构发生不兼容变动，允许删除旧库重建 (工业级开发阶段常用，生产环境需慎用)
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        // V1: 初始工业化架构 - 全表审计标准化
        migrator.registerMigration("v1_initial_schema") { db in
            // 1. 核心知识页面主表
            try db.create(table: "pages") { t in
                t.column("id", .blob).primaryKey()
                t.column("title", .text).notNull().unique()
                t.column("page_type", .text).notNull().indexed()
                t.column("content", .text).notNull()
                t.column("aliases", .text) // JSON 字符串
                t.column("tags", .text)    // JSON 字符串
                t.column("status", .text).notNull().defaults(to: "active")
                t.column("confidence", .text).notNull().defaults(to: "medium")
                t.column("sources", .text) // JSON 引用
                t.column("related_page_ids", .text) // JSON UUIDs
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

            // 2. 知识图谱链接表 (物理 ID 关联)
            try db.create(table: "links") { t in
                t.column("source_id", .blob).notNull().references("pages", column: "id", onDelete: .cascade)
                t.column("target_id", .blob).notNull().references("pages", column: "id", onDelete: .cascade).indexed()
                t.column("context", .text)
                t.column("created_at", .datetime).notNull().defaults(to: Date())
                t.primaryKey(["source_id", "target_id"])
            }

            // 3. 向量分块表 (RAG 支持)
            try db.create(table: "page_chunks") { t in
                t.column("id", .text).primaryKey()
                t.column("page_id", .blob).notNull().references("pages", column: "id", onDelete: .cascade)
                t.column("parent_id", .text).references("page_chunks", column: "id", onDelete: .cascade)
                t.column("chunk_type", .text).notNull()
                t.column("content", .text).notNull()
                t.column("anchor_path", .text) // 新增：语义锚点路径
                t.column("chunk_index", .integer).notNull()
                t.column("embedding", .blob)
                t.column("start_index", .integer)
                t.column("created_at", .datetime).notNull().defaults(to: Date())
                t.column("updated_at", .datetime).notNull().defaults(to: Date())
            }

            // 4. 向量映射表
            try db.create(table: "page_embeddings") { t in
                t.column("id", .blob).primaryKey().references("pages", column: "id", onDelete: .cascade)
                t.column("vector_blob", .blob).notNull()
                t.column("model_name", .text).notNull()
                t.column("created_at", .datetime).notNull().defaults(to: Date())
                t.column("updated_at", .datetime).notNull().defaults(to: Date())
            }

            // 5. 治理与资源审计表
            try db.create(table: "token_usage") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("model", .text).notNull()
                t.column("prompt_tokens", .integer).notNull()
                t.column("completion_tokens", .integer).notNull()
                t.column("total_tokens", .integer).notNull()
                t.column("created_at", .datetime).notNull().defaults(to: Date())
            }

            try db.create(table: "llm_call_logs") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("model", .text).notNull()
                t.column("prompt_tokens", .integer).notNull()
                t.column("completion_tokens", .integer).notNull()
                t.column("latency_ms", .integer).notNull()
                t.column("status", .text).notNull()
                t.column("created_at", .datetime).notNull().defaults(to: Date())
            }

            try db.create(table: "rag_evaluations") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("query", .text).notNull()
                t.column("answer", .text).notNull()
                t.column("faithfulness_score", .double).notNull()
                t.column("relevance_score", .double).notNull()
                t.column("context_precision", .double).notNull()
                t.column("evaluator_model", .text).notNull()
                t.column("created_at", .datetime).notNull().defaults(to: Date())
            }

            // 6. 自动化触发器
            try db.execute(sql: """
                CREATE TRIGGER trigger_update_pages_timestamp
                AFTER UPDATE ON pages
                BEGIN
                    UPDATE pages SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
                END;
            """)
        }

        // V2: FTS5 搜索引擎
        migrator.registerMigration("v2_fts_initial") { db in
            try db.execute(sql: """
                CREATE VIRTUAL TABLE pages_fts USING fts5(
                    id UNINDEXED, title, content, tags, aliases,
                    content='pages'
                )
            """)
            try db.execute(sql: """
                CREATE TRIGGER pages_ai AFTER INSERT ON pages BEGIN
                    INSERT INTO pages_fts(id, title, content, tags, aliases)
                    VALUES (new.id, new.title, new.content, new.tags, new.aliases);
                END;
            """)
            try db.execute(sql: """
                CREATE TRIGGER pages_ad AFTER DELETE ON pages BEGIN
                    INSERT INTO pages_fts(pages_fts, id, title, content, tags, aliases)
                    VALUES ('delete', old.id, old.title, old.content, old.tags, old.aliases);
                END;
            """)
            try db.execute(sql: """
                CREATE TRIGGER pages_au AFTER UPDATE ON pages BEGIN
                    INSERT INTO pages_fts(pages_fts, id, title, content, tags, aliases)
                    VALUES ('delete', old.id, old.title, old.content, old.tags, old.aliases);
                    INSERT INTO pages_fts(id, title, content, tags, aliases)
                    VALUES (new.id, new.title, new.content, new.tags, new.aliases);
                END;
            """)
        }

        // V3: 标签存储范式化 (DIP 性能优化)
        migrator.registerMigration("v3_tag_normalization") { db in
            // 1. 创建标签字典表
            try db.create(table: "tags") { t in
                t.column("id", .text).primaryKey() // 使用标签名作为 ID，或 UUID
                t.column("name", .text).notNull().unique()
                t.column("created_at", .datetime).notNull().defaults(to: Date())
            }

            // 2. 创建页面-标签多对多关联表
            try db.create(table: "page_tags") { t in
                t.column("page_id", .blob).notNull().references("pages", column: "id", onDelete: .cascade)
                t.column("tag_id", .text).notNull().references("tags", column: "id", onDelete: .cascade)
                t.primaryKey(["page_id", "tag_id"])
            }

            // 3. 存量数据迁移：从 pages.tags JSON 字符串中提取并插入
            let rows = try Row.fetchAll(db, sql: "SELECT id, tags FROM pages")
            for row in rows {
                let pageID: Data = row["id"]
                let tagsJSON: String? = row["tags"]
                if let data = tagsJSON?.data(using: .utf8),
                   let tags = try? JSONDecoder().decode([String].self, from: data) {
                    for tagName in tags {
                        // 插入标签 (忽略冲突)
                        try db.execute(sql: "INSERT OR IGNORE INTO tags (id, name, created_at) VALUES (?, ?, ?)", arguments: [tagName, tagName, Date()])
                        // 建立关联
                        try db.execute(sql: "INSERT OR IGNORE INTO page_tags (page_id, tag_id) VALUES (?, ?)", arguments: [pageID, tagName])
                    }
                }
            }
        }

        // V4: SRS 间隔重复系统支持 (@P1: 实现知识内化闭环)
        migrator.registerMigration("v4_srs_metadata") { db in
            try db.create(table: "srs_metadata") { t in
                t.column("page_id", .blob).primaryKey().references("pages", column: "id", onDelete: .cascade)
                t.column("ease_factor", .double).notNull().defaults(to: 2.5)
                t.column("repetitions", .integer).notNull().defaults(to: 0)
                t.column("review_interval", .integer).notNull().defaults(to: 0)
                t.column("next_review_at", .datetime).notNull().indexed()
                t.column("created_at", .datetime).notNull().defaults(to: Date())
                t.column("updated_at", .datetime).notNull().defaults(to: Date())
            }
        }

        return migrator
    }

    /// 重置连接池 (物理删除文件前必须调用)
    func reset() {
        dbWriter = nil
        dbURL = nil
    }
}

// MARK: - Errors
enum DatabaseError: Error {
    case initializationFailed
}
