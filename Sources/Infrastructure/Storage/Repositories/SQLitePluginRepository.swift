//
//  SQLitePluginRepository.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/30.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L1] 基础设施层
//  核心职责：基于 GRDB 的插件仓储实现，持久化插件元数据、状态及运行时统计至全局数据库。
//
import Foundation
@preconcurrency import GRDB

/// 基于 GRDB 的插件持久化仓储实现，操作全局共享数据库（global.sqlite3）。
final class SQLitePluginRepository: PluginRepository, @unchecked Sendable {
    private let dbWriter: any DatabaseWriter

    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }

    // MARK: - CRUD

    func fetchAllInstalled() async throws -> [PluginRecord] {
        try await dbWriter.read { db in
            try PluginRecord
                .order(PluginRecord.Columns.updatedAt.desc)
                .fetchAll(db)
        }
    }

    func fetch(id: String) async throws -> PluginRecord? {
        try await dbWriter.read { db in
            try PluginRecord
                .filter(PluginRecord.Columns.id == id)
                .fetchOne(db)
        }
    }

    func save(_ record: PluginRecord) async throws {
        try await dbWriter.write { db in
            // upsert：存在则更新，不存在则插入
            if var existing = try PluginRecord
                .filter(PluginRecord.Columns.id == record.id)
                .fetchOne(db) {
                existing.name = record.name
                existing.version = record.version
                existing.author = record.author
                existing.source = record.source
                existing.status = record.status
                existing.permissionsJSON = record.permissionsJSON
                existing.loadDuration = record.loadDuration
                existing.unloadDuration = record.unloadDuration
                existing.totalExecutionTime = record.totalExecutionTime
                existing.callCount = record.callCount
                existing.manifestJSON = record.manifestJSON
                try existing.update(db)
            } else {
                var newRecord = record
                try newRecord.insert(db)
            }

            // 同步 FTS5 索引
            try self.syncFTS(db, record: record)
        }
    }

    func delete(id: String) async throws {
        try await dbWriter.write { db in
            try PluginRecord
                .filter(PluginRecord.Columns.id == id)
                .deleteAll(db)

            // 清理 FTS5 索引
            try PluginRecordFTS
                .filter(Column("id") == id)
                .deleteAll(db)
        }
    }

    // MARK: - 搜索

    func search(query: String) async throws -> [PluginRecord] {
        try await dbWriter.read { db in
            // FTS5 全文搜索
            if let pattern = FTS5Pattern(matchingAnyTokenIn: query) {
                let ftsMatches = try PluginRecordFTS
                    .matching(pattern)
                    .limit(50)
                    .fetchAll(db)

                if !ftsMatches.isEmpty {
                    let matchIDs = ftsMatches.map { $0.id }
                    return try PluginRecord
                        .filter(matchIDs.contains(PluginRecord.Columns.id))
                        .fetchAll(db)
                }
            }

            // 降级 LIKE 模糊搜索
            let likePattern = "%\(query)%"
            return try PluginRecord
                .filter(
                    PluginRecord.Columns.name.like(likePattern) ||
                    PluginRecord.Columns.author.like(likePattern)
                )
                .order(PluginRecord.Columns.updatedAt.desc)
                .fetchAll(db)
        }
    }

    // MARK: - 统计更新

    func updateStats(id: String, loadDuration: Double?, unloadDuration: Double?,
                     totalExecutionTime: Double?, callCount: Int?, status: String?) async throws {
        try await dbWriter.write { db in
            guard var record = try PluginRecord
                .filter(PluginRecord.Columns.id == id)
                .fetchOne(db) else {
                return
            }

            if let v = loadDuration { record.loadDuration = v }
            if let v = unloadDuration { record.unloadDuration = v }
            if let v = totalExecutionTime { record.totalExecutionTime = v }
            if let v = callCount { record.callCount = v }
            if let v = status { record.status = v }
            try record.update(db)

            // 同步 FTS5 索引
            try self.syncFTS(db, record: record)
        }
    }

    func deleteAll() async throws {
        try await dbWriter.write { db in
            try PluginRecord.deleteAll(db)
            try PluginRecordFTS.deleteAll(db)
        }
    }

    // MARK: - FTS5 同步

    /// 将主表记录同步至 FTS5 虚拟表（upsert）
    private func syncFTS(_ db: Database, record: PluginRecord) throws {
        // 从 manifestJSON 中提取 description（使用匿名结构体避开 @MainActor 限制）
        var desc = ""
        if let data = record.manifestJSON.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let lang = Locale.current.language.languageCode?.identifier ?? "en"
            if let descriptions = json["descriptions"] as? [String: String] {
                desc = descriptions[lang] ?? descriptions["en"] ?? descriptions.values.first ?? ""
            }
        }

        // 先删除旧索引再插入（FTS5 不支持 update）
        try PluginRecordFTS
            .filter(Column("id") == record.id)
            .deleteAll(db)

        let ftsRecord = PluginRecordFTS(
            id: record.id,
            name: record.name,
            author: record.author,
            description: desc
        )
        try ftsRecord.insert(db)
    }
}
