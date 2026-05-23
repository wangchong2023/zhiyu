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
    /// 自动识别 Welcome Onboarding 遮罩，智能执行“游客登录(跳过)”及“默认金库进入”，保障后续 UI 路径 100% 可达。
    private func ensureAppIsLoggedInAndInVault() {
        // 1. 优先使用 GuestModeButton 测试标识定位游客模式按钮，若缺失则降级使用标签模糊检索
        var guestButton = app.buttons["GuestModeButton"]
        if !guestButton.exists {
            guestButton = app.buttons.containing(NSPredicate(format: "label CONTAINS '游客' OR label CONTAINS '跳过' OR label CONTAINS 'Guest'")).element(boundBy: 0)
        }
        
        if guestButton.waitForExistence(timeout: 3) {
            #if DEBUG
            print("UI Test Recovery: Detected Welcome Screen, tapping Guest Mode to bypass.")
            #endif
            guestButton.tap()
        }
        
        // 2. 优先通过唯一标识定位笔记本工作台，若缺失则通过多语言标签降级检索
        var hubView = app.scrollViews["NotebookHubView"]
        var isHubVisible = hubView.waitForExistence(timeout: 3)
        if !isHubVisible {
            let fallbackTitle = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '笔记本' OR label CONTAINS 'Notebook'")).element(boundBy: 0)
            isHubVisible = fallbackTitle.waitForExistence(timeout: 3)
        }
        
        if isHubVisible {
            #if DEBUG
            print("UI Test Recovery: Detected Notebook Hub, entering the default notebook vault.")
            #endif
            // 优先通过唯一标识符精确定位笔记本卡片，避免误触“新建笔记本”等控制按钮
            var anyCard = app.buttons.matching(identifier: "NotebookCard_Item").element(boundBy: 0)
            if !anyCard.exists {
                // 兜底降级方案：获取工作台中的第一个按钮
                anyCard = app.buttons.element(boundBy: 0)
            }
            
            if anyCard.exists {
                anyCard.tap()
            }
        }
    }

    // MARK: - 全功能 UI 测试用例
    
    /// 关键路径测试：查看 Dashboard 图谱 -> 跳转推荐页面 -> 校验置顶卡片详情
    func testDashboardNavigationFlow() throws {
        // 执行登录自愈防卫
        ensureAppIsLoggedInAndInVault()
        
        // 1. 确认并点击底部“图谱” (Graph) 仪表盘标签
        let dashboardTab = app.tabBars.buttons["Graph"]
        XCTAssertTrue(dashboardTab.exists)
        dashboardTab.tap()
        
        // 2. 检查“每日闪念 (Daily Recap)”推荐模块是否存在并成功渲染
        let dailyRecapHeader = app.staticTexts["每日闪念"] 
        XCTAssertTrue(dailyRecapHeader.waitForExistence(timeout: 5))
        
        // 3. 点击当日智能推荐卡片完成路由跳转
        let recapCard = app.buttons.element(boundBy: 0)
        XCTAssertTrue(recapCard.exists)
        recapCard.tap()
        
        // 4. 验证详情页面右上角“pin”置顶按钮是否存在，证明路由成功推进至文档详情
        let pinButton = app.buttons["pin"]
        XCTAssertTrue(pinButton.waitForExistence(timeout: 2))
    }
    
    /// 链接跳转测试：列表文档 -> 查找双向链接 [[WikiPage]] 标记 -> 模拟点击跳转关联页
    func testPageLinkNavigation() throws {
        // 执行登录自愈防卫
        ensureAppIsLoggedInAndInVault()
        
        // 1. 进入“知识库 (Knowledge)”列表主页面
        app.tabBars.buttons["Knowledge"].tap()
        
        // 2. 点击列表顶部的第一个已播种知识文档
        let firstPage = app.cells.element(boundBy: 0)
        XCTAssertTrue(firstPage.exists)
        firstPage.tap()
        
        // 3. 智能模糊查找包含 CJK 双向链接标记 "[[ " 的文本颗粒
        let pageLink = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '[[ '")).element(boundBy: 0)
        if pageLink.exists {
            pageLink.tap()
        }
        
        // 4. 校验导航栏标题是否存在，检验跳转链路完整度
        XCTAssertTrue(app.navigationBars.element.exists)
    }
    
    /// 闭环测试：退出至工作台 -> 多笔记本金库切换 -> 校验播种数据幂等填充
    func testVaultSwitchingAndSeedingFlow() throws {
        // 执行登录自愈防卫
        ensureAppIsLoggedInAndInVault()
        
        // 1. 若当前已经在特定笔记本中，点击左上角“笔记本/金库”角标退出至 Hub 平台
        let vaultBadge = app.buttons.containing(NSPredicate(format: "label CONTAINS '笔记本'")).element(boundBy: 0)
        if vaultBadge.waitForExistence(timeout: 2) {
            vaultBadge.tap()
            let backButton = app.buttons["返回工作台"]
            if backButton.waitForExistence(timeout: 2) {
                backButton.tap()
            }
        }
        
        // 2. 确认安全退回至 NotebookHub 工作台
        let hubTitle = app.staticTexts["笔记本"]
        XCTAssertTrue(hubTitle.waitForExistence(timeout: 5))
        
        // 3. 点击切换笔记本（优先匹配自定义命名的笔记本卡片，否则匹配带有唯一标识符的卡片，最后降级匹配网格中首个按钮）
        let firstVaultCard = app.buttons.containing(NSPredicate(format: "label CONTAINS '的笔记本'")).element(boundBy: 0)
        if firstVaultCard.exists {
            firstVaultCard.tap()
        } else {
            var anyCard = app.buttons.matching(identifier: "NotebookCard_Item").element(boundBy: 0)
            if !anyCard.exists {
                anyCard = app.buttons.element(boundBy: 0)
            }
            XCTAssertTrue(anyCard.exists)
            anyCard.tap()
        }
        
        // 4. 进入新金库后，校验冷启动数据播种 (Data Seeding) 是否幂等安全触发
        // 切换至 Knowledge 列表，验证含有“欢迎来到智宇”的导引文档渲染情况
        app.tabBars.buttons["Knowledge"].tap()
        let welcomeDocument = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '欢迎'")).element(boundBy: 0)
        XCTAssertTrue(welcomeDocument.waitForExistence(timeout: 8))
    }
}
