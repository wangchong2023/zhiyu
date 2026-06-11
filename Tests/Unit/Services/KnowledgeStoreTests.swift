//
//  KnowledgeStoreTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/11.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 KnowledgeStore 的纯逻辑与数据操作开展单元测试。
//

import XCTest
@testable import ZhiYu

@MainActor
final class KnowledgeStoreSimpleTests: XCTestCase {

    // MARK: - 初始状态

    func testInitialState() {
        let store = KnowledgeStore()
        XCTAssertTrue(store.pages.isEmpty, "初始页面列表应为空")
        XCTAssertEqual(store.totalPages, 0)
        XCTAssertEqual(store.totalWords, 0)
        XCTAssertFalse(store.isScanning)
        XCTAssertFalse(store.showCreateSheet)
    }

    func testPagesMutability() {
        let store = KnowledgeStore()
        let page = KnowledgePage(title: "测试")
        store.pages = [page]
        XCTAssertEqual(store.pages.count, 1)
        XCTAssertEqual(store.pages.first?.title, "测试")
    }

    func testTotalWordsSettable() {
        let store = KnowledgeStore()
        store.totalWords = 100
        XCTAssertEqual(store.totalWords, 100)
    }
}
