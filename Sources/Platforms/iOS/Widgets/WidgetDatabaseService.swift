//
//  WidgetDatabaseService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/09.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：Widget Extension 专用的轻量级数据库读取服务。
//           遵循 Repository 模式，使用 GRDB 类型安全查询 API。
//           通过 App Group 共享容器只读打开 SQLite 文件。
//
import Foundation
import GRDB

/// Widget Extension 专用的只读数据库服务。
///
/// 设计原则：
/// - Repository 模式：使用 GRDB TableRecord + FetchableRecord，杜绝原始 SQL
/// - 只读打开（config.readonly），零写入风险
/// - 无状态纯函数，每次调用独立连接池
enum WidgetDatabaseService {

    // MARK: - 数据库路径

    /// App Group 共享容器标识符
    private static let appGroupIdentifier = "group.com.zhiyu.app"

    /// 获取 App Group 共享容器中的数据库文件 URL
    private static var databaseURL: URL? {
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            return nil
        }
        return groupURL.appendingPathComponent(AppConstants.Storage.databaseName)
    }

    // MARK: - 数据库连接

    /// 建立只读数据库连接池
    private static func openReadOnlyPool() throws -> DatabasePool {
        guard let dbURL = databaseURL else {
            throw WidgetDatabaseError.appGroupUnavailable
        }
        guard FileManager.default.fileExists(atPath: dbURL.path) else {
            throw WidgetDatabaseError.databaseNotFound
        }
        var config = Configuration()
        config.readonly = true
        config.qos = .utility
        return try DatabasePool(path: dbURL.path, configuration: config)
    }

    // MARK: - 公开 API

    /// 获取知识库统计数据（页面数、链接数、标签数）
    static func fetchStats() async -> WidgetStats {
        do {
            let pool = try openReadOnlyPool()
            defer { try? pool.close() }

            let pageCount = try await pool.read { db in
                try WidgetPageRow.fetchCount(db)
            }

            let linkCount = try await pool.read { db in
                try WidgetLinkRow.fetchCount(db)
            }

            let tagCount = try await pool.read { db in
                try fetchDistinctTagCount(db)
            }

            return WidgetStats(pageCount: pageCount, linkCount: linkCount, tagCount: tagCount)
        } catch {
            print("[WidgetDatabaseService] fetchStats failed: \(error.localizedDescription)")
            return WidgetStats(pageCount: 0, linkCount: 0, tagCount: 0)
        }
    }

    /// 获取最近更新的知识页列表
    /// - Parameter limit: 返回条数，默认 3
    static func fetchRecentPages(
        limit: Int = 3
    ) async -> [WidgetRecentPage] {
        do {
            let pool = try openReadOnlyPool()
            defer { try? pool.close() }

            let rows = try await pool.read { db in
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
            print("[WidgetDatabaseService] fetchRecentPages failed: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - 内部辅助

    /// 统计所有页面中不重复标签的总数。
    /// tags 列存储为 JSON 字符串数组（如 `["tag1","tag2"]`），
    /// 需要解析所有行的 JSON 后在内存中 deduplicate。
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

// MARK: - 错误类型

/// Widget 数据库服务专用错误
enum WidgetDatabaseError: Error, LocalizedError {
    case appGroupUnavailable
    case databaseNotFound

    var errorDescription: String? {
        switch self {
        case .appGroupUnavailable:
            return "App Group container is unavailable"
        case .databaseNotFound:
            return "Database file not found (no data yet)"
        }
    }
}
