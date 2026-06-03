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
    
    /// TC-WID-02: 验证时间线提供商在 Snapshot 数据拉取下的数值准确度与字段可靠性
    func testKnowledgeStatsProviderFetchEntry() throws {
        let provider = KnowledgeStatsProvider()
        let entry = provider.fetchWidgetEntry(date: Date())
        
        // 关键过程：验证拟真的静态 Mock 数据与系统预期指标的对齐情况
        XCTAssertEqual(entry.vaultName, "Demo Vault", "Mock vault name should be Demo Vault")
        XCTAssertEqual(entry.pageCount, AppConstants.Demo.mockPageCount)
        XCTAssertEqual(entry.linkCount, AppConstants.Demo.mockLinkCount)
        XCTAssertEqual(entry.tagCount, AppConstants.Demo.mockTagCount)
        XCTAssertEqual(entry.lastUpdatedPages.count, 3)
    }

    /// TC-WID-03: 验证小组件时间线刷新策略是否严格处于 30 分钟以上的能耗安全保护限制内
    func testKnowledgeStatsProviderTimelinePolicy() throws {
        let provider = KnowledgeStatsProvider()
        let testDate = Date()
        let timeline = provider.calculateTimeline(date: testDate)
        
        XCTAssertEqual(timeline.entries.count, 1, "Timeline should contain exactly 1 baseline entry")
        
        // 🟢 经典避坑指南：WidgetKit 的 TimelineReloadPolicy 实际上是 struct 而非 enum，
        // 它的 .after(Date) 是静态工厂方法。因此我们通过 Equatable 来优雅断言 policy 的对齐情况，
        // 从而完美避开模式匹配编译限制。
        let expectedPolicy = TimelineReloadPolicy.after(testDate.addingTimeInterval(AppConstants.Demo.widgetRefreshIntervalMinutes * 60))
        XCTAssertEqual(timeline.policy, expectedPolicy, "Timeline reload policy should match exactly \(AppConstants.Demo.widgetRefreshIntervalMinutes) minutes later")
    }
}
