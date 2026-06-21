//
//  AISettingsTabSwitchingUITests.swift
//  ZhiYuUITests
//
//  临时 UI 测试：验证 AISettingsView 顶部 Tab 切换是否正常响应
//  修复前：tab 点击不响应
//  修复后：tab 应能正常切换内容
//

import XCTest

@MainActor
final class AISettingsTabSwitchingUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() async throws {
        try await super.setUp()

        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state", "-ResetUserDefaults", "-UITest_MockData"]
        app.launchEnvironment = ["UITesting": "true"]
        app.launch()

        // 跳过游客模式
        let guestButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS '游客' OR label CONTAINS '跳过' OR identifier == 'GuestModeButton'")
        ).element(boundBy: 0)
        if guestButton.waitForExistence(timeout: 3) {
            guestButton.tap()
        }

        Thread.sleep(forTimeInterval: 1.5)
    }

    /// 验证 AISettingsView 顶部的 4 个 tab 是否都能点击切换
    func testAISettingsTabsAreSwitchable() throws {
        // 1. 找到用户头像入口
        let profileButton = app.buttons["userProfileMenuButton"]
        XCTAssertTrue(profileButton.waitForExistence(timeout: 5), "用户头像入口应当存在")
        profileButton.tap()

        Thread.sleep(forTimeInterval: 1.0)

        // 2. 在弹出菜单中点击"AI 大模型"或"人工智能"入口
        let aiMenuPredicate = NSPredicate(format: "label CONTAINS 'AI' OR label CONTAINS '人工智能' OR label CONTAINS '大模型'")
        let aiMenuButton = app.buttons.matching(aiMenuPredicate).element(boundBy: 0)
        XCTAssertTrue(aiMenuButton.waitForExistence(timeout: 3), "AI 大模型菜单入口应当存在")
        aiMenuButton.tap()

        Thread.sleep(forTimeInterval: 1.5)

        // 3. 确认进入 AI 设置页面
        let navTitle = app.navigationBars["人工智能"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "AI 设置页面导航栏标题应为'人工智能'")

        // 4. 通过 segmented control 定位 Picker
        let segmentedControl = app.segmentedControls.firstMatch
        XCTAssertTrue(segmentedControl.waitForExistence(timeout: 3), "AISettingsView 顶部的分段选择器应当存在")
        XCTAssertEqual(segmentedControl.buttons.count, 4, "分段选择器应当有 4 个 tab")

        // 5. 点击 "在线大模型" segment (索引 1)
        let tab2 = segmentedControl.buttons.element(boundBy: 1)
        XCTAssertTrue(tab2.isHittable, "tab '在线大模型' 应当可点击")
        tab2.tap()

        Thread.sleep(forTimeInterval: 1.0)

        // 调试：dump 整个屏幕文本，看看点击后实际渲染的是什么
        let allStaticTexts = app.staticTexts.allElementsBoundByIndex.map { $0.label }
        print("DEBUG after tab2 tap, static texts count: \(allStaticTexts.count)")
        print("DEBUG ALL static texts: \(allStaticTexts)")

        let apiKeyText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS '开启 AI 助手' OR label CONTAINS '提供商' OR label CONTAINS 'API'")
        ).firstMatch
        XCTAssertTrue(apiKeyText.waitForExistence(timeout: 3),
                      "点击'在线大模型' tab 后应显示相关配置内容（API Key、提供商等），说明 tab 切换响应成功")

        // 6. 点击 "本地大模型" tab
        let tab3 = segmentedControl.buttons.element(boundBy: 2)
        XCTAssertTrue(tab3.isHittable, "tab '本地大模型' 应当可点击")
        tab3.tap()
        Thread.sleep(forTimeInterval: 1.0)

        let allStaticTexts2 = app.staticTexts.allElementsBoundByIndex.map { $0.label }
        print("DEBUG after tab3 tap, static texts count: \(allStaticTexts2.count)")
        print("DEBUG ALL static texts: \(allStaticTexts2)")

        let localText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS '本地' OR label CONTAINS '模型市场' OR label CONTAINS '测试'")
        ).firstMatch
        XCTAssertTrue(localText.waitForExistence(timeout: 3),
                      "点击'本地大模型' tab 后应显示相关配置内容（模型市场/测试实验室）")

        // 7. 点击 "提示词设置" tab
        let tab4 = segmentedControl.buttons.element(boundBy: 3)
        XCTAssertTrue(tab4.isHittable, "tab '提示词设置' 应当可点击")
        tab4.tap()
        Thread.sleep(forTimeInterval: 1.0)

        let promptText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS '提示' OR label CONTAINS 'Prompt'")
        ).firstMatch
        XCTAssertTrue(promptText.waitForExistence(timeout: 3),
                      "点击'提示词设置' tab 后应显示相关配置内容")

        // 8. 点击 "大模型策略" tab 回到第一项
        let tab1 = segmentedControl.buttons.element(boundBy: 0)
        XCTAssertTrue(tab1.isHittable, "tab '大模型策略' 应当可点击")
        tab1.tap()
        Thread.sleep(forTimeInterval: 1.0)

        let strategyText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS '策略' OR label CONTAINS '路由' OR label CONTAINS '本地模型'")
        ).firstMatch
        XCTAssertTrue(strategyText.waitForExistence(timeout: 3),
                      "点击'大模型策略' tab 后应显示路由策略相关内容")
    }
}
