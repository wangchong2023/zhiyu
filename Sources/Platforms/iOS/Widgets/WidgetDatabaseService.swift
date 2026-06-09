//
//  WidgetDatabaseService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/09.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 平台适配层
//  核心职责：Widget Extension 专用的轻量级数据库读取服务。
//           Widget 无法引入主 App 的 DatabaseManager 与领域模型，
//           故通过 GRDB 直接打开 App Group 共享 SQLite 文件，使用原始 SQL 查询。
//
import Foundation
import GRDB

/// Widget Extension 专用的轻量级数据库读取服务。
///
/// 设计原则：
/// - 只读打开，绝不写入
/// - 纯静态函数，无状态
/// - 原始 SQL 查询，不依赖领域模型（模型文件不在 Widget Target 中）
enum WidgetDatabaseService {

    // MARK: - 数据库路径

    /// App Group 共享容器标识符
    private static let appGroupIdentifier = "group.com.zhiyu.app"

    /// 获取 App Group 共享容器中的数据库文件 URL
    private static var databaseURL: URL? {
        let fileManager = FileManager.default
        guard let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            return nil
        }
        return groupURL.appendingPathComponent(AppConstants.Storage.databaseName)
    }

    // MARK: - 数据库连接

    /// 建立只读数据库连接池
    /// - Returns: 配置好的只读 DatabasePool
    /// - Throws: WidgetDatabaseError 或 GRDB 错误
    private static func openReadOnlyPool() throws -> DatabasePool {
        guard let dbURL = databaseURL else {
            throw WidgetDatabaseError.appGroupUnavailable
        }
        guard FileManager.default.fileExists(atPath: dbURL.path) else {
            throw WidgetDatabaseError.databaseNotFound
        }

        var config = Configuration()
        config.readonly = true
        // WAL 模式下只读取不开启事务，避免锁竞争
        config.qos = .utility
        return try DatabasePool(path: dbURL.path, configuration: config)
    }

    // MARK: - 公开 API

    /// 获取知识库统计数据
    /// - Returns: (pageCount 页面数, linkCount 链接数, tagCount 标签数)
    static func fetchStats() async -> (pageCount: Int, linkCount: Int, tagCount: Int) {
        do {
            let pool = try openReadOnlyPool()
            defer { try? pool.close() }

            let pageCount = try await pool.read { db in
                try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(AppConstants.Storage.Tables.pages)") ?? 0
            }
            let linkCount = try await pool.read { db in
                try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(AppConstants.Storage.Tables.links)") ?? 0
            }
            let tagCount = try await pool.read { db in
                // tags 列存储为 JSON 字符串数组，使用 json_each 展开后统计不重复值
                try Int.fetchOne(db, sql: """
                    SELECT COUNT(DISTINCT value)
                    FROM \(AppConstants.Storage.Tables.pages), json_each(\(AppConstants.Storage.Tables.pages).tags)
                    """) ?? 0
            }
            return (pageCount, linkCount, tagCount)
        } catch {
            print("[WidgetDatabaseService] fetchStats failed: \(error.localizedDescription)")
            return (0, 0, 0)
        }
    }

    /// 获取最近更新的知识页列表
    /// - Parameter limit: 返回条数，默认 3
    /// - Returns: 元组数组 (title, typeName, colorName)
    static func fetchRecentPages(limit: Int = 3) async -> [(title: String, typeName: String, colorName: String)] {
        do {
            let pool = try openReadOnlyPool()
            defer { try? pool.close() }

            let rows = try await pool.read { db in
                try Row.fetchAll(db, sql: """
                    SELECT title, page_type
                    FROM \(AppConstants.Storage.Tables.pages)
                    ORDER BY updated_at DESC
                    LIMIT ?
                    """, arguments: [limit])
            }

            return rows.map { row in
                let title: String = row["title"]
                // page_type 可能为 nil，默认 concept
                let typeName: String = (row["page_type"] as String?) ?? "concept"
                // 颜色名称映射规则：concept → accent（蓝），其他 → purple
                let colorName = typeName == "concept" ? "accent" : "purple"
                return (title, typeName, colorName)
            }
        } catch {
            print("[WidgetDatabaseService] fetchRecentPages failed: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - 错误类型

/// Widget 数据库服务专用错误
enum WidgetDatabaseError: Error, LocalizedError {
    /// App Group 容器不可用
    case appGroupUnavailable
    /// 数据库文件不存在（首次启动或从未创建数据）
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
