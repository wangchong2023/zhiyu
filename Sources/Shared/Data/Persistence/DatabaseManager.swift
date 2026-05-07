// DatabaseManager.swift
//
// 作者: Wang Chong
// 功能说明: 数据库管理器，负责 GRDB 的初始化、配置、并发管理及 Schema 迁移。
// 版本: 1.1
// 修改记录:
//   - 2026-05-05: 升级文档规范，优化内存数据库检测逻辑
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import GRDB

/// 数据库相关错误
enum DatabaseError: Error {
    case initializationFailed
    case migrationFailed(String)
}

/// 数据库管理器：负责 GRDB 的初始化、配置、并发管理及 Schema 迁移。
/// 使用 DatabasePool 以获得最高性能的 WAL 模式并发访问能力。
@MainActor
final class DatabaseManager {
    /// 全局单例
    static let shared = DatabaseManager()
    
    /// 标记当前是否处于测试环境
    var isInTesting: Bool = false
    
    /// 统一使用 DatabaseWriter 协议，支持 DatabasePool (WAL) 或 DatabaseQueue (内存/单线程)
    private(set) var dbWriter: (any DatabaseWriter)?
    
    /// 获取当前的数据库池（辅助属性，保持向后兼容）
    var dbPool: DatabasePool! {
        return dbWriter as? DatabasePool
    }
    
    private init() {
        // 延迟初始化，由 setup() 显式启动
    }
    
    /// 初始化数据库连接
    /// 配置 WAL 模式、外键约束并执行 Schema 迁移
    /// - Parameter dbURL: 数据库文件的 URL 路径
    /// - Throws: 数据库打开或迁移失败时的错误
    func setup(at dbURL: URL) throws {
        // 如果已经初始化过且路径一致，则跳过
        let isMemory = dbURL.absoluteString.contains(":memory:")
        if let current = dbWriter {
            let currentPath = current.path
            let newPath = dbURL.path
            // 内存模式下统一比对标记，文件模式下比对真实路径
            if (isMemory && currentPath == ":memory:") || currentPath == newPath {
                return
            }
        }
        
        var config = Configuration()
        config.prepareDatabase { db in
            // 启用外键支持
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }
        
        // 核心修复逻辑：检测是否为内存数据库
        
        if isMemory {
            // 对于内存数据库，直接使用 DatabaseQueue() 避开非法路径问题
            self.dbWriter = try DatabaseQueue(configuration: config)
        } else {
            // 使用 DatabasePool 启用 WAL 模式
            self.dbWriter = try DatabasePool(path: dbURL.path, configuration: config)
        }
        
        // 核心修复：使用显式类型转换避开 any DatabaseWriter 无法直接满足泛型约束的问题
        if let pool = dbWriter as? DatabasePool {
            try migrator.migrate(pool)
        } else if let queue = dbWriter as? DatabaseQueue {
            try migrator.migrate(queue)
        } else {
            // 回退方案：如果将来增加了其他 DatabaseWriter 实现
            try dbWriter?.read { db in
                _ = db // 确保数据库可访问
            }
            // 注意：某些情况下此处的 migrate 仍可能因 any 约束报错
            // 但显式处理 Pool 和 Queue 已覆盖 99% 的场景
        }
    }
    
    /// 关闭当前数据库连接并重置单例状态
    func reset() {
        dbWriter = nil
    }
    
    // MARK: - 数据库迁移 (Migrator)
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        #if DEBUG
        // 在开发模式下，允许在不增加版本的情况下擦除并重新创建（方便快速调整 Schema）
        // migrator.eraseDatabaseOnSchemaChange = true
        #endif
        
        // V1: 初始架构 (包含 pages, page_embeddings, page_chunks, links)
        migrator.registerMigration("v1") { db in
            // 1. Pages 表
            try db.create(table: "pages", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("title", .text).notNull().indexed()
                t.column("type", .text).notNull().defaults(to: "concept").indexed()
                t.column("custom_icon", .text)
                t.column("content", .text).defaults(to: "")
                t.column("aliases", .text).defaults(to: "[]")
                t.column("tags", .text).defaults(to: "[]")
                t.column("status", .text).notNull().defaults(to: "active").indexed()
                t.column("confidence", .text).notNull().defaults(to: "medium")
                t.column("sources", .text).defaults(to: "[]")
                t.column("related_page_ids", .text).defaults(to: "[]")
                t.column("is_pinned", .boolean).notNull().defaults(to: false).indexed()
                t.column("content_hash", .text)
                t.column("source_url", .text)
                t.column("raw_snippet", .text)
                t.column("file_size", .integer)
                t.column("source_type", .text)
                t.column("created", .datetime).notNull()
                t.column("updated", .datetime).notNull().indexed()
                // v1 包含 lamport_timestamp 作为基线
                t.column("lamport_timestamp", .integer).notNull().defaults(to: 0)
            }
            
            // 2. FTS5 全文搜索表 (基于 pages 内容)
            try db.create(virtualTable: "pages_fts", ifNotExists: true, using: FTS5()) { t in
                t.tokenizer = .unicode61() // 支持多语言分词
                t.column("title")
                t.column("content")
                t.column("tags")
                t.column("aliases")
                
                // 3. 极速同步：使用 GRDB 自动生成的触发器替代手动 SQL
                // 它会自动处理 INSERT/UPDATE/DELETE 时的 rowid 关联与内容对齐
                t.synchronize(withTable: "pages")
            }
            
            // 4. Embeddings 表
            try db.create(table: "page_embeddings", ifNotExists: true) { t in
                t.column("id", .text).primaryKey().references("pages", column: "id", onDelete: .cascade)
                t.column("vector_blob", .blob).notNull()
                t.column("model_name", .text).notNull()
                t.column("updated", .datetime).notNull()
            }
            
            // 5. Page Chunks 表 (RAG)
            try db.create(table: "page_chunks", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("page_id", .text).notNull().references("pages", column: "id", onDelete: .cascade).indexed()
                t.column("content", .text).notNull()
                t.column("embedding", .blob)
                t.column("start_index", .integer)
            }
            
            // 6. Links 表
            try db.create(table: "links", ifNotExists: true) { t in
                t.column("source_id", .text).notNull().references("pages", column: "id", onDelete: .cascade)
                t.column("target_title", .text).notNull().indexed()
                t.column("context", .text)
                t.primaryKey(["source_id", "target_title"])
            }
        }
        
        // V2: 兼容性补丁 - 确保 lamport_timestamp 存在于旧库中
        migrator.registerMigration("v2_add_lamport") { db in
            let columns = try db.columns(in: "pages")
            if !columns.contains(where: { $0.name == "lamport_timestamp" }) {
                try db.alter(table: "pages") { t in
                    t.add(column: "lamport_timestamp", .integer).notNull().defaults(to: 0)
                }
            }
        }
        
        // V4: 标题唯一性约束 - 强制同名页面合并，并添加唯一索引
        migrator.registerMigration("v4_unique_title") { db in
            // 1. 清理现有重复标题数据（保留最新更新的一条）
            try db.execute(sql: """
                DELETE FROM pages
                WHERE id NOT IN (
                    SELECT id FROM (
                        SELECT id, title, MAX(updated) FROM pages GROUP BY title
                    )
                )
            """)
            
            // 2. 删除旧索引并创建唯一索引
            try db.execute(sql: "DROP INDEX IF EXISTS idx_pages_on_title")
            try db.execute(sql: "CREATE UNIQUE INDEX idx_pages_on_title ON pages(title)")
        }
        
        // V5: RAG 增强 - 升级分块表支持层级与分类
        migrator.registerMigration("v5_upgrade_page_chunks") { db in
            let columns = try db.columns(in: "page_chunks")
            if !columns.contains(where: { $0.name == "parent_id" }) {
                try db.alter(table: "page_chunks") { t in
                    t.add(column: "parent_id", .text).indexed()
                    t.add(column: "chunk_type", .text).notNull().defaults(to: "regular")
                }
            }
        }
        
        // V6: 资源审计 - 记录 Token 使用量以支持开销统计
        migrator.registerMigration("v6_resource_audit") { db in
            try db.create(table: "token_usage", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("model", .text).notNull()
                t.column("prompt_tokens", .integer).notNull().defaults(to: 0)
                t.column("completion_tokens", .integer).notNull().defaults(to: 0)
                t.column("total_tokens", .integer).notNull().defaults(to: 0)
                t.column("created", .datetime).notNull().indexed()
            }
        }
        
        // V7: 增强治理 - 性能监控与质量评估
        migrator.registerMigration("v7_enhanced_governance") { db in
            // 1. LLM 调用日志表 (可观测性：Token + 时延 + 状态)
            try db.create(table: "llm_call_logs", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("model", .text).notNull()
                t.column("prompt_tokens", .integer).notNull()
                t.column("completion_tokens", .integer).notNull()
                t.column("latency_ms", .integer).notNull().indexed()
                t.column("status", .text).notNull().defaults(to: "success")
                t.column("created", .datetime).notNull().indexed()
            }
            
            // 2. 质量评估表 (Benchmark)
            try db.create(table: "rag_evaluations", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("query", .text).notNull()
                t.column("answer", .text).notNull()
                t.column("faithfulness_score", .double).notNull()
                t.column("relevance_score", .double).notNull()
                t.column("context_precision", .double).notNull()
                t.column("evaluator_model", .text).notNull()
                t.column("created", .datetime).notNull().indexed()
            }
        }
        
        // V8: Karpathy 模式增强 - 补全溯源元数据
        migrator.registerMigration("v8_karpathy_metadata") { db in
            let columns = try db.columns(in: "pages")
            if !columns.contains(where: { $0.name == "file_size" }) {
                try db.alter(table: "pages") { t in
                    t.add(column: "file_size", .integer)
                    t.add(column: "source_type", .text)
                }
            }
        }
        
        return migrator
    }
}
