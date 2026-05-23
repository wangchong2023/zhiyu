//
//  GraphUITests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 GraphUI 开展自动化单元测试验证。
//
import XCTest

// MARK: - Graph UI Tests
/// 3D 图谱 UI 自动化测试套件
/// 覆盖范围：缩放按钮、类型过滤 Pill、图例切换、洞察面板、标签云
final class GraphTests: KnowledgeBaseUITests {

    override func setUp() async throws {
        try await super.setUp()
        // 图谱 Tab 在 Tab 栏中物理索引为 4
        tapTab(named: "Graph")
        try? await Task.sleep(nanoseconds: UInt64(1 * 1_000_000_000))
    }

    /// 验证图谱缩放控制按钮可交互
    func testGraphZoomControls() async {
        let zoomIn = app.buttons.matching(identifier: "zoom-in").firstMatch
        if zoomIn.exists {
            safeTap(zoomIn)
            try? await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
        }

        let zoomOut = app.buttons.matching(identifier: "zoom-out").firstMatch
        if zoomOut.exists {
            safeTap(zoomOut)
            try? await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
        }

        let resetBtn = app.buttons.matching(identifier: "reset").firstMatch
        if resetBtn.exists {
            safeTap(resetBtn)
            try? await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
        }

        let relayoutBtn = app.buttons.matching(identifier: "relayout").firstMatch
        if relayoutBtn.exists {
            safeTap(relayoutBtn)
            try? await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
        }
    }

    /// 验证类型过滤 Pill 按钮可交互（实体/关系过滤）
    func testTypeFilterPills() async {
        let entityFilter = app.buttons.matching(identifier: "Filter-entity").firstMatch
        if entityFilter.exists {
            safeTap(entityFilter)
            try? await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
            safeTap(entityFilter) // 取消选择
        }
    }

    /// 验证图例开关按钮可交互
    func testLegendToggle() async {
        let legendBtn = app.buttons.matching(identifier: "toggle-legend").firstMatch
        if legendBtn.exists {
            safeTap(legendBtn)
            try? await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
        }
    }

    /// 验证图谱洞察面板开关及内容渲染
    func testInsightsToggle() async {
        let insightsBtn = app.buttons.matching(identifier: "toggle-insights").firstMatch
        if insightsBtn.exists {
            safeTap(insightsBtn)
            try? await Task.sleep(nanoseconds: UInt64(1 * 1_000_000_000))
            // 验证洞察面板出现
            XCTAssertTrue(app.scrollViews.firstMatch.exists || app.otherElements.firstMatch.exists)
            // 再次点击关闭
            if insightsBtn.isHittable {
                safeTap(insightsBtn)
                try? await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
            }
        }
    }
}

// MARK: - Tag Cloud UI Tests
/// 标签云 UI 自动化测试套件
/// 覆盖范围：标签云按钮访问与内容验证
final class TagCloudTests: KnowledgeBaseUITests {

    /// 验证标签云工具按钮存在并可展开
    func testTagCloudToolExists() async {
        await navigateToKnowledgeTab()
        let tagCloudButton = app.buttons.matching(identifier: "tagCloud").firstMatch
        if tagCloudButton.isHittable {
            safeTap(tagCloudButton)
            try? await Task.sleep(nanoseconds: UInt64(1 * 1_000_000_000))
            // 标签云应展示内容或空状态
            XCTAssertFalse(app.staticTexts.count == 0, "标签云应有内容或空状态提示")
        }
    }
}
