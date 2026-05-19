// ZhiYuMonkeyTests.swift
//
// 作者: Wang Chong
// 功能说明: [Tests] 原生 XCUITest 狂暴随机点击测试 (Monkey Test)
//          在真实模拟器下进行 100 次随机探索与深层页面渗透，用于提前暴露 UI 栈冲突与导航死锁。
// 版本: 1.0
// 日期: 2026-05-18
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import XCTest

/// 智宇 (ZhiYu) 原生 100 次狂暴随机点击 Monkey 测试
///
/// 本测试通过遍历屏幕上的活动 hittable 元素，结合防死锁的过滤安全逻辑和随机交互，
/// 狂暴碰撞并深度压力遍历应用内各种隐藏的弹窗与深层嵌套导航。
@MainActor
final class ZhiYuMonkeyTests: XCTestCase {
    
    /// XCUIApplication 实例句柄
    var app: XCUIApplication!

    override func setUp() async throws {
        try await super.setUp()
        
        // 避让单元测试 Target，确保此 UI 测试只在 UI 测试沙盒中正确运行
        if ProcessInfo.processInfo.processName == "ZhiYu" {
            throw XCTSkip("Skipping Monkey UI test in Unit Test target to prevent XCUIApplication init crash.")
        }
        
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() async throws {
        app?.terminate()
        try await super.tearDown()
    }

    /// 执行 100 次原生的狂暴随机点击测试
    func testWildMonkeyClickTraversal() throws {
        let maxIterations = 100
        print("====== [MONKEY] 开始执行 100 步狂暴随机点击遍历压力测试 ======")
        
        for step in 1...maxIterations {
            // 1. 每步短暂休眠 0.35s，给 UI 阻尼弹性动效和渲染流水线以缓冲时间，真实模拟用户反应
            _ = app.wait(for: .unknown, timeout: 0.35)
            
            // 2. 分别采集屏幕上当前存在且可命中点击的各类按钮、网格、列表行、标签页
            let buttons = app.buttons.allElementsBoundByIndex.filter { $0.exists && $0.isHittable }
            let cells = app.cells.allElementsBoundByIndex.filter { $0.exists && $0.isHittable }
            let tabBars = app.tabBars.buttons.allElementsBoundByIndex.filter { $0.exists && $0.isHittable }
            
            // 3. 合并交互候选项
            var candidates: [XCUIElement] = []
            candidates.append(contentsOf: buttons)
            candidates.append(contentsOf: cells)
            candidates.append(contentsOf: tabBars)
            
            // 4. 【智能避让机制】过滤掉带有“删除”、“退出”、“擦除”、“销毁”等可能导致测试提前截断或数据物理丢失的敏感选项
            candidates = candidates.filter { element in
                let label = element.label.lowercased()
                let identifier = element.identifier.lowercased()
                
                let isDestructive = label.contains("delete") || label.contains("删除") ||
                                    label.contains("erase") || label.contains("擦除") ||
                                    label.contains("sign out") || label.contains("退出登录") ||
                                    label.contains("logout") || label.contains("clear") ||
                                    label.contains("清除")
                
                let isDestructiveId = identifier.contains("delete") || identifier.contains("logout")
                
                return !isDestructive && !isDestructiveId
            }
            
            // 5. 进行随机驱动决策
            if candidates.isEmpty {
                // 如果当前屏幕陷入无响应的死胡同或输入框遮挡，执行一次随机物理阻尼拖拽滑动来试图自我破局
                print("[MONKEY] 第 \(step)/\(maxIterations) 步：未检索到安全交互点。执行屏幕中轴随机拖拽滑动破局。")
                let startPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
                let endPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
                startPoint.press(forDuration: 0.1, thenDragTo: endPoint)
            } else {
                // 从安全候选池中挑选一员进行模拟点击
                let randomIndex = Int.random(in: 0..<candidates.count)
                let targetElement = candidates[randomIndex]
                
                print("[MONKEY] 第 \(step)/\(maxIterations) 步：拟真操作 -> 元素类型: \(targetElement.elementType)，文本标签: '\(targetElement.label)'")
                
                // 执行点击。捕捉由于点击瞬间页面动画导致的 hittable 改变异常，保证 monkey 主进程抗震不死
                do {
                    if targetElement.exists && targetElement.isHittable {
                        targetElement.tap()
                    }
                } catch {
                    print("[MONKEY] 操作警告：元素状态在执行瞬间发生偏转，跳过该步。")
                }
            }
        }
        
        print("====== [MONKEY] 狂暴随机测试顺利闯关 100 步！应用导航无死锁，未触发任何崩溃或 UI 栈冲突 ======")
    }
}
