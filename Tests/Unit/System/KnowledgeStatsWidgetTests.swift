//
//  KnowledgeStatsWidgetTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 KnowledgeStatsWidget 开展自动化单元测试验证。
//
import XCTest
import WidgetKit
@testable import ZhiYu

final class KnowledgeStatsWidgetTests: XCTestCase {
    
    /// TC-WID-01: 验证小组件时间线实体 Entry 的基本数据字段绑定可靠性
    func testKnowledgeStatsEntryConfiguration() throws {
        let entry = KnowledgeStatsEntry(
            date: Date(),
            vaultName: "ZhiYu Vault",
            pageCount: 10,
            linkCount: 20,
            tagCount: 5,
            lastUpdatedPages: [
                ("Test Page", "concept", "accent")
            ]
        )
        
        XCTAssertEqual(entry.vaultName, "ZhiYu Vault")
        XCTAssertEqual(entry.pageCount, 10)
        XCTAssertEqual(entry.linkCount, 20)
        XCTAssertEqual(entry.tagCount, 5)
        XCTAssertEqual(entry.lastUpdatedPages.count, 1)
        XCTAssertEqual(entry.lastUpdatedPages.first?.title, "Test Page")
    }
    
    /// TC-WID-02: 验证 Provider 占位符返回合法的空数据 Entry（不崩溃）
    func testKnowledgeStatsProviderPlaceholder() throws {
        let provider = KnowledgeStatsProvider()
        let placeholder = provider.placeholder(in: .init())
        XCTAssertEqual(placeholder.pageCount, 0)
        XCTAssertEqual(placeholder.linkCount, 0)
        XCTAssertEqual(placeholder.tagCount, 0)
        XCTAssertTrue(placeholder.lastUpdatedPages.isEmpty)
    }
    
    /// TC-WID-03: 验证时间线刷新策略使用正确的刷新间隔
    func testKnowledgeStatsProviderRefreshInterval() throws {
        // 验证 Widget 级别的刷新间隔配置
        XCTAssertEqual(WidgetMetrics.widgetRefreshIntervalMinutes, 30.0,
                       "Widget refresh interval should be 30 minutes for energy safety")
    }
}
