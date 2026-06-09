//
//  WidgetRepositoryTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/10.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：验证 WidgetRepository 数据读取链路的正确性

import XCTest
import GRDB
@testable import ZhiYu

@MainActor
final class WidgetRepositoryTests: XCTestCase {

    private var dbQueue: DatabaseQueue!

    override func setUp() async throws {
        try await super.setUp()
        dbQueue = try DatabaseQueue()

        // 创建测试用的 pages 表和 links 表
        try await dbQueue.write { db in
            try db.create(table: WidgetPageRow.databaseTableName) { t in
                t.column(WidgetPageRow.Columns.title.rawValue, .text).notNull()
                t.column(WidgetPageRow.Columns.pageType.rawValue, .text).notNull().defaults(to: "concept")
                t.column(WidgetPageRow.Columns.tags.rawValue, .text)
                t.column(WidgetPageRow.Columns.updatedAt.rawValue, .datetime).notNull().defaults(to: Date())
            }
            try db.create(table: WidgetLinkRow.databaseTableName) { t in
                t.column("source_id", .blob)
                t.column("target_id", .blob)
            }
        }
    }

    override func tearDown() async throws {
        dbQueue = nil
        try await super.tearDown()
    }

    // MARK: - fetchStats 正向路径

    /// 验证有数据时 fetchStats 返回正确的 pageCount / linkCount / tagCount
    func testFetchStatsWithKnownData() async throws {
        // Arrange: 写入 3 个页面 + 2 条链接
        try await dbQueue.write { db in
            for i in 1...3 {
                try db.execute(sql: """
                    INSERT INTO pages (title, page_type, tags, updated_at)
                    VALUES (?, 'concept', ?, datetime('now'))
                    """, arguments: ["Page \(i)", #"["tagA","tagB"]"#])
            }
            for _ in 1...2 {
                try db.execute(sql: "INSERT INTO links (source_id, target_id) VALUES (x'00', x'01')")
            }
        }

        // Act
        let stats = await WidgetRepository.fetchStats(from: dbQueue)

        // Assert
        XCTAssertEqual(stats.pageCount, 3)
        XCTAssertEqual(stats.linkCount, 2)
        // tagA + tagB = 2 distinct tags
        XCTAssertEqual(stats.tagCount, 2)
    }

    // MARK: - fetchStats 空数据库

    func testFetchStatsWithEmptyDatabase() async {
        let stats = await WidgetRepository.fetchStats(from: dbQueue)
        XCTAssertEqual(stats.pageCount, 0)
        XCTAssertEqual(stats.linkCount, 0)
        XCTAssertEqual(stats.tagCount, 0)
    }

    // MARK: - fetchRecentPages

    /// 验证 fetchRecentPages 返回最近更新的页面（按 updatedAt 降序）
    func testFetchRecentPagesOrdering() async throws {
        // Arrange: 写入 5 个页面，不同更新时间
        try await dbQueue.write { db in
            for i in 1...5 {
                try db.execute(sql: """
                    INSERT INTO pages (title, page_type, tags, updated_at)
                    VALUES (?, ?, '[]', datetime('now', ?))
                    """, arguments: ["Page \(i)", i % 2 == 0 ? "entity" : "concept", "-\(6-i) hours"])
            }
        }

        // Act: limit 3
        let recent = await WidgetRepository.fetchRecentPages(from: dbQueue, limit: 3)

        // Assert
        XCTAssertEqual(recent.count, 3)
        // 最近的是 Page 5
        XCTAssertEqual(recent[0].title, "Page 5")
        XCTAssertEqual(recent[0].typeName, "concept")
        // Page 4 是 entity → colorName 应该是 purple
        XCTAssertEqual(recent[1].title, "Page 4")
        XCTAssertEqual(recent[1].colorName, "purple")
        // Page 3
        XCTAssertEqual(recent[2].title, "Page 3")
    }

    // MARK: - fetchRecentPages limit 截断

    func testFetchRecentPagesRespectsLimit() async throws {
        try await dbQueue.write { db in
            for i in 1...5 {
                try db.execute(sql: """
                    INSERT INTO pages (title, page_type, tags, updated_at)
                    VALUES (?, 'concept', '[]', datetime('now'))
                    """, arguments: ["P\(i)"])
            }
        }

        let result = await WidgetRepository.fetchRecentPages(from: dbQueue, limit: 2)
        XCTAssertEqual(result.count, 2)
    }

    // MARK: - fetchRecentPages 空数据库

    func testFetchRecentPagesEmptyDatabase() async {
        let result = await WidgetRepository.fetchRecentPages(from: dbQueue)
        XCTAssertEqual(result.count, 0)
    }

    // MARK: - 标签去重

    /// 验证标签 JSON 解析 + 跨页面去重
    func testFetchDistinctTagCountDeduplication() async throws {
        try await dbQueue.write { db in
            // Page 1: [A, B]
            try db.execute(sql: """
                INSERT INTO pages (title, page_type, tags, updated_at)
                VALUES ('P1', 'concept', '["tagA","tagB"]', datetime('now'))
                """)
            // Page 2: [B, C] — tagB 重复
            try db.execute(sql: """
                INSERT INTO pages (title, page_type, tags, updated_at)
                VALUES ('P2', 'concept', '["tagB","tagC"]', datetime('now'))
                """)
            // Page 3: 无标签
            try db.execute(sql: """
                INSERT INTO pages (title, page_type, tags, updated_at)
                VALUES ('P3', 'concept', NULL, datetime('now'))
                """)
        }

        let stats = await WidgetRepository.fetchStats(from: dbQueue)
        // A, B, C = 3 distinct
        XCTAssertEqual(stats.tagCount, 3)
    }

    // MARK: - pageType → colorName 映射

    func testRecentPageColorMapping() async throws {
        try await dbQueue.write { db in
            try db.execute(sql: """
                INSERT INTO pages (title, page_type, updated_at)
                VALUES ('Concept', 'concept', datetime('now'))
                """)
            try db.execute(sql: """
                INSERT INTO pages (title, page_type, updated_at)
                VALUES ('Entity', 'entity', datetime('now', '-1 hours'))
                """)
            try db.execute(sql: """
                INSERT INTO pages (title, page_type, updated_at)
                VALUES ('Unknown', '', datetime('now', '-2 hours'))
                """)
        }

        let recent = await WidgetRepository.fetchRecentPages(from: dbQueue, limit: 3)
        XCTAssertEqual(recent[0].colorName, "accent")   // concept
        XCTAssertEqual(recent[1].colorName, "purple")   // entity
        XCTAssertEqual(recent[2].typeName, "concept")   // empty → "concept"
    }
}
