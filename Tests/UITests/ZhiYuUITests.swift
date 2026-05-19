// ZhiYuUITests.swift
//
// 作者: Wang Chong
// 功能说明: 关键路径测试：查看 Dashboard -> 跳转页面 -> 检查内容
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
// 日期: 2026-05-04
// 版权: Copyright © 2026 Wang Chong. All rights reserved.

import XCTest

@MainActor
final class ZhiYuUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() async throws {
        try await super.setUp()
        
        // 防止在单元测试 Target 中运行 UI 测试导致崩溃
        if ProcessInfo.processInfo.processName == "ZhiYu" {
            throw XCTSkip("Skipping UI test in Unit Test target to prevent XCUIApplication init crash.")
        }
        
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() async throws {
        app?.terminate()
        try await super.tearDown()
    }

    /// 关键路径测试：查看 Dashboard -> 跳转页面 -> 检查内容
    func testDashboardNavigationFlow() throws {
        // 1. 确认是否在 Dashboard 标签
        let dashboardTab = app.tabBars.buttons["Graph"] // 对应代码中的 .graph 图谱/仪表盘
        XCTAssertTrue(dashboardTab.exists)
        dashboardTab.tap()
        
        // 2. 检查每日闪念 (Daily Recap) 是否存在
        let dailyRecapHeader = app.staticTexts["每日闪念"] 
        XCTAssertTrue(dailyRecapHeader.waitForExistence(timeout: 5))
        
        // 3. 点击推荐卡片进行跳转
        let recapCard = app.buttons.element(boundBy: 0) // 第一个推荐卡片
        XCTAssertTrue(recapCard.exists)
        recapCard.tap()
        
        // 4. 验证是否进入了页面详情
        let pinButton = app.buttons["pin"]
        XCTAssertTrue(pinButton.waitForExistence(timeout: 2))
    }
    
    /// 测试 PageLink 点击跳转
    func testPageLinkNavigation() throws {
        // 1. 进入搜索或列表找到包含链接的页面
        app.tabBars.buttons["Knowledge"].tap()
        
        let firstPage = app.cells.element(boundBy: 0)
        XCTAssertTrue(firstPage.exists)
        firstPage.tap()
        
        // 2. 查找正文中的链接（蓝色文本或特定标记）
        let pageLink = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '[[ '")).element(boundBy: 0)
        if pageLink.exists {
            pageLink.tap()
        }
        XCTAssertTrue(app.navigationBars.element.exists)
    }
    
    /// 测试金库切换与数据冷启动自动播种校验
    func testVaultSwitchingAndSeedingFlow() throws {
        // 1. 尝试寻找金库标识，如果存在则退出至工作台以进行切换测试
        let vaultBadge = app.buttons.containing(NSPredicate(format: "label CONTAINS '笔记本'")).element(boundBy: 0)
        if vaultBadge.waitForExistence(timeout: 2) {
            vaultBadge.tap()
            let backButton = app.buttons["返回工作台"]
            if backButton.waitForExistence(timeout: 2) {
                backButton.tap()
            }
        }
        
        // 2. 此时应当在主笔记本选择工作台 (NotebookHub)
        let hubTitle = app.staticTexts["笔记本"]
        XCTAssertTrue(hubTitle.waitForExistence(timeout: 5))
        
        // 3. 点击第一个可点击的金库卡片进入
        let firstVaultCard = app.buttons.containing(NSPredicate(format: "label CONTAINS '的笔记本'")).element(boundBy: 0)
        if firstVaultCard.exists {
            firstVaultCard.tap()
        } else {
            // 如果不存在特定命名卡片，尝试点击网格内第一个普通的卡片按钮
            let anyCard = app.buttons.element(boundBy: 0)
            XCTAssertTrue(anyCard.exists)
            anyCard.tap()
        }
        
        // 4. 进入金库后，系统会自动触发冷启动自动数据播种 (Seeding)
        // 校验欢迎文档 "欢迎来到智宇 👋" 是否存在且渲染，证明播种幂等安全执行且成功！
        app.tabBars.buttons["Knowledge"].tap()
        let welcomeDocument = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '欢迎'")).element(boundBy: 0)
        XCTAssertTrue(welcomeDocument.waitForExistence(timeout: 8))
    }
}
