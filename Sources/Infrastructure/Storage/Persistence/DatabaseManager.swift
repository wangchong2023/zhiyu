//
//  DatabaseManager.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：属于 Persistence 模块，提供相关的结构体或工具支撑。
//
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
        self.isInTesting = true
        
        // 核心步骤 1：对测试环境下的专属瞬态内存主数据库跑 Schema 架构迁移，建立完整的物理表、虚拟表（如 FTS5）与触发器
        try migrator.migrate(writer)
        
        // 核心步骤 2：单独开辟一个独立的内存型全局配置数据库，彻底隔离并规避不同迁移器对 grdb_migrations 表的命名冲突与擦除问题
        let globalQueue = try DatabaseQueue()
        self.globalWriter = globalQueue
        try globalMigrator.migrate(globalQueue)
        
        let tables = try writer.read { db in
            try String.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type='table'")
        }
        let globalTables = try globalQueue.read { db in
            try String.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type='table'")
        }
        print("📊 [DatabaseManager] setupForTesting completed.")
        print("   - Vault Tables: \(tables)")
        print("   - Global Tables: \(globalTables)")
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
        
        // 2. 配置连接池并注入物理调优 PRAGMA 参数
        let config = createDatabaseConfiguration()
        
        // 3. 建立连接并自动运行全局迁移
        let globalPool = try DatabasePool(path: path, configuration: config)
        self.globalWriter = globalPool
        
        try globalMigrator.migrate(globalPool)
        print("🌍 [DatabaseManager] Global main configuration database initialized successfully: \(url.lastPathComponent)")
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
        
        let config = createDatabaseConfiguration()
        
        let dbPool = try DatabasePool(path: path, configuration: config)
        self.dbWriter = dbPool
        
        // 3. 执行专属库架构迁移
        try migrator.migrate(dbPool)
    }
    
    /// 物理热切换当前激活的专属笔记本数据库（Multi-Vault Switching）。
    ///
    /// - 架构防死锁与 WAL 连接池生命周期深度设计规范 (WAL Exclusive Lock Release & Anti-Deadlock Specification):
    ///   在多租户 (Multi-Vault) 热插拔架构中，由于 SQLite 启用了高性能的 WAL (Write-Ahead Logging) 模式，
    ///   操作系统会在沙盒中生成并映射 `.sqlite3`、`.sqlite3-wal` 及 `.sqlite3-shm` 三个物理文件。
    ///   
    ///   ```
    ///   ┌────────────────────────────────────────────────────────┐
    ///   │           SQLite WAL 并发独占锁释放与重构生命周期           │
    ///   └────────────────────────────────────────────────────────┘
    ///         [旧数据库激活]
    ///               │
    ///               ▼
    ///         1. 显式 dbWriter = nil  ──► 触发 ARC 同步析构，注销所有 Reader / Writer 句柄
    ///               │                      物理闭合并刷新 .sqlite3-wal 缓存，彻底释放 Shared/Exclusive 锁
    ///               ▼
    ///         2. 重定向 dbURL = url   ──► 指向新物理笔记本路径
    ///               │
    ///               ▼
    ///         3. 重建 DatabasePool   ──► 动态开辟全新隔离的连接池通道
    ///               │
    ///               ▼
    ///         4. 跑 Schema 架构迁移  ──► 自动化建立新专属库元数据与虚拟表
    ///               │
    ///               ▼
    ///         5. 广播 databaseDidSwitch 通知 ──► 各子服务（Embedding/Search）执行内存缓存强力驱逐
    ///   ```
    ///   
    ///   [死锁场景剖析 (Deadlock Risk)]：
    ///   如果之前的 `DatabasePool` 连接句柄没有被 100% 销毁，它的多个读取连接与写入连接可能仍隐式保持着 SQLite 的
    ///   Shared 或 Reserved/Exclusive 锁状态。若此时立即去加载、删除、移动或者在其他线程重入读写这个数据库文件，
    ///   将瞬间触发 SQLite 的 `SQLITE_BUSY` (数据库锁对撞)，甚至导致系统主线程永久性锁死死锁。
    ///
    ///   [金牌防死锁架构解决路径]：
    ///   1. **步骤一 (物理断联释放锁)**：显式执行 `self.dbWriter = nil`。根据 Swift ARC 机制，这会触发旧 `DatabasePool` 实例
    ///      及其底层所有活跃 SQLite 句柄的**同步析构与强物理销毁**。这一步是释放 SQLite WAL 锁、将缓冲区刷新至磁盘、
    ///      并强行解开文件独占锁的黄金法门。
    ///   2. **步骤二 (物理重定向)**：确立全新的 `self.dbURL = url`。
    ///   3. **步骤三 (串行重建与安全隔离)**：在此基础上重新配置并唤醒目标物理库的并发 Pool，以隔离态重新跑 Schema 迁移，
    ///      物理切断新旧库之间的任何锁传染通路。
    ///
    /// - Parameters:
    ///   - vaultID: 切换目标笔记本的唯一识别码 UUID。
    ///   - url: 目标笔记本数据库在沙盒中的物理绝对路径 URL。
    /// - Throws: 断开挂载异常、新库 GRDB Pool 实例化异常或架构版本不兼容升级失败。
    func switchDatabase(to vaultID: UUID, at url: URL) throws {
        print("🔄 [DatabaseManager] Starting physical multi-database hot swap => Target: \(url.lastPathComponent)")
        
        // 1. 【安全核心步骤】：显式重置为 nil 以强制触发旧专属库 DatabasePool 资源 ARC 同步析构
        // 彻底释放 WAL 模式下对 .sqlite3-wal 及 .sqlite3-shm 物理文件的读写独占锁，防止后续多库切换或物理移动擦除时发生 SQLITE_BUSY 死锁。
        self.dbWriter = nil
        self.dbURL = url
        
        // 2. 确保目标文件夹在沙盒中物理存在
        let folderURL = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        
        // 3. 重新配置并开辟新库的并发池连接，确保外键约束正常挂载
        // 3. 重新配置并开辟新库的并发池连接，应用高性能调优 PRAGMA
        let config = createDatabaseConfiguration()
        
        let dbPool = try DatabasePool(path: url.path, configuration: config)
        self.dbWriter = dbPool
        
        // 4. 对新专属库自动运行最新版本的 Schema 架构迁移（FTS5、Pages、SRS等表级热挂载）
        try migrator.migrate(dbPool)
        print("✅ [DatabaseManager] Exclusive physical database successfully switched and remounted => \(url.lastPathComponent)")
        
        // 5. 广播系统全局通知，引导 EmbeddingManager 和 AppStore 精准完成内存向量/数据实体驱逐与载入，重置搜索索引状态
        NotificationCenter.default.post(
            name: .databaseDidSwitch,
            object: nil,
            userInfo: ["vaultID": vaultID]
        )
    }
    
    // MARK: - 数据库高性能配置
    
    /// 构建极尽压榨物理 I/O 并发吞吐的 SQLite 高性能配置
    /// 包含：WAL 读写分离最大并发度、NORMAL 同步级别、内存 temp_store、10MB 连接页缓存、256MB mmap 内存映射与 5秒锁延迟。
    private func createDatabaseConfiguration() -> Configuration {
        var config = Configuration()
        
        // 1. 设置并发读取最大线程数（WAL 读写分离高阶连接池）
        config.maximumReaderCount = 5
        // 2. 将读取线程的系统优先调度级别（QoS）调至用户高优先级，防范卡顿
        config.qos = .userInitiated
        
        config.prepareDatabase { db in
            // 3. 开启物理级外键约束
            try db.execute(sql: "PRAGMA foreign_keys = ON")
            // 4. 采用 SQLite NORMAL 同步模式：WAL 模式下的黄金同步级别，兼顾 100% 事务安全性与超高写吞吐
            try db.execute(sql: "PRAGMA synchronous = NORMAL")
            // 5. 将临时表及中间索引文件全部强制置于 RAM 内存中，缩短排序耗时
            try db.execute(sql: "PRAGMA temp_store = MEMORY")
            // 6. 分配 10MB 的连接级大页面缓存页（缓存大小为 10000 字节，负数代表以 KB 为单位）
            try db.execute(sql: "PRAGMA cache_size = -10000")
            // 7. 启用 256MB 的内存映射 I/O，极速加载 FTS5 全文索引虚拟表，免除系统调用开销
            try db.execute(sql: "PRAGMA mmap_size = 268435456")
            // 8. 设定 5000 毫秒锁等待超时，打消多线程冷读写瞬时争用触发的 SQLITE_BUSY 风险
            try db.execute(sql: "PRAGMA busy_timeout = 5000")
        }
        
        return config
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

// MARK: - VaultDatabaseSwitcher 协议遵循

extension DatabaseManager: VaultDatabaseSwitcher {
    /// 物理断开专属物理数据库连接以闭合通道锁并安全刷新 WAL。
    ///
    /// 此方法显式将 `dbWriter` 置为 nil。通过 Swift ARC 机制，这会触发底层已挂载的
    /// `DatabasePool` 及其全部活跃的 SQLite 读写连接句柄的同步析构与销毁。
    /// 这一步骤是强物理释放 WAL 文件锁、规避 `SQLITE_BUSY` 死锁风险的关键环节。
    public func releaseDatabaseConnection() {
        // 核心步骤：显式重置专属物理库写入池，利用 Swift ARC 触发析构以释放 WAL 文件锁
        self.dbWriter = nil
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
