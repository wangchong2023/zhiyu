// DatabaseManager.swift
//
// 作者: Wang Chong
// 功能说明: [L1] 基础设施层：[Infra] 持久化层核心：负责数据库连接、多租户 (Vault) 隔离策略及架构迁移。
// 核心职责：
// 1. 全局配置库与专属物理库生命周期托管。
// 2. 运行时 WAL 级物理多库热切换 (Multi-Vault Switching)。
// 3. 全表审计标准化与 Schema 架构版本渐进式迁移 (DatabaseMigrator)。
// 版本: 1.7 (Industrial Refactoring)
// 修改记录:
//   - 2026-05-18: 补全 100% 结构化三斜杠 DocC 简体中文规范，强化多库热切换生命周期与 WAL 安全断开机制的架构说明。
// 日期: 2026-05-18
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import GRDB

/// 数据库中枢管理器（DatabaseManager）。
/// 它是知识金库高内聚持久化层（Persistence）的基座大脑，托管了专属笔记本数据库（Workspace DB）
/// 和全局共享设置数据库（Global DB）的双轨道生命周期。
@MainActor
final class DatabaseManager: Sendable {
    
    /// 全局唯一的线程安全单例实例。
    static let shared = DatabaseManager()
    
    /// 专属笔记本数据库写入连接池（dbWriter）。
    /// 支持多线程并发读写与 WAL 安全锁隔离，是当前已激活 Vault 的核心数据通道。
    var dbWriter: DatabaseWriter?

    /// 全局配置数据库写入连接池（globalWriter）。
    /// 负责记录多租户 Vault 列表、全库 HMAC 安全防篡改指纹、系统偏好以及操作审计日志。
    var globalWriter: DatabaseWriter?

    /// 当前处于激活状态的专属笔记本数据库物理沙盒文件 URL。
    private(set) var dbURL: URL?

    /// 全局共享偏好配置库的物理沙盒文件 URL。
    private(set) var globalDBURL: URL?
    
    /// 当前数据库管理器是否运行于 Unit Test 单元测试管道中。
    var isInTesting: Bool = false
    
    /// 私有化单例构造方法。
    private init() {}
    
    // MARK: - 初始化方法组
    
    /// 为单元测试管道强制重连与注入内存/临时物理数据库连接池。
    /// - Parameter writer: 由单元测试套件临时开辟的 DatabaseWriter（通常是内存型 DatabaseQueue 实例）。
    /// - Throws: SQLite Schema 架构自动化迁移异常。
    func setupForTesting(with writer: any DatabaseWriter) throws {
        self.dbWriter = writer
        self.globalWriter = writer
        self.isInTesting = true
        // 核心步骤：对测试环境下瞬态内存数据库同步跑完所有 Schema 架构迁移，建立完整的物理表、虚拟表（如 FTS5）与触发器
        try migrator.migrate(writer)
        try globalMigrator.migrate(writer)
    }
    
    /// 初始化全局共享的主配置库（global.sqlite3）连接。
    /// - Parameter url: 物理沙盒中指向 `global.sqlite3` 文件的绝对路径 URL。
    /// - Throws: 目录创建失败或 GRDB 数据库连接池实例化异常。
    func setupGlobal(at url: URL) throws {
        self.globalDBURL = url
        let path = url.path
        
        // 1. 确保护航目录存在
        let folderURL = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        
        // 2. 配置连接池，启用外键约束
        var config = Configuration()
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }
        
        // 3. 建立连接并自动运行全局迁移
        let globalPool = try DatabasePool(path: path, configuration: config)
        self.globalWriter = globalPool
        
        try globalMigrator.migrate(globalPool)
        print("🌍 [DatabaseManager] 全局主配置库初始化成功: \(url.lastPathComponent)")
    }
    
    /// 初始化激活默认专属数据库（vault.sqlite3）连接。
    /// 若专属目录或同级全局配置目录不存在，则会自动创建并级联初始化 `global.sqlite3`。
    /// - Parameter url: 指向专属数据库的物理文件 URL 路径。
    /// - Throws: 目录授权、SQLite 实例化或专属 Schema 迁移失败。
    func setup(at url: URL) throws {
        // 1. 自动计算并在专属库同级目录下建立独立的 global.sqlite3 全局库
        let globalURL = url.deletingLastPathComponent().appendingPathComponent(AppConstants.Storage.globalDatabaseName)
        try setupGlobal(at: globalURL)
        
        // 2. 建立默认专属物理库连接
        self.dbURL = url
        let path = url.path
        let folderURL = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        
        var config = Configuration()
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }
        
        let dbPool = try DatabasePool(path: path, configuration: config)
        self.dbWriter = dbPool
        
        // 3. 执行专属库架构迁移
        try migrator.migrate(dbPool)
    }
    
    /// 物理热切换当前激活的专属笔记本数据库（Multi-Vault Switching）。
    /// 该操作支持 WAL 安全锁断开旧的并发池连接，安全重定向，热挂载目标新数据库，并触发全局状态广播。
    /// - Parameters:
    ///   - vaultID: 切换目标笔记本的唯一识别码 UUID。
    ///   - url: 目标笔记本数据库在沙盒中的物理绝对路径 URL。
    /// - Throws: 断开挂载异常、新库 GRDB Pool 实例化异常或架构版本不兼容升级失败。
    func switchDatabase(to vaultID: UUID, at url: URL) throws {
        print("🔄 [DatabaseManager] 开始执行物理多库热切换 => 目标: \(url.lastPathComponent)")
        
        // 1. 优雅断开并销毁旧的专属库 DatabasePool 资源，防止 WAL 发生多进程锁对撞
        self.dbWriter = nil
        self.dbURL = url
        
        // 2. 确保目标文件夹在沙盒中物理存在
        let folderURL = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        
        // 3. 重新配置并开辟新库的并发池连接
        var config = Configuration()
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }
        
        let dbPool = try DatabasePool(path: url.path, configuration: config)
        self.dbWriter = dbPool
        
        // 4. 对新专属库自动运行最新版本的 Schema 架构迁移
        try migrator.migrate(dbPool)
        print("✅ [DatabaseManager] 专属物理库已成功切换重挂载 => \(url.lastPathComponent)")
        
        // 5. 广播系统全局通知，引导 EmbeddingManager 和 AppStore 精准完成内存向量/数据实体驱逐与载入
        NotificationCenter.default.post(
            name: .databaseDidSwitch,
            object: nil,
            userInfo: ["vaultID": vaultID]
        )
    }
    
    // MARK: - 专属笔记本库迁移方案 (DatabaseMigrator)
    
    /// 专属笔记本数据库对应的渐进式架构迁移器。
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        // 若在 DEBUG 研发模式下发生不兼容变动，允许就地抹除以加速迭代
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        // V1: 初始工业化架构 - 全表审计标准化
        migrator.registerMigration("v1_initial_schema") { db in
            // 1. 核心知识页面主表
            try db.create(table: AppConstants.Storage.Tables.pages) { t in
                t.column("id", .blob).primaryKey()
                t.column("title", .text).notNull().unique()
                t.column("page_type", .text).notNull().indexed()
                t.column("content", .text).notNull()
                t.column("aliases", .text) // JSON 字符串数组
                t.column("tags", .text)    // JSON 字符串数组
                t.column("status", .text).notNull().defaults(to: "active")
                t.column("confidence", .text).notNull().defaults(to: "medium")
                t.column("sources", .text) // JSON 引用数据
                t.column("related_page_ids", .text) // JSON 关联的 UUID 数组
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

            // 2. 知识图谱双向链接映射表 (物理 ID 级强关联)
            try db.create(table: AppConstants.Storage.Tables.links) { t in
                t.column("source_id", .blob).notNull().references(AppConstants.Storage.Tables.pages, column: "id", onDelete: .cascade)
                t.column("target_id", .blob).notNull().references(AppConstants.Storage.Tables.pages, column: "id", onDelete: .cascade).indexed()
                t.column("context", .text)
                t.column("created_at", .datetime).notNull().defaults(to: Date())
                t.primaryKey(["source_id", "target_id"])
            }

            // 3. 语义块切片表 (RAG 核心承载)
            try db.create(table: AppConstants.Storage.Tables.pageChunks) { t in
                t.column("id", .text).primaryKey()
                t.column("page_id", .blob).notNull().references(AppConstants.Storage.Tables.pages, column: "id", onDelete: .cascade)
                t.column("parent_id", .text).references(AppConstants.Storage.Tables.pageChunks, column: "id", onDelete: .cascade)
                t.column("chunk_type", .text).notNull()
                t.column("content", .text).notNull()
                t.column("anchor_path", .text) // 页面内具体语义锚点 Markdown Header 路径
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

            // 5. 合规治理与 AI 资源开销审计表
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

            // 6. 自动化物理审计时间戳更新触发器
            try db.execute(sql: """
                CREATE TRIGGER trigger_update_pages_timestamp
                AFTER UPDATE ON \(AppConstants.Storage.Tables.pages)
                BEGIN
                    UPDATE \(AppConstants.Storage.Tables.pages) SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
                END;
            """)
        }

        // V2: SQLite 内嵌混合倒排高性能检索 (FTS5 搜索引擎)
        migrator.registerMigration("v2_fts_initial") { db in
            try db.execute(sql: """
                CREATE VIRTUAL TABLE \(AppConstants.Storage.Tables.pagesFTS) USING fts5(
                    id UNINDEXED, title, content, tags, aliases,
                    content='\(AppConstants.Storage.Tables.pages)'
                )
            """)
            try db.execute(sql: """
                CREATE TRIGGER pages_ai AFTER INSERT ON \(AppConstants.Storage.Tables.pages) BEGIN
                    INSERT INTO \(AppConstants.Storage.Tables.pagesFTS)(id, title, content, tags, aliases)
                    VALUES (new.id, new.title, new.content, new.tags, new.aliases);
                END;
            """)
            try db.execute(sql: """
                CREATE TRIGGER pages_ad AFTER DELETE ON \(AppConstants.Storage.Tables.pages) BEGIN
                    INSERT INTO \(AppConstants.Storage.Tables.pagesFTS)(\(AppConstants.Storage.Tables.pagesFTS), id, title, content, tags, aliases)
                    VALUES ('delete', old.id, old.title, old.content, old.tags, old.aliases);
                END;
            """)
            try db.execute(sql: """
                CREATE TRIGGER pages_au AFTER UPDATE ON \(AppConstants.Storage.Tables.pages) BEGIN
                    INSERT INTO \(AppConstants.Storage.Tables.pagesFTS)(\(AppConstants.Storage.Tables.pagesFTS), id, title, content, tags, aliases)
                    VALUES ('delete', old.id, old.title, old.content, old.tags, old.aliases);
                    INSERT INTO \(AppConstants.Storage.Tables.pagesFTS)(id, title, content, tags, aliases)
                    VALUES (new.id, new.title, new.content, new.tags, new.aliases);
                END;
            """)
        }

        // V3: 标签存储范式化与检索性能提速 (Tags DIP 范式)
        migrator.registerMigration("v3_tag_normalization") { db in
            // 1. 创建标签字典表
            try db.create(table: AppConstants.Storage.Tables.tags) { t in
                t.column("id", .text).primaryKey() // 使用标签文本作为主键 ID
                t.column("name", .text).notNull().unique()
                t.column("created_at", .datetime).notNull().defaults(to: Date())
            }

            // 2. 创建页面-标签多对多关联关联表
            try db.create(table: AppConstants.Storage.Tables.pageTags) { t in
                t.column("page_id", .blob).notNull().references(AppConstants.Storage.Tables.pages, column: "id", onDelete: .cascade)
                t.column("tag_id", .text).notNull().references(AppConstants.Storage.Tables.tags, column: "id", onDelete: .cascade)
                t.primaryKey(["page_id", "tag_id"])
            }

            // 3. 历史存量数据平滑迁移：从 pages.tags JSON 字符串中解离出独立 Tag 实物
            let rows = try Row.fetchAll(db, sql: "SELECT id, tags FROM \(AppConstants.Storage.Tables.pages)")
            for row in rows {
                let pageID: Data = row["id"]
                let tagsJSON: String? = row["tags"]
                if let data = tagsJSON?.data(using: .utf8),
                   let tags = try? JSONDecoder().decode([String].self, from: data) {
                     for tagName in tags {
                         // 建立基础标签记录 (如存在则忽略)
                         try db.execute(sql: "INSERT OR IGNORE INTO \(AppConstants.Storage.Tables.tags) (id, name, created_at) VALUES (?, ?, ?)", arguments: [tagName, tagName, Date()])
                         // 绑定多对多关联
                         try db.execute(sql: "INSERT OR IGNORE INTO \(AppConstants.Storage.Tables.pageTags) (page_id, tag_id) VALUES (?, ?)", arguments: [pageID, tagName])
                     }
                }
            }
        }

        // V4: 增加 SRS 间隔重复算法元数据表 (@P1: 促进卡片知识内化吸收)
        migrator.registerMigration("v4_srs_metadata") { db in
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

        return migrator
    }

    // MARK: - 全局数据库迁移方案 (DatabaseMigrator)
    
    /// 全局数据库对应的架构迁移器。
    private var globalMigrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        
        migrator.registerMigration("v1_global_schema") { db in
            // 1. 笔记本元数据主表：托管所有多笔记本卡片信息
            try db.create(table: AppConstants.Storage.Tables.globalVaults) { t in
                t.column("id", .text).primaryKey() // 使用 UUID 字符串
                t.column("name", .text).notNull()
                t.column("path", .text).notNull()
                t.column("icon", .text)
                t.column("created_at", .datetime).notNull().defaults(to: Date())
                t.column("updated_at", .datetime).notNull().defaults(to: Date())
                t.column("last_accessed_at", .datetime).notNull().defaults(to: Date())
            }
            
            // 2. 物理文件防篡改 HMAC 完整性指纹表：取代原 UserDefaults 强寄生
            try db.create(table: AppConstants.Storage.Tables.fileSignatures) { t in
                t.column("file_path", .text).primaryKey()
                t.column("signature", .text).notNull()
                t.column("salt", .text).notNull()
                t.column("created_at", .datetime).notNull().defaults(to: Date())
                t.column("updated_at", .datetime).notNull().defaults(to: Date())
            }
            
            // 3. 全局设置表：系统级全局偏好持久化
            try db.create(table: AppConstants.Storage.Tables.globalSettings) { t in
                t.column("key", .text).primaryKey()
                t.column("value", .text).notNull()
                t.column("updated_at", .datetime).notNull().defaults(to: Date())
            }
            
            // 4. 全局安全及 Token 损耗审计日志表
            try db.create(table: AppConstants.Storage.Tables.auditLogs) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("action", .text).notNull()
                t.column("details", .text)
                t.column("created_at", .datetime).notNull().defaults(to: Date())
            }
        }
        
        return migrator
    }

    /// 重置并释放所有已挂载的数据库 Pool 连接资源（在物理移动、抹除文件或退出登录前必须强制调用）。
    func reset() {
        dbWriter = nil
        globalWriter = nil
        dbURL = nil
        globalDBURL = nil
    }
}

// MARK: - 核心通知扩展

extension Notification.Name {
    /// 专属数据库多库热切换成功完成时的全局广播通知。
    static let databaseDidSwitch = Notification.Name("databaseDidSwitch")
}

// MARK: - 物理隔离层强类型异常

enum DatabaseError: Error {
    /// 数据库连接池配置或建立失败。
    case initializationFailed
}
