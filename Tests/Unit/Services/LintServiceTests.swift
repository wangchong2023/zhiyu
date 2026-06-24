//
//  LintServiceTests.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/06/11.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[Shared] 测试层
//  核心职责：针对 LintService 知识库健康检查功能开展自动化单元测试。
//

import XCTest
@testable import ZhiYu

final class LintServiceHealthCheckTests: ZhiYuTestCase {

    private let service = LintService()
    private let linkService = LinkService()

    // MARK: - 孤立页面与孤岛

    func testIslandPage_detected() async {
        let page = KnowledgePage(title: "孤立", content: "没有链接的页面", aliases: [])
        let issues = await service.runLint(pages: [page], linkService: linkService)
        let islandIssues = issues.filter { $0.type == .island }
        XCTAssertEqual(islandIssues.count, 1, "无入链也无出链的页面应标记为孤岛")
    }

    func testOrphanPage_detected() async {
        let pageA = KnowledgePage(title: "A", content: "[[B]]")
        let pageB = KnowledgePage(title: "B", content: "无链接内容")
        // Page A links to B, so A is outgoing, B has incoming from A
        // A has no incoming links → orphan. B has incoming → not orphan.
        let issues = await service.runLint(pages: [pageA, pageB], linkService: linkService)
        let orphanIssues = issues.filter { $0.type == .orphan }
        XCTAssertEqual(orphanIssues.count, 1, "有出链但无入链的页面应标记为孤立")
        XCTAssertEqual(orphanIssues.first?.pageID, pageA.id)
    }

    func testConnectedPages_noIssues() async {
        let pageA = KnowledgePage(title: "A", content: "内容关于 [[B]]")
        let pageB = KnowledgePage(title: "B", content: "内容关于 [[A]]")
        let issues = await service.runLint(pages: [pageA, pageB], linkService: linkService)
        XCTAssertFalse(issues.contains(where: { $0.type == .island || $0.type == .orphan }))
    }

    func testRawTypePage_skippedFromIslandCheck() async {
        let page = KnowledgePage(title: "Raw", pageType: .raw, content: "raw text")
        let issues = await service.runLint(pages: [page], linkService: linkService)
        XCTAssertFalse(issues.contains(where: { $0.type == LintIssue.IssueType.island }))
    }

    // MARK: - 断裂链接

    func testBrokenLink_detected() async {
        let page = KnowledgePage(title: "Source", content: "参考 [[NotFound]] 页面")
        let issues = await service.runLint(pages: [page], linkService: linkService)
        let brokenIssues = issues.filter { $0.type == .brokenLink }
        XCTAssertEqual(brokenIssues.count, 1)
        XCTAssertEqual(brokenIssues.first?.severity, .error)
    }

    func testBrokenLink_caseInsensitiveMatch() async {
        let pageA = KnowledgePage(title: "Target", content: "正文")
        let pageB = KnowledgePage(title: "Source", content: "参考 [[target]]")
        let issues = await service.runLint(pages: [pageA, pageB], linkService: linkService)
        XCTAssertFalse(issues.contains(where: { $0.type == .brokenLink }), "大小写不匹配不应视为断链")
    }

    func testAllLinksValid_noBrokenLinkIssues() async {
        let pageA = KnowledgePage(title: "A", content: "参考 [[B]]")
        let pageB = KnowledgePage(title: "B", content: "参考 [[A]]")
        let issues = await service.runLint(pages: [pageA, pageB], linkService: linkService)
        XCTAssertFalse(issues.contains(where: { $0.type == .brokenLink }))
    }

    // MARK: - 循环引用

    func testCircularReference_detected() async {
        let pageA = KnowledgePage(title: "A", content: "[[B]]")
        let pageB = KnowledgePage(title: "B", content: "[[A]]")
        let issues = await service.runLint(pages: [pageA, pageB], linkService: linkService)
        let cycleIssues = issues.filter { $0.type == .cycle }
        XCTAssertEqual(cycleIssues.count, 2, "双向引用双方都应标记")
    }

    func testCircularReference_threeWayCycle() async {
        // 当前算法仅检测直接双向循环（A→B→A），不跨链检测三方循环
        let pages = [
            KnowledgePage(title: "A", content: "[[B]]"),
            KnowledgePage(title: "B", content: "[[C]]"),
            KnowledgePage(title: "C", content: "[[A]]")
        ]
        let issues = await service.runLint(pages: pages, linkService: linkService)
        let cycleIssues = issues.filter { $0.type == .cycle }
        XCTAssertEqual(cycleIssues.count, 0, "三方循环引用当前算法无法检测，等待改进")
    }

    // MARK: - 存根页面

    func testStubPage_detected() async {
        let page = KnowledgePage(title: "Stub", content: "短", status: .active)
        let issues = await service.runLint(pages: [page], linkService: linkService)
        XCTAssertTrue(issues.contains(where: { $0.type == .stub }))
    }

    func testNonStubPage_noIssue() async {
        let page = KnowledgePage(title: "Long", content: String(repeating: "长", count: 200), status: .active)
        let issues = await service.runLint(pages: [page], linkService: linkService)
        XCTAssertFalse(issues.contains(where: { $0.type == .stub }))
    }

    // MARK: - 重复标题

    func testDuplicateTitles_detected() async {
        let pages = [
            KnowledgePage(title: "Duplicate"),
            KnowledgePage(title: "duplicate")
        ]
        let issues = await service.runLint(pages: pages, linkService: linkService)
        let dupIssues = issues.filter { $0.type == .generic }
        XCTAssertEqual(dupIssues.count, 2, "每个重复标题的页面都应生成一条 issue")
    }

    func testUniqueTitles_noDuplicateIssue() async {
        let pages = [
            KnowledgePage(title: "A"),
            KnowledgePage(title: "B")
        ]
        let issues = await service.runLint(pages: pages, linkService: linkService)
        XCTAssertFalse(issues.contains(where: { $0.type == .generic }))
    }

    // MARK: - 健康评分

    func testCalculateHealthMetrics_perfectScore() {
        let metrics = service.calculateHealthMetrics(issues: [])
        XCTAssertEqual(metrics.score, 100)
        XCTAssertEqual(metrics.level, .excellent)
    }

    func testCalculateHealthMetrics_withDeductions() {
        let issues = [
            LintIssue(severity: .error, message: "", suggestion: ""),
            LintIssue(severity: .warning, message: "", suggestion: ""),
            LintIssue(severity: .info, message: "", suggestion: "")
        ]
        let metrics = service.calculateHealthMetrics(issues: issues)
        XCTAssertEqual(metrics.score, 83) // 100 - 10 - 5 - 2
        XCTAssertEqual(metrics.level, .good)
    }

    func testCalculateHealthMetrics_minimumScoreZero() {
        let issues = (0..<15).map { _ in LintIssue(severity: .error, message: "", suggestion: "") }
        let metrics = service.calculateHealthMetrics(issues: issues)
        XCTAssertEqual(metrics.score, 0)
        XCTAssertEqual(metrics.level, .poor)
    }

    func testCalculateHealthMetrics_levelThresholds() {
        struct TestCase {
            let errorCount: Int
            let warningCount: Int
            let expectedScore: Int
            let expectedLevel: LintService.HealthLevel
        }
        let testCases: [TestCase] = [
            TestCase(errorCount: 0, warningCount: 0, expectedScore: 100, expectedLevel: .excellent),
            TestCase(errorCount: 1, warningCount: 0, expectedScore: 90, expectedLevel: .excellent),
            TestCase(errorCount: 2, warningCount: 0, expectedScore: 80, expectedLevel: .good),
            TestCase(errorCount: 3, warningCount: 0, expectedScore: 70, expectedLevel: .fair),
            TestCase(errorCount: 4, warningCount: 0, expectedScore: 60, expectedLevel: .fair),
            TestCase(errorCount: 5, warningCount: 0, expectedScore: 50, expectedLevel: .fair),
            TestCase(errorCount: 6, warningCount: 0, expectedScore: 40, expectedLevel: .poor),
            TestCase(errorCount: 0, warningCount: 5, expectedScore: 75, expectedLevel: .good),
            TestCase(errorCount: 0, warningCount: 6, expectedScore: 70, expectedLevel: .fair),
            TestCase(errorCount: 0, warningCount: 10, expectedScore: 50, expectedLevel: .fair),
            TestCase(errorCount: 0, warningCount: 11, expectedScore: 45, expectedLevel: .poor)
        ]
        for tc in testCases {
            var issues: [LintIssue] = []
            for _ in 0..<tc.errorCount {
                issues.append(LintIssue(severity: .error, message: "", suggestion: ""))
            }
            for _ in 0..<tc.warningCount {
                issues.append(LintIssue(severity: .warning, message: "", suggestion: ""))
            }
            let metrics = service.calculateHealthMetrics(issues: issues)
            XCTAssertEqual(metrics.score, tc.expectedScore, "errors=\(tc.errorCount) warnings=\(tc.warningCount)")
            XCTAssertEqual(metrics.level, tc.expectedLevel, "errors=\(tc.errorCount) warnings=\(tc.warningCount)")
        }
    }
}
