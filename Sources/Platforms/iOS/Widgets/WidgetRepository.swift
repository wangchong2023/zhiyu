//
//  WidgetRepository.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/10.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：Widget Extension 专用 Repository，封装 App Group 数据库只读访问。
//           遵循 Model (WidgetModels) + Repository 模式，杜绝原始 SQL。

import Foundation
import GRDB

/// Widget 专用数据仓储（只读 Repository）
enum WidgetRepository {

    // MARK: - 路径解析

    private static let appGroupID = "group.com.zhiyu.app"

    private static var groupURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    /// 解析当前活跃 vault 的数据库 URL
    static func resolveActiveVaultDatabaseURL() -> URL? {
        guard let globalURL = groupURL?.appendingPathComponent("global.sqlite3"),
              FileManager.default.fileExists(atPath: globalURL.path) else {
            return nil
        }
        do {
            var config = Configuration()
            config.readonly = true
            let pool = try DatabasePool(path: globalURL.path, configuration: config)
            defer { try? pool.close() }

            let vaultsKey = "vaults.selectedID"
            let row = try pool.read { db in
                try WidgetGlobalSettingRow
                    .filter(WidgetGlobalSettingRow.Columns.key == vaultsKey)
                    .fetchOne(db)
            }
            guard let uuidString = row?.value,
                  let _ = UUID(uuidString: uuidString) else { return nil }

            return groupURL?
                .appendingPathComponent("Vaults")
                .appendingPathComponent(uuidString)
                .appendingPathComponent("vault.sqlite3")
        } catch {
            return nil
        }
    }

    // MARK: - 连接管理

    private static func openReadOnlyPool(at url: URL) throws -> DatabasePool {
        var config = Configuration()
        config.readonly = true
        config.qos = .utility
        return try DatabasePool(path: url.path, configuration: config)
    }

    // MARK: - 查询 API（生产环境：从 App Group 文件读取）

    static func fetchStats() async -> WidgetStats {
        guard let dbURL = resolveActiveVaultDatabaseURL(),
              FileManager.default.fileExists(atPath: dbURL.path),
              let pool = try? openReadOnlyPool(at: dbURL) else {
            return WidgetStats(pageCount: 0, linkCount: 0, tagCount: 0)
        }
        defer { try? pool.close() }
        return await fetchStats(from: pool)
    }

    static func fetchRecentPages(limit: Int = 3) async -> [WidgetRecentPage] {
        guard let dbURL = resolveActiveVaultDatabaseURL(),
              FileManager.default.fileExists(atPath: dbURL.path),
              let pool = try? openReadOnlyPool(at: dbURL) else {
            return []
        }
        defer { try? pool.close() }
        return await fetchRecentPages(from: pool, limit: limit)
    }

    // MARK: - 查询 API（可测试：接受 DatabaseWriter 参数）

    /// 从指定数据库获取统计数据（用于单元测试注入内存 DB）
    static func fetchStats(from writer: some DatabaseWriter) async -> WidgetStats {
        do {
            let pageCount = try await writer.read { db in try WidgetPageRow.fetchCount(db) }
            let linkCount = try await writer.read { db in try WidgetLinkRow.fetchCount(db) }
            let tagCount = try await writer.read { db in try fetchDistinctTagCount(db) }
            return WidgetStats(pageCount: pageCount, linkCount: linkCount, tagCount: tagCount)
        } catch {
            return WidgetStats(pageCount: 0, linkCount: 0, tagCount: 0)
        }
    }

    /// 从指定数据库获取最近更新页列表（用于单元测试注入内存 DB）
    static func fetchRecentPages(from writer: some DatabaseWriter, limit: Int = 3) async -> [WidgetRecentPage] {
        do {
            let rows = try await writer.read { db in
                try WidgetPageRow
                    .select(WidgetPageRow.Columns.title, WidgetPageRow.Columns.pageType)
                    .order(WidgetPageRow.Columns.updatedAt.desc)
                    .limit(limit)
                    .fetchAll(db)
            }
            return rows.map { row in
                let typeName = row.pageType.isEmpty ? "concept" : row.pageType
                let colorName = typeName == "concept" ? "accent" : "purple"
                return WidgetRecentPage(title: row.title, typeName: typeName, colorName: colorName)
            }
        } catch {
            return []
        }
    }

    // MARK: - 内部辅助

    private static func fetchDistinctTagCount(_ db: Database) throws -> Int {
        let rows = try Row.fetchAll(db, WidgetPageRow
            .select(WidgetPageRow.Columns.tags)
            .filter(WidgetPageRow.Columns.tags != nil)
        )
        let rawTags: [String] = rows.compactMap { $0[WidgetPageRow.Columns.tags] }
        let allTags = rawTags.flatMap { json -> [String] in
            guard let data = json.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        return Set(allTags).count
    }
}
