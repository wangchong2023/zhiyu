//
//  ShortcutManagerTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 ShortcutManager 开展自动化单元测试验证。
//
#if os(iOS) || os(macOS)
import XCTest
import AppIntents
@testable import ZhiYu

@available(iOS 16.0, macOS 13.0, *)
final class ShortcutManagerTests: XCTestCase {
    
    /// TC-SHO-01: 测试快速记录意图 (CaptureIntent) 的配置与类型参数的正确性
    func testCaptureIntentConfiguration() throws {
        let intent = ShortcutManager.CaptureIntent()
        
        // 验证多语言 Key 的安全绑定
        XCTAssertEqual(ShortcutManager.CaptureIntent.title.key, "shortcuts.capture.title")
        
        // 验证默认参数无脏数据
        XCTAssertTrue(intent.content.isEmpty, "Default content should be empty")
    }
    
    /// TC-SHO-02: 测试搜索知识库意图 (SearchKnowledgeIntent) 的路由前置配置
    func testSearchKnowledgeIntentConfiguration() throws {
        let intent = ShortcutManager.SearchKnowledgeIntent()
        
        XCTAssertEqual(ShortcutManager.SearchKnowledgeIntent.title.key, "shortcuts.search.title")
        XCTAssertTrue(ShortcutManager.SearchKnowledgeIntent.openAppWhenRun, "Search intent should open the app")
        XCTAssertTrue(intent.query.isEmpty, "Default query should be empty")
    }
    
    /// TC-SHO-03: 测试统计查询意图 (GetKnowledgeStatsIntent) 的配置完整度
    func testGetKnowledgeStatsIntentConfiguration() throws {
        XCTAssertEqual(ShortcutManager.GetKnowledgeStatsIntent.title.key, "shortcuts.stats.title")
    }
    
    /// TC-SHO-04: 测试快捷指令提供商 (ZhiYuShortcuts) 向系统提供并绑定的 Intent 映射正确性
    func testAppShortcutsProviderPhrases() throws {
        // 获取注册的所有快捷指令列表
        let shortcuts = ZhiYuShortcuts.appShortcuts
        
        // 关键过程：验证系统快捷指令的总数量是否符合设计预期（目前应为 3 个）
        XCTAssertEqual(shortcuts.count, 3, "快捷指令列表长度应与预期注册的 3 个快捷指令相符")
    }
}
#endif
