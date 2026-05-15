// KnowledgePageStore.swift
//
// 作者: Wang Chong
// 功能说明: 本文件实现了知识管理系统的核心持久化引擎，封装了基于 GRDB 的高性能数据库访问逻辑。
// 核心职责：
// 1. 全文搜索 (FTS5)：集成 SQLite FTS5 虚拟表技术。
// 2. 向量化索引 (RAG)：存储页面分块与嵌入向量。
// 3. 原子性保障：实现线程安全的读写分离与事务控制。
// MARK: [SR-01] 所有用户原始文档严禁在未经授权的情况下上传至云端
// MARK: [RR-01] 数据库事务必须满足 ACID 特性，确保数据不损坏
// 版本: 1.2
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
import GRDB

// MARK: - 数据库 Record 模型

/// 页面链接模型 (用于反向链接 O(1) 查询)
struct PageLink: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "links"

    var sourceID: UUID
    var targetTitle: String
    var context: String?

    enum CodingKeys: String, CodingKey {
        case sourceID = "source_id"
        case targetTitle = "target_title"
        case context
    }
}

/// 页面嵌入向量模型
struct PageEmbedding: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "page_embeddings"

    var id: UUID
    var vectorBlob: Data
    var modelName: String
    var updated: Date

    enum CodingKeys: String, CodingKey {
        case id
        case vectorBlob = "vector_blob"
        case modelName = "model_name"
        case updated
    }

    var vector: [Float] {
        let count = vectorBlob.count / MemoryLayout<Float>.size
        return vectorBlob.withUnsafeBytes { pointer in
            Array(UnsafeBufferPointer(start: pointer.baseAddress?.assumingMemoryBound(to: Float.self), count: count))
        }
    }

    init(id: UUID, vector: [Float], modelName: String, updated: Date = Date()) {
        self.id = id
        self.vectorBlob = Data(bytes: vector, count: vector.count * MemoryLayout<Float>.size)
        self.modelName = modelName
        self.updated = updated
    }
}

/// 页面分块模型 (升级版：支持父子块与多维索引)
struct PageChunk: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "page_chunks"

    var id: String
    var pageID: UUID
    var parentID: String? // 支持 Small-to-Big: 子块指向父块的 ID
    var chunkType: String // "regular", "summary", "qa_pair"
    var content: String
    var embedding: Data?
    var startIndex: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case pageID = "page_id"
        case parentID = "parent_id"
        case chunkType = "chunk_type"
        case content
        case embedding
        case startIndex = "start_index"
    }
}

/// 页面全文搜索映射模型
struct KnowledgePageFTS: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "pages_fts"
    var title: String
    var content: String
    var tags: String
    var aliases: String
}

/// Token 使用记录模型
struct TokenUsage: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "token_usage"
    var id: Int64?
    var model: String
    var promptTokens: Int
    var completionTokens: Int
    var totalTokens: Int
    var created: Date

    enum CodingKeys: String, CodingKey {
        case id, model
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
        case created
    }
}

// MARK: - 核心存储 (KnowledgePageStore)

/// 知识库 页面存储：封装所有基于 GRDB 的高性能 CRUD 操作。
final class KnowledgePageStore: Sendable {
    private let dbWriter: any DatabaseWriter

    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }

    // MARK: - 页面操作 (实现 Upsert 逻辑)

    @discardableResult
    func save(_ page: KnowledgePage) throws -> UUID {
        try dbWriter.write { db in
            try save(page, in: db)
        }
    }

    /// 在已有数据库事务中保存页面及其关联链接，返回实际使用的 ID
    @discardableResult
    func save(_ page: KnowledgePage, in db: Database) throws -> UUID {
        let savedID = try upsert(page, in: db)
        try saveLinks(sourceID: savedID, targetTitles: page.outgoingLinks, in: db)
        return savedID
    }

    /// 执行具体的 Upsert 逻辑：根据标题查找，存在则更新，不存在则插入。返回保存后的 ID。
    private func upsert(_ page: KnowledgePage, in db: Database) throws -> UUID {
        if let existing = try KnowledgePage.filter(Column("title") == page.title).fetchOne(db) {
            // 如果标题已存在，则保持原有的 ID 不变，执行更新操作
            var updatedPage = page
            updatedPage.id = existing.id
            // 继承原有页面的创建时间
            updatedPage.created = existing.created
            try updatedPage.update(db)
            return existing.id
        } else {
            // 标题不存在，执行新插入
            try page.insert(db)
            return page.id
        }
    }

    func delete(id: UUID) throws {
        _ = try dbWriter.write { db in
            try KnowledgePage.deleteOne(db, id: id)
        }
    }

    func fetchAll() throws -> [KnowledgePage] {
        try dbWriter.read { db in
            try KnowledgePage.order(Column("updated").desc).fetchAll(db)
        }
    }

    func fetchByID(_ id: UUID) throws -> KnowledgePage? {
        try dbWriter.read { db in
            try KnowledgePage.fetchOne(db, id: id)
        }
    }

    func fetchByTitle(_ title: String) throws -> KnowledgePage? {
        try dbWriter.read { db in
            try KnowledgePage.filter(Column("title") == title).fetchOne(db)
        }
    }

    // MARK: - 全文搜索 (FTS5)

    func search(query: String) throws -> [KnowledgePage] {
        try dbWriter.read { db in
            guard let pattern = FTS5Pattern(matchingAllPrefixesIn: query) else { return [] }

            // 说明：由于 FTS5 的 MATCH 和 rank 排序在处理跨表 Association 时
            // 容易引发 Swift 编译器复杂的类型推断错误，此处采用 GRDB 推荐的 SQL 映射模式。
            // 这种方式在处理 FTS5 虚拟表关联时性能最优且逻辑最直观。
            let sql = """
                SELECT \(AppConstants.Storage.Tables.pages).* FROM \(AppConstants.Storage.Tables.pages)
                JOIN \(AppConstants.Storage.Tables.pagesFTS) ON \(AppConstants.Storage.Tables.pages).rowid = \(AppConstants.Storage.Tables.pagesFTS).rowid
                WHERE \(AppConstants.Storage.Tables.pagesFTS) MATCH ?
                ORDER BY rank
            """
            return try KnowledgePage.fetchAll(db, sql: sql, arguments: [pattern])
        }
    }

    // MARK: - 反向链接 (Links)

    func saveLinks(sourceID: UUID, targetTitles: [String]) throws {
        try dbWriter.write { db in
            try saveLinks(sourceID: sourceID, targetTitles: targetTitles, in: db)
        }
    }

    /// 在给定数据库连接中保存链接（内部使用）
    private func saveLinks(sourceID: UUID, targetTitles: [String], in db: Database) throws {
        try PageLink.filter(Column("source_id") == sourceID).deleteAll(db)
        for title in targetTitles {
            let link = PageLink(sourceID: sourceID, targetTitle: title)
            try link.insert(db)
        }
    }

    func fetchBacklinks(for targetTitle: String) throws -> [UUID] {
        try dbWriter.read { db in
            let links = try PageLink.filter(Column("target_title") == targetTitle).fetchAll(db)
            return links.map { $0.sourceID }
        }
    }

    // MARK: - 向量存储 (Embeddings)

    func saveEmbedding(id: UUID, vector: [Float], modelName: String) throws {
        let entry = PageEmbedding(id: id, vector: vector, modelName: modelName)
        try dbWriter.write { db in
            try entry.save(db)
        }
    }

    func fetchAllEmbeddings() throws -> [UUID: [Float]] {
        try dbWriter.read { db in
            let records = try PageEmbedding.fetchAll(db)
            var dict: [UUID: [Float]] = [:]
            for record in records {
                dict[record.id] = record.vector
            }
            return dict
        }
    }

    // MARK: - 统计

    func count(type: PageType? = nil) throws -> Int {
        try dbWriter.read { db in
            if let type = type {
                return try KnowledgePage.filter(Column("type") == type.rawValue).fetchCount(db)
            }
            return try KnowledgePage.fetchCount(db)
        }
    }

    func deleteAll() throws {
        _ = try dbWriter.write { db in
            try KnowledgePage.deleteAll(db)
        }
    }

    // MARK: - 高级 RAG 分块操作

    /// 批量保存页面分块（支持父子关系与多维索引）
    func saveChunks(pageID: UUID, chunks: [PageChunk]) throws {
        try dbWriter.write { db in
            // 物理删除旧分块，确保索引最新
            try PageChunk.filter(Column("page_id") == pageID).deleteAll(db)
            for chunk in chunks {
                try chunk.insert(db)
            }
        }
    }

    // MARK: - 资源统计 (Tokens & Storage)

    /// 记录 LLM 调用详情 (Token + 时延 + 状态)
    func recordLLMCall(model: String, prompt: Int, completion: Int, latency: Int, status: String = AppConstants.Storage.defaultCallStatus) throws {
        try dbWriter.write { db in
            try db.execute(sql: """
                INSERT INTO \(AppConstants.Storage.Tables.llmCallLogs) (model, prompt_tokens, completion_tokens, latency_ms, status, \(AppConstants.Storage.Columns.created))
                VALUES (?, ?, ?, ?, ?, ?)
            """, arguments: [model, prompt, completion, latency, status, Date()])

            // 同时更新汇总表 token_usage (保持向前兼容)
            try db.execute(sql: """
                INSERT INTO \(AppConstants.Storage.Tables.tokenUsage) (model, prompt_tokens, completion_tokens, total_tokens, \(AppConstants.Storage.Columns.created))
                VALUES (?, ?, ?, ?, ?)
            """, arguments: [model, prompt, completion, prompt + completion, Date()])
        }
    }

    /// 获取最近 30 天的详细响应时延统计 (平均、最大、最小、次数)
    func fetchLatencyStats() throws -> (avg: Int, max: Int, min: Int, count: Int) {
        try dbWriter.read { db in
            let row = try Row.fetchOne(db, sql: """
                SELECT 
                    AVG(latency_ms) as avg, 
                    MAX(latency_ms) as max, 
                    MIN(latency_ms) as min, 
                    COUNT(*) as count 
                FROM llm_call_logs 
                WHERE created > ?
            """, arguments: [Date().addingTimeInterval(-AppConstants.Storage.thirtyDaysSeconds)])
            
            return (
                avg: Int(row?["avg"] ?? 0),
                max: Int(row?["max"] ?? 0),
                min: Int(row?["min"] ?? 0),
                count: Int(row?["count"] ?? 0)
            )
        }
    }

    /// 获取过去 30 天的每日 AI 资源统计 (Token 与 请求次数)
    func fetchDailyAIStats() throws -> [(date: String, tokens: Int, requests: Int)] {
        try dbWriter.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT strftime('%Y-%m-%d', created) as day, SUM(total_tokens) as tokens, COUNT(*) as requests
                FROM token_usage
                WHERE created >= date('now', '-30 days')
                GROUP BY day
                ORDER BY day ASC
            """)
            return rows.map { ($0["day"], $0["tokens"], $0["requests"]) }
        }
    }

    /// 获取按月的 Token 统计
    func fetchMonthlyTokenStats() throws -> [(month: String, total: Int)] {
        try dbWriter.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT strftime('%Y-%m', created) as month, SUM(total_tokens) as total
                FROM token_usage
                GROUP BY month
                ORDER BY month ASC
            """)
            return rows.map { ($0["month"], $0["total"]) }
        }
    }

    /// 获取存储空间分布统计 (基于类型)
    /// 核心逻辑：优先使用物理 fileSize，若缺失则基于 content 长度进行估算 (UTF-16 字节 + 500B 元数据开销)
    func fetchStorageStats() throws -> (total: Int64, byType: [String: (size: Int64, count: Int)], dbSize: Int64) {
        try dbWriter.read { db in
            // 1. 获取按类型的聚合统计
            let rows = try Row.fetchAll(db, sql: """
                SELECT 
                    type, 
                    COUNT(*) as count,
                    SUM(COALESCE(\(AppConstants.Storage.Columns.fileSize), LENGTH(content) * 2 + 500)) as size
                FROM \(AppConstants.Storage.Tables.pages) 
                GROUP BY type
            """)
            
            var byType: [String: (size: Int64, count: Int)] = [:]
            var total: Int64 = 0
            
            for row in rows {
                let type: String = row["type"]
                let size: Int64 = row["size"] ?? 0
                let count: Int = row["count"]
                byType[type] = (size, count)
                total += size
            }

            // 2. 获取数据库物理文件大小
            let dbPathRow = try Row.fetchOne(db, sql: "PRAGMA database_list")
            let dbPath = dbPathRow?["file"] as? String ?? ""
            let dbSize = (try? FileManager.default.attributesOfItem(atPath: dbPath)[.size] as? Int64) ?? 0

            return (total, byType, dbSize)
        }
    }

    /// 获取导入与自建统计 (计数与大小)
    func fetchProvenanceStats() throws -> (importedCount: Int, importedSize: Int64, createdCount: Int, createdSize: Int64) {
        try dbWriter.read { db in
            // 导入的页面通常带有 "ingested" 标签
            let imported = try Row.fetchOne(db, sql: "SELECT COUNT(*) as count, SUM(\(AppConstants.Storage.Columns.fileSize)) as size FROM \(AppConstants.Storage.Tables.pages) WHERE tags LIKE '%ingested%'")
            let total = try Row.fetchOne(db, sql: "SELECT COUNT(*) as count, SUM(\(AppConstants.Storage.Columns.fileSize)) as size FROM \(AppConstants.Storage.Tables.pages)")

            let iCount: Int = imported?["count"] ?? 0
            let iSize: Int64 = imported?["size"] ?? 0
            let tCount: Int = total?["count"] ?? 0
            let tSize: Int64 = total?["size"] ?? 0

            return (iCount, iSize, tCount - iCount, tSize - iSize)
        }
    }

    /// 获取所有带有向量的分块（用于高性能内存检索）
    func fetchAllChunksWithEmbeddings() throws -> [PageChunk] {
        try dbWriter.read { db in
            try PageChunk.filter(Column("embedding") != nil).fetchAll(db)
        }
    }

    // MARK: - 数据清洗 (Cleaning)

    /// 清洗重复分块：识别并删除内容重复的分块
    func cleanupDuplicateChunks() throws -> Int {
        try dbWriter.write { db in
            // 使用 SQL 找出重复的内容并保留最小 ID 的那一条
            _ = try db.execute(sql: """
                DELETE FROM \(AppConstants.Storage.Tables.pageChunks)
                WHERE id NOT IN (
                    SELECT MIN(id)
                    FROM \(AppConstants.Storage.Tables.pageChunks)
                    GROUP BY content, page_id
                )
            """)
            return db.changesCount
        }
    }

    /// 清洗孤儿分块：删除关联页面已不存在的分块
    func cleanupOrphanedChunks() throws -> Int {
        try dbWriter.write { db in
            _ = try db.execute(sql: """
                DELETE FROM \(AppConstants.Storage.Tables.pageChunks)
                WHERE page_id NOT IN (SELECT id FROM \(AppConstants.Storage.Tables.pages))
            """)
            return db.changesCount
        }
    }

    // MARK: - 质量评估 (Benchmark)

    /// 保存 RAG 评估结果
    func saveEvaluation(query: String, answer: String, scores: [String: Double], model: String) throws {
        try dbWriter.write { db in
            try db.execute(sql: """
                INSERT INTO \(AppConstants.Storage.Tables.ragEvaluations) (query, answer, \(AppConstants.Storage.Columns.faithfulness), \(AppConstants.Storage.Columns.relevance), \(AppConstants.Storage.Columns.precision), evaluator_model, \(AppConstants.Storage.Columns.created))
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, arguments: [
                query, answer,
                scores["faithfulness"] ?? 0,
                scores["relevance"] ?? 0,
                scores["precision"] ?? 0,
                model, Date()
            ])
        }
    }

    /// 获取最近的评估分数分布
    func fetchEvaluationStats() throws -> [String: Double] {
        try dbWriter.read { db in
            let row = try Row.fetchOne(db, sql: """
                SELECT AVG(\(AppConstants.Storage.Columns.faithfulness)), AVG(\(AppConstants.Storage.Columns.relevance)), AVG(\(AppConstants.Storage.Columns.precision))
                FROM \(AppConstants.Storage.Tables.ragEvaluations)
            """)
            return [
                "faithfulness": row?[0] ?? 0,
                "relevance": row?[1] ?? 0,
                "precision": row?[2] ?? 0
            ]
        }
    }
}

// MARK: - GRDB 关联定义

extension KnowledgePage {
    /// 定义 FTS5 关联，使用 rowid 进行连接
    @MainActor
    static let contentSnapshot = belongsTo(KnowledgePageFTS.self, using: ForeignKey(["rowid"], to: ["rowid"]))
}
