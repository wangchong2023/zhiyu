// DatabaseManager.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：[Infra] 持久化层核心：负责数据库连接、多租户 (Vault) 隔离策略及架构迁移。
// 遵循工业级全表审计标准化：
//   - 时间戳统一为 created_at / updated_at
//   - 关联采用物理 UUID (target_id)
//   - 规避 SQL 保留字 (type -> page_type)
// 版本: 1.5 (Industrial Refactoring)
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
