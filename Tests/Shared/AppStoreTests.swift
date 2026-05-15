// AppStoreTests.swift
//
// 作者: Wang Chong
// 功能说明: ZhiYu存储Tests.swift
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
// 日期: 2026-05-04
// 版权: Copyright © 2026 Wang Chong. All rights reserved.

import XCTest
@testable import ZhiYu

@MainActor
final class AppStoreTests: XCTestCase {
    var store: AppStore!
    
    override func setUp() async throws {
        try await super.setUp()
        setupFullMockEnvironment()
        store = AppStore()
    }
    
    override func tearDown() async throws {
        store = nil
        DatabaseManager.shared.reset()
        ServiceContainer.shared.reset()
        try await super.tearDown()
    }
    
    func testPageCreation() async {
        let initialCount = store.totalPages
        let _ = await store.createPage(title: "Test Page", type: .concept, content: "Test Content")
        XCTAssertEqual(store.totalPages, initialCount + 1)
    }
    
    func testUndoRedo() async {
        let initialCount = store.totalPages
        _ = await store.createPage(title: "Undo Test", type: .concept)
        XCTAssertEqual(store.totalPages, initialCount + 1)
        
        store.undo()
        XCTAssertEqual(store.totalPages, initialCount)
        
        store.redo()
        XCTAssertEqual(store.totalPages, initialCount + 1)
    }
    
    func testTagManagement() async {
        let _ = await store.createPage(title: "Tag Test", type: .concept, tags: ["OldTag"])
        XCTAssertTrue(store.pages.contains { $0.tags.contains("OldTag") })
        
        store.renameTag("OldTag", to: "NewTag")
        XCTAssertTrue(store.pages.contains { $0.tags.contains("NewTag") })
        XCTAssertFalse(store.pages.contains { $0.tags.contains("OldTag") })
        
        store.deleteTag("NewTag")
        XCTAssertFalse(store.pages.contains { $0.tags.contains("NewTag") })
    }
}
