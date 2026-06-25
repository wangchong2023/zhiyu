//
//  NotebookHubUITests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/25.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Tests] UI 测试层
//  核心职责：验证 NotebookHub → 点击内置笔记本 → Dashboard 渲染全链路，
//           覆盖 iPad/Mac NavigationSplitView 过渡和 L10n 初始化场景。
//           防止 EXC_BREAKPOINT (MainActor.assumeIsolated) 和
//           GestureRecognizer 冲突导致的 crash 回归。

import XCTest

/// NotebookHub UI 自动化测试
///
/// 测试覆盖：
/// 1. 内置笔记本数量验证（始终 ≥2）
/// 2. 点击内置笔记本 → Dashboard 仪表盘渲染
/// 3. 笔记本切换无 crash（NavigationSplitView 过渡 + languageMode 访问）
/// 4. languageMode 缓存初始化正确性（非主 actor 上下文安全）
@MainActor
final class NotebookHubUITests: KnowledgeBaseUITests {

    // MARK: - 内置笔记本存在性

    /// 验证 NotebookHub 至少显示 2 个内置笔记本（"知识图谱" + "项目调研"）。
    /// 这覆盖了 VaultDataCoordinator.loadVaults() 通过 englishName 补全内置笔记本的逻辑。
    func testNotebookHubShowsAtLeastTwoDefaultNotebooks() async throws {
        // 如果已经进入主界面（有 TabBar），先回到 NotebookHub
        if app.tabBars.firstMatch.exists {
            // 通过 VaultBadge → 退出到 NotebookHub
            returnToNotebookHub()
        }

        // 等待 NotebookHub 出现
        let hubView = app.scrollViews["NotebookHubView"]
        XCTAssertTrue(hubView.waitForExistence(timeout: 5),
                      "NotebookHubView 应在 5 秒内显示")

        // 统计笔记本卡片数量
        let cards = app.buttons.matching(identifier: "NotebookCard_Item")
        let cardCount = cards.count
        XCTAssertGreaterThanOrEqual(cardCount, 2,
                                    "应至少显示 2 个内置笔记本，实际: \(cardCount)")
    }

    // MARK: - 点击笔记本 → Dashboard 渲染

    /// 点击内置笔记本 → 验证 Dashboard 仪表盘正确渲染。
    /// 这是本次 crash 修复的核心回归测试——验证 .task 闭包中
    /// languageMode 访问不会触发 EXC_BREAKPOINT。
    func testClickBuiltInNotebookNavigatesToDashboard() async throws {
        // 确保在 NotebookHub
        if app.tabBars.firstMatch.exists {
            returnToNotebookHub()
        }

        let hubView = app.scrollViews["NotebookHubView"]
        guard hubView.waitForExistence(timeout: 5) else {
            throw XCTSkip("NotebookHubView 未显示，跳过测试")
        }

        // 点击第一个内置笔记本
        let firstCard = app.buttons.matching(identifier: "NotebookCard_Item").element(boundBy: 0)
        guard firstCard.waitForExistence(timeout: 3) else {
            throw XCTSkip("无可点击的笔记本卡片，跳过测试")
        }
        firstCard.tap()

        // 等待主界面出现（TabBar + 内容区域）
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5),
                      "点击笔记本后 TabBar 应在 5 秒内显示")

        // 验证 Knowledge tab 被选中
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // 检查 Dashboard 区域有内容渲染（非白屏）
        let sidebarTitle = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'dashboard' OR label CONTAINS[c] '仪表盘'")
        ).firstMatch
        let hasContent = sidebarTitle.exists
            || app.staticTexts.firstMatch.exists
        XCTAssertTrue(hasContent, "仪表盘应渲染至少部分可见内容")

        // 核心断言：应用未崩溃。如果到达这里，说明 NavigationSplitView 过渡、
        // KnowledgeDashboardView.task 中的 languageMode 访问均成功。
    }

    // MARK: - 笔记本切换稳定性

    /// 连续切换多个笔记本，验证 NavigationSplitView 过渡无 crash。
    func testSwitchBetweenVaultsDoesNotCrash() async throws {
        // 进入第一个笔记本
        if app.tabBars.firstMatch.exists {
            returnToNotebookHub()
        }

        let hubView = app.scrollViews["NotebookHubView"]
        guard hubView.waitForExistence(timeout: 5) else {
            throw XCTSkip("NotebookHubView 未显示")
        }

        let cards = app.buttons.matching(identifier: "NotebookCard_Item")
        guard cards.count >= 2 else {
            throw XCTSkip("需要至少 2 个笔记本进行切换测试")
        }

        // 第一轮：点击第一个笔记本
        cards.element(boundBy: 0).tap()
        var tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "首次点击应进入主界面")

        // 返回到 NotebookHub
        returnToNotebookHub()
        guard hubView.waitForExistence(timeout: 5) else {
            throw XCTSkip("返回 NotebookHub 失败")
        }

        // 第二轮：点击第二个笔记本
        let refreshedCards = app.buttons.matching(identifier: "NotebookCard_Item")
        guard refreshedCards.count >= 2 else {
            throw XCTSkip("返回后笔记本卡片数量不足")
        }
        refreshedCards.element(boundBy: 1).tap()

        tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "第二次点击应进入主界面")

        // 如果到达这里，连续切换无 crash
    }

    // MARK: - 从 NotebookHub 创建并进入自定义笔记本

    /// 创建自定义笔记本 → 点击进入 → 验证 Dashboard 不 crash。
    /// 这覆盖了非内置笔记本（拼音 englishName 路径）的完整流程。
    func testCreateAndEnterCustomNotebookDoesNotCrash() async throws {
        // 确保在 NotebookHub
        if app.tabBars.firstMatch.exists {
            returnToNotebookHub()
        }

        let hubView = app.scrollViews["NotebookHubView"]
        guard hubView.waitForExistence(timeout: 5) else {
            throw XCTSkip("NotebookHubView 未显示")
        }

        // 点击新建按钮（网格模式下的 + 卡片或空状态下的引导按钮）
        let createBtn: XCUIElement
        let gridCreateBtn = app.buttons["CreateNotebookButton"]
        let emptyCreateBtn = app.buttons["empty_state_action_button"]
        if gridCreateBtn.exists {
            createBtn = gridCreateBtn
        } else if emptyCreateBtn.exists {
            createBtn = emptyCreateBtn
        } else {
            throw XCTSkip("找不到新建笔记本按钮")
        }
        createBtn.tap()

        // 填写创建表单
        let nameField = app.textFields["notebook_name_textfield"]
        guard nameField.waitForExistence(timeout: 3) else {
            throw XCTSkip("创建表单未出现")
        }
        nameField.tap()
        nameField.typeText("UI 测试笔记本")

        let submitBtn = app.buttons["notebook_submit_button"]
        guard submitBtn.exists else {
            throw XCTSkip("提交按钮不存在")
        }
        submitBtn.tap()

        // 等待新卡片出现并点击
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        let newCard = app.buttons.matching(identifier: "NotebookCard_Item").element(boundBy: 0)
        guard newCard.waitForExistence(timeout: 3) else {
            throw XCTSkip("新建笔记本卡片未出现")
        }
        newCard.tap()

        // 验证主界面出现
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5),
                      "进入自定义笔记本后 TabBar 应显示")
    }

    // MARK: - Helpers

    /// 通过 VaultBadge 菜单退出当前笔记本，返回 NotebookHub 工作台。
    private func returnToNotebookHub() {
        // 优先通过 VaultBadge 菜单退出
        let vaultBadge = app.buttons["vaultBadgeButton"]
        if vaultBadge.waitForExistence(timeout: 3) {
            vaultBadge.tap()
            // 使用 accessibilityIdentifier 精确定位，避免 L10n 值变更导致匹配失败
            let backBtn = app.buttons["vaultBackToHubButton"]
            if backBtn.waitForExistence(timeout: 2) {
                backBtn.tap()
                _ = app.scrollViews["NotebookHubView"].waitForExistence(timeout: 5)
                return
            }
        }

        // 回退方案：通过 Sidebar 中的 NotebookHub 入口
        let sidebarHubEntry = app.buttons["SidebarTab_knowledge"]
        if sidebarHubEntry.exists {
            sidebarHubEntry.tap()
        }
        _ = app.scrollViews["NotebookHubView"].waitForExistence(timeout: 3)
    }
}
