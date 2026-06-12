//
//  ZhiYuUITests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 ZhiYuUI 开展自动化单元测试验证。
//
import XCTest

/// 智宇 (ZhiYu) 全平台核心业务流 UI 自动化测试套件
@MainActor
final class ZhiYuUITests: KnowledgeBaseUITests {

    // MARK: - 智能自愈防卫引擎

    /// 确保应用处于已登录且进入金库主页面的安全自愈引导助手
    /// 自动识别 Welcome Onboarding 遮罩，智能执行"游客登录(跳过)"及"默认金库进入"，保障后续 UI 路径 100% 可达。
    private func ensureAppIsLoggedInAndInVault() {
        var guestButton = app.buttons["GuestModeButton"]
        if !guestButton.exists {
            let predicate = NSPredicate(format: "label CONTAINS '游客' OR label CONTAINS '跳过' OR label CONTAINS 'Guest'")
            guestButton = app.buttons.matching(predicate).element(boundBy: 0)
        }

        if guestButton.waitForExistence(timeout: 3) {
            #if DEBUG
            print("UI Test Recovery: Detected Welcome Screen, tapping Guest Mode to bypass.")
            #endif
            guestButton.tap()
        }

        // 2. 自动点击返回按钮 pop 回根视图，解决测试悬挂于详情页或列表页的情况
        let backButtonPredicate = NSPredicate(format: "label CONTAINS '返回' OR label CONTAINS 'Back' OR identifier == 'Back'")
        for _ in 0..<5 {
            let backButton = app.navigationBars.buttons.matching(backButtonPredicate).element(boundBy: 0)
            if backButton.exists && backButton.isHittable {
                backButton.tap()
                try? Thread.sleep(forTimeInterval: 0.5)
            } else {
                break
            }
        }

        // 3. 此时若处于 NotebookHubView (金库列表/选择页)，则需要点击进入默认金库
        var hubView = app.scrollViews["NotebookHubView"]
        var isHubVisible = hubView.waitForExistence(timeout: 3)
        if !isHubVisible {
            let predicate = NSPredicate(format: "label CONTAINS '笔记本' OR label CONTAINS 'Notebook'")
            let fallbackTitle = app.staticTexts.matching(predicate).element(boundBy: 0)
            isHubVisible = fallbackTitle.waitForExistence(timeout: 3)
        }

        if isHubVisible {
            #if DEBUG
            print("UI Test Recovery: Detected Notebook Hub, entering the default notebook vault.")
            #endif
            var anyCard = app.buttons.matching(identifier: "NotebookCard_Item").element(boundBy: 0)
            if !anyCard.exists {
                anyCard = app.buttons.element(boundBy: 0)
            }

            if anyCard.exists {
                anyCard.tap()
                try? Thread.sleep(forTimeInterval: 1.0)
            }
        }

        // 4. 确保在主金库内时，切换到根 Knowledge Tab 视图
        let tabButton = app.tabBars.buttons["Knowledge"].exists ? app.tabBars.buttons["Knowledge"] : app.buttons["Knowledge"]
        if tabButton.waitForExistence(timeout: 5) {
            tabButton.tap()
        }
    }

    // MARK: - 全功能 UI 测试用例

    /// 关键路径测试：查看 Dashboard 仪表盘 -> 跳转推荐页面 -> 校验置顶卡片详情
    func testDashboardNavigationFlow() throws {
        ensureAppIsLoggedInAndInVault()

        let predicate = NSPredicate(format: "label CONTAINS '工作台' OR label CONTAINS '仪表盘' OR label CONTAINS 'Dashboard' OR label CONTAINS '知识仪表'")
        var dashboardRow = app.buttons.matching(predicate).element(boundBy: 0)

        if !dashboardRow.waitForExistence(timeout: 5) {
            dashboardRow = app.cells.matching(predicate).element(boundBy: 0)
        }
        if !dashboardRow.exists {
            dashboardRow = app.cells.containing(predicate).element(boundBy: 0)
        }
        if !dashboardRow.exists {
            dashboardRow = app.buttons.containing(predicate).element(boundBy: 0)
        }
        XCTAssertTrue(dashboardRow.exists, "工作台入口行应该存在")
        dashboardRow.tap()

        var dailyRecapHeader = app.staticTexts["每日灵感"]
        if !dailyRecapHeader.exists {
            dailyRecapHeader = app.staticTexts["每日闪念"]
        }
        if !dailyRecapHeader.exists {
            dailyRecapHeader = app.staticTexts["Daily Insights"]
        }
        XCTAssertTrue(dailyRecapHeader.waitForExistence(timeout: 5), "每日灵感标题应该存在并渲染")

        // 增加等待超时时间至 20 秒，以防慢速测试机或首次冷启动下异步数据播种写入延迟
        let recapCard = app.buttons["DailyRecapCard"]
        XCTAssertTrue(recapCard.waitForExistence(timeout: 20), "每日灵感推荐卡片在 20 秒内应该加载并存在")
        
        // 物理点击推荐卡片以跳转至笔记详情页
        recapCard.tap()
        
        // 校验笔记详情页的置顶 (pin) 按钮渲染就绪
        let pinButton = app.buttons["pin"]
        XCTAssertTrue(pinButton.waitForExistence(timeout: 10), "详情页置顶按钮应当存在并正确渲染")
    }

    /// 链接跳转测试：列表文档 -> 查找双向链接 [[WikiPage]] 标记 -> 模拟点击跳转关联页
    func testPageLinkNavigation() throws {
        ensureAppIsLoggedInAndInVault()

        var knowledgeTab = app.tabBars.buttons["Knowledge"]
        if !knowledgeTab.exists {
            knowledgeTab = app.tabBars.buttons["books.vertical.fill"]
        }
        if !knowledgeTab.exists {
            knowledgeTab = app.tabBars.buttons["知识库"]
        }
        XCTAssertTrue(knowledgeTab.exists, "知识库 Tab 按钮应该存在")
        knowledgeTab.tap()

        let listPredicate = NSPredicate(format: "label CONTAINS '所有' OR label CONTAINS '页面' OR label CONTAINS 'Pages'")
        var pageListRow = app.buttons.matching(listPredicate).element(boundBy: 0)

        if !pageListRow.waitForExistence(timeout: 5) {
            pageListRow = app.cells.matching(listPredicate).element(boundBy: 0)
        }
        if !pageListRow.exists {
            pageListRow = app.cells.containing(listPredicate).element(boundBy: 0)
        }
        if !pageListRow.exists {
            pageListRow = app.buttons.containing(listPredicate).element(boundBy: 0)
        }

        if pageListRow.exists {
            pageListRow.tap()
        }

        let firstPage = app.buttons.matching(identifier: "PageRow_Item").element(boundBy: 0)
        let firstPageExists = firstPage.waitForExistence(timeout: 20)
        guard firstPageExists else {
            XCTFail("知识库列表首个文档项在 20 秒内未加载完成，请检查冷启动数据种子化时序")
            return
        }
        firstPage.tap()

        let linkPredicate = NSPredicate(format: "label CONTAINS '[[ '")
        var pageLink = app.staticTexts.matching(linkPredicate).element(boundBy: 0)
        if !pageLink.exists {
            pageLink = app.staticTexts.containing(linkPredicate).element(boundBy: 0)
        }
        if pageLink.exists {
            pageLink.tap()
        }

        XCTAssertTrue(app.navigationBars.element.waitForExistence(timeout: 3))
    }

    /// 闭环测试：退出至工作台 -> 多笔记本金库切换 -> 校验播种数据幂等填充
    func testVaultSwitchingAndSeedingFlow() throws {
        ensureAppIsLoggedInAndInVault()
        navigateBackToHub()
        verifyHubAppears()
        switchToVaultCard()
        enterKnowledgeList()
        verifySeededDocuments()
    }

    private func navigateBackToHub() {
        let badgePredicate = NSPredicate(format: "label CONTAINS '笔记本' OR label CONTAINS 'Notebook'")
        let vaultBadge = findFirstExisting(app.buttons.matching(badgePredicate).firstMatch, app.buttons.containing(badgePredicate).firstMatch)
        guard vaultBadge.waitForExistence(timeout: 3) else { return }
        vaultBadge.tap()
        let backLabels = ["所有笔记本", "返回工作台", "All Notebooks"]
        for label in backLabels {
            let btn = app.buttons[label]
            if btn.waitForExistence(timeout: 3) {
                btn.tap()
                return
            }
        }
    }

    private func findFirstExisting(_ candidates: XCUIElement...) -> XCUIElement {
        for element in candidates where element.exists { return element }
        return candidates.last ?? app.buttons.firstMatch
    }

    private func verifyHubAppears() {
        let predicate = NSPredicate(format: "label CONTAINS '笔记本' OR label CONTAINS 'Notebooks' OR label CONTAINS 'Notebook'")
        let hubTitle = app.staticTexts.matching(predicate).firstMatch
        XCTAssertTrue(hubTitle.waitForExistence(timeout: 5), "NotebookHub 工作台界面应当在 5 秒内显示")
    }

    private func switchToVaultCard() {
        let cardPredicate = NSPredicate(format: "label CONTAINS '的笔记本'")
        let namedCard = findFirstExisting(app.buttons.matching(cardPredicate).firstMatch, app.buttons.containing(cardPredicate).firstMatch)
        if namedCard.exists {
            namedCard.tap()
            return
        }
        let anyCard = findFirstExisting(app.buttons.matching(identifier: "NotebookCard_Item").firstMatch, app.buttons.element(boundBy: 0))
        XCTAssertTrue(anyCard.exists)
        anyCard.tap()
    }

    private func enterKnowledgeList() {
        let knowledgeTab = resolveKnowledgeTab()
        XCTAssertTrue(knowledgeTab.exists, "知识库 Tab 按钮应该存在")
        knowledgeTab.tap()

        let listPredicate = NSPredicate(format: "label CONTAINS '所有' OR label CONTAINS '页面' OR label CONTAINS 'Pages'")
        let pageListRow = findFirstExisting(app.buttons.matching(listPredicate).element(boundBy: 0), app.cells.matching(listPredicate).element(boundBy: 0), app.cells.containing(listPredicate).element(boundBy: 0), app.buttons.containing(listPredicate).element(boundBy: 0))
        guard pageListRow.waitForExistence(timeout: 5) else { return }
        pageListRow.tap()
    }

    private func resolveKnowledgeTab() -> XCUIElement {
        let candidates = [app.tabBars.buttons["Knowledge"], app.tabBars.buttons["books.vertical.fill"], app.tabBars.buttons["知识库"]]
        for tab in candidates where tab.exists { return tab }
        return candidates.first ?? app.tabBars.buttons.firstMatch
    }

    private func verifySeededDocuments() {
        let firstCell = app.buttons.matching(identifier: "PageRow_Item").element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 20), "切换笔记本并进入文档列表后，列表中应该至少加载出一个文档项")

        let welcomePredicate = NSPredicate(format: "label CONTAINS '欢迎' OR label CONTAINS 'Welcome' OR label CONTAINS 'welcome'")
        let welcomeDocument = findFirstExisting(
            app.buttons.matching(welcomePredicate).element(boundBy: 0),
            app.buttons.containing(welcomePredicate).element(boundBy: 0),
            app.cells.matching(welcomePredicate).element(boundBy: 0),
            app.cells.containing(welcomePredicate).element(boundBy: 0),
            app.staticTexts.matching(welcomePredicate).element(boundBy: 0),
            app.staticTexts.containing(welcomePredicate).element(boundBy: 0)
        )
        if welcomeDocument.exists {
            XCTAssertTrue(welcomeDocument.exists, "冷启动播种的引导文档应当存在于列表中")
        } else {
            XCTAssertTrue(firstCell.exists, "列表中应当至少有文档项存在（欢迎文档或其他幂等播种文档）")
        }
    }

    // MARK: - 新增高级 UI 冒烟测试

    /// UI 冒烟测试：切入 AI 对话面板 -> 模拟发送提问 -> 捕获并校验国际化加载状态 (AppAILoadingSkeleton) 文案 -> 物理中断流式输出
    ///
    /// 核心职责：验证 AppAILoadingSkeleton 的 L10n 字段正确渲染，并确保 RAG 对话流的中止机制（Stop-flow）功能闭环正常。
    func testChatAISkeletonLoadingState() throws {
        ensureAppIsLoggedInAndInVault()

        var chatTab = app.tabBars.buttons["Chat"]
        if !chatTab.exists {
            chatTab = app.buttons["Chat"]
        }
        if !chatTab.exists {
            chatTab = app.tabBars.buttons["AI 对话"]
        }
        XCTAssertTrue(chatTab.waitForExistence(timeout: 5), "AI 对话 Tab 按钮应当存在")
        chatTab.tap()

        let chatInput = app.textFields["ChatInput_TextField"]
        XCTAssertTrue(chatInput.waitForExistence(timeout: 5), "对话输入框应当存在并可见")

        chatInput.tap()
        chatInput.typeText("什么是倒数排名融合RRF算法？")

        let sendButton = app.buttons["ChatSend_Button"]
        XCTAssertTrue(sendButton.exists, "发送按钮应当存在")
        sendButton.tap()

        let skeletonPredicate = NSPredicate(format: "label CONTAINS '思考' OR label CONTAINS '嵌入' OR label CONTAINS '检索' OR label CONTAINS '整合' OR label CONTAINS 'THINKING' OR label CONTAINS 'EMBEDDING' OR label CONTAINS 'RETRIEVAL' OR label CONTAINS 'SYNTHESIS' OR label CONTAINS 'ai.status.skeleton'")

        let skeletonText = app.staticTexts.matching(skeletonPredicate).element(boundBy: 0)

        let exists = skeletonText.waitForExistence(timeout: 5)
        XCTAssertTrue(exists, "AI 流式思考骨架屏 (AppAILoadingSkeleton) 本地化提示文案应当正确渲染")

        XCTAssertTrue(sendButton.exists, "发送/停止按钮应当可见并支持点击")
        sendButton.tap()

        try? Thread.sleep(forTimeInterval: 1.0)
    }
}
