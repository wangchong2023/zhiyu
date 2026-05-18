// KnowledgeRepositoryTests.swift
//
// 作者: Wang Chong
// 功能说明: 知识库仓库层测试，包含应用级加密验证 (@P0)
// 版本: 1.0
// 日期: 2026-05-16
// 版权: Copyright © 2026 Wang Chong. All rights reserved.

import XCTest
import GRDB
@testable import ZhiYu

final class KnowledgeRepositoryTests: XCTestCase {
    
    var dbQueue: DatabaseQueue!
    var repository: KnowledgePageRepository!

    override func setUp() async throws {
        try await super.setUp()
        // 创建内存数据库进行测试
        dbQueue = try DatabaseQueue()
        // 执行真实数据库迁移以建立完整的物理表结构与触发器
        try await DatabaseManager.shared.setupForTesting(with: dbQueue)
        repository = KnowledgePageRepository(dbWriter: dbQueue)
    }

    override func tearDownWithError() throws {
        repository = nil
        dbQueue = nil
    }

    // MARK: - Encryption Tests

    func testPrivatePageContentIsEncryptedInDB() async throws {
        let plainContent = "This is a very secret message."
        let page = KnowledgePage(title: "Secret", content: plainContent, tags: ["private"])
        
        // 保存页面
        try await repository.save(page)
        
        // 1. 验证内存中读取时已解密
        let fetched = try await repository.fetch(id: page.id)
        XCTAssertEqual(fetched?.content, plainContent, "读取出的内容应与原始明文一致")
        
        // 2. 验证物理数据库中存储的是加密后的密文
        try await dbQueue.read { db in
            let row = try Row.fetchOne(db, sql: "SELECT content FROM pages WHERE title = ?", arguments: ["Secret"])
            let dbContent = row?["content"] as? String
            
            XCTAssertNotNil(dbContent)
            XCTAssertNotEqual(dbContent, plainContent, "数据库中的物理内容不应是明文")
            // 验证是否为 Base64 格式（简单校验）
            XCTAssertTrue(Data(base64Encoded: dbContent ?? "") != nil, "加密内容应为 Base64 编码")
        }
    }

    func testPublicPageContentIsPlainInDB() async throws {
        let plainContent = "This is public knowledge."
        let page = KnowledgePage(title: "Public", content: plainContent, tags: ["science"])
        
        try await repository.save(page)
        
        try await dbQueue.read { db in
            let row = try Row.fetchOne(db, sql: "SELECT content FROM pages WHERE title = ?", arguments: ["Public"])
            let dbContent = row?["content"] as? String
            XCTAssertEqual(dbContent, plainContent, "普通页面在数据库中应以明文存储")
        }
    }
}
