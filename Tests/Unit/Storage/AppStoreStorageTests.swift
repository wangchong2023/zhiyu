// AppStoreStorageTests.swift
//
// 作者: Wang Chong
// 功能说明: 核心状态管理器测试 (Expert QA Item #4)
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-03
// 日期: 2026-05-04
// 版权: Copyright © 2026 Wang Chong. All rights reserved.

import XCTest
@testable import ZhiYu

/// 核心状态管理器测试 (Expert QA Item #4)
/// 验证 AppStore 的 CRUD 逻辑、发布订阅一致性及内存状态安全。
@MainActor
final class AppStoreStorageTests: XCTestCase {
    var store: AppStore!
    
    override func setUp() async throws {
        try await super.setUp()
        setupFullMockEnvironment()
        store = AppStore()
    }
    
    override func tearDown() async throws {
        store = nil
        // 允许当前主线程/协程事件循环排水，确保所有未完成的异步任务运行完毕，规避重置 DI 导致的 Race Condition (@SRS-7.1)
        try? await Task.sleep(nanoseconds: 50_000_000)
        DatabaseManager.shared.reset()
        ServiceContainer.shared.reset()
        try await super.tearDown()
    }
    
    /// 测试页面添加与持久化
    func testAddPage() async {
        let initialCount = store.totalPages
        let _ = await store.createPage(title: "测试页面", pageType: .concept, content: "内容")
        
        // 等待观察者更新内存状态
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        XCTAssertEqual(store.totalPages, initialCount + 1, "页面创建后总数应增加")
        XCTAssertTrue(store.pages.contains(where: { $0.title == "测试页面" }), "页面创建后应存在于列表中")
    }
    
    /// 测试页面更新逻辑 (Deep Scan 触发验证)
    func testUpdatePage() async {
        let page = await store.createPage(title: "初始标题", pageType: .concept, content: "初始内容")
        
        // 关键：必须等待观察者将新创建的页面同步到内存中，否则 updatePage 的 guard 将失败
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        var updatedPage = page
        updatedPage.content = "修改后的内容 [[链接测试]]"
        await store.updatePage(updatedPage, forceDeepScan: true)
        
        // 等待观察者更新内存状态
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        let found = store.pages.first(where: { $0.id == page.id })
        XCTAssertEqual(found?.content, "修改后的内容 [[链接测试]]")
        XCTAssertTrue(found?.outgoingLinks.contains("链接测试") ?? false, "Deep Scan 应正确解析出反向链接")
    }
    
    /// 测试页面删除
    func testDeletePage() async {
        let page = await store.createPage(title: "待删除", pageType: .concept, content: "内容")
        let id = page.id
        
        await store.deletePage(page)
        XCTAssertFalse(store.pages.contains(where: { $0.id == id }), "页面删除后不应存在")
    }
    
    /// 测试搜索建议与过滤
    func testSearchSuggestions() async {
        _ = await store.createPage(title: "Apple", pageType: .entity, content: "Fruit")
        _ = await store.createPage(title: "Banana", pageType: .entity, content: "Yellow")
        
        let results = await store.sqliteStore.searchPages(query: "Apple")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Apple")
    }
}
