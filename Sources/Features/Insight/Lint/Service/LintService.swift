// LintService.swift
//
// 作者: Wang Chong
// 功能说明: [L2] 业务功能层：本文件实现了知识管理系统的“内容巡检”与“健康巡检”服务（LintService），旨在通过多维度算法自动发现并标记知识库中的质量缺陷。
// 该服务作为知识维护层的核心组件，通过以下功能点确保知识库的长期活力与引用完整性：
// 1. 结构化漏洞检测：自动识别“孤岛页面”（无出入链）、“断裂链接”（指向缺失页面）及“循环引用”，维护图谱结构的拓扑严谨性。
// 2. 知识陈旧度分析：基于时间阈值追踪活跃内容的更新频率，及时提醒用户对存Stub页面或陈旧知识进行深度扩充与重构。
// 3. 量化健康评分模型：内置扣分制算法（根据严重程度分级），将复杂的监控结果转化为直观的健康得分与等级评价（优秀至差）。
// 4. 非破坏性监控流程：坚持“只检不改”的原则，仅生成合规性建议（Suggestion），将最终的决策权交还给用户或 AI 修复辅助。
// 版本: 1.1
// 修改记录:
//   - 2026-05-05: 升级全工程文档规范，完善健康评分权重与巡检逻辑说明
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation

// MARK: - Lint Service (Health Check)
/// 对知识库进行健康检查：断裂链接、孤立页面、存根页面、陈旧内容。
/// Returns issues without side effects — caller decides what to do with results.
public final class LintService: @unchecked Sendable {

    /// 知识库健康等级
    public enum HealthLevel: String, CaseIterable, Sendable {
        case excellent, good, fair, poor

        var title: String {
            switch self {
            case .excellent: return L10n.Lint.healthExcellent
            case .good: return L10n.Lint.healthGood
            case .fair: return L10n.Lint.healthFair
            case .poor: return L10n.Lint.healthPoor
            }
        }

        var colorName: String {
            switch self {
            case .excellent: return "green"
            case .good: return "blue"
            case .fair: return "orange"
            case .poor: return "red"
            }
        }
    }

    /// Threshold (in days) after which an active page is considered stale.
    private static let stalePageThresholdDays = 30

    /// Run all lint checks and return the list of issues found.
    func runLint(pages: [KnowledgePage], linkService: LinkService) async -> [LintIssue] {
        var issues: [LintIssue] = []

        // 1. 性能预优化：构建查找索引 (使用 uniquingKeysWith 避免因重复标题导致的崩溃)
        let titleMap = Dictionary(pages.map { ($0.title.lowercased(), $0) }, uniquingKeysWith: { first, _ in first })
        var incomingLinksCount: [UUID: Int] = [:]
        for page in pages {
            for link in page.outgoingLinks {
                if let target = titleMap[link.lowercased()] {
                    incomingLinksCount[target.id, default: 0] += 1
                }
            }
        }

        // 2. 执行各项巡检
        issues += checkIslandsAndOrphans(pages: pages, incomingLinksCount: incomingLinksCount)
        issues += checkCircularReferences(pages: pages, titleMap: titleMap)
        issues += checkBrokenLinks(pages: pages, titleMap: titleMap)
        issues += checkStubsAndStale(pages: pages)
        issues += checkDuplicateTitles(pages: pages)

        return issues
    }

    // MARK: - 私有巡检规则

    /// 检查孤岛页面与孤立页面
    private func checkIslandsAndOrphans(pages: [KnowledgePage], incomingLinksCount: [UUID: Int]) -> [LintIssue] {
        var issues: [LintIssue] = []
        for page in pages where page.pageType != .raw {
            let inCount = incomingLinksCount[page.id] ?? 0
            let outCount = page.outgoingLinks.count

            if inCount == 0 && outCount == 0 {
                issues.append(LintIssue(
                    severity: .warning,
                    type: .island,
                    pageID: page.id,
                    message: String(format: L10n.Lint.islandMessage, page.title),
                    suggestion: L10n.Lint.islandSuggestion
                ))
            } else if inCount == 0 {
                issues.append(LintIssue(
                    severity: .info,
                    type: .orphan,
                    pageID: page.id,
                    message: String(format: L10n.Lint.orphanPage, page.title),
                    suggestion: String(format: L10n.Lint.orphanSuggestion, page.title)
                ))
            }
        }
        return issues
    }

    /// 检查循环引用 (A -> B -> A)
    private func checkCircularReferences(pages: [KnowledgePage], titleMap: [String: KnowledgePage]) -> [LintIssue] {
        var issues: [LintIssue] = []
        for pageA in pages {
            for linkTitle in pageA.outgoingLinks {
                if let pageB = titleMap[linkTitle.lowercased()] {
                    if pageB.outgoingLinks.contains(where: { $0.lowercased() == pageA.title.lowercased() }) {
                        issues.append(LintIssue(
                            severity: .info,
                            type: .cycle,
                            pageID: pageA.id,
                            message: String(format: L10n.Lint.cycleMessage, pageA.title, pageB.title),
                            suggestion: L10n.Lint.cycleSuggestion
                        ))
                    }
                }
            }
        }
        return issues
    }

    /// 检查断裂链接
    private func checkBrokenLinks(pages: [KnowledgePage], titleMap: [String: KnowledgePage]) -> [LintIssue] {
        var issues: [LintIssue] = []
        for page in pages {
            for link in page.outgoingLinks {
                if titleMap[link.lowercased()] == nil {
                    issues.append(LintIssue(
                        severity: .error,
                        type: .brokenLink,
                        pageID: page.id,
                        message: String(format: L10n.Lint.brokenLink, page.title, link),
                        suggestion: String(format: L10n.Lint.brokenLinkSuggestion, link)
                    ))
                }
            }
        }
        return issues
    }

    /// 检查存根页面与陈旧内容
    private func checkStubsAndStale(pages: [KnowledgePage]) -> [LintIssue] {
        var issues: [LintIssue] = []
        let staleThreshold = Calendar.current.date(byAdding: .day, value: -Self.stalePageThresholdDays, to: Date()) ?? Date()

        for page in pages where page.status == .active {
            // 存根检查
            if page.isStub {
                issues.append(LintIssue(
                    severity: .info,
                    type: .stub,
                    pageID: page.id,
                    message: String(format: L10n.Lint.stubContent, page.title),
                    suggestion: L10n.Lint.stubSuggestion
                ))
            }

            // 陈旧检查
            if page.updatedAt < staleThreshold {
                issues.append(LintIssue(
                    severity: .info,
                    type: .stale,
                    pageID: page.id,
                    message: String(format: L10n.Lint.outdated, page.title),
                    suggestion: L10n.Lint.outdatedSuggestion
                ))
            }
        }
        return issues
    }

    /// 检查重名的页面
    private func checkDuplicateTitles(pages: [KnowledgePage]) -> [LintIssue] {
        var issues: [LintIssue] = []
        var titleGroups: [String: [KnowledgePage]] = [:]
        for page in pages {
            let key = page.title.lowercased()
            titleGroups[key, default: []].append(page)
        }

        for (_, group) in titleGroups where group.count > 1 {
            for page in group {
                issues.append(LintIssue(
                    severity: .warning,
                    type: .generic,
                    pageID: page.id,
                    message: "存在重名页面: \"\(page.title)\" (Duplicate page title detected)",
                    suggestion: "请修改其中一个页面的标题以避免引用混淆。"
                ))
            }
        }
        return issues
    }

    /// 根据检查结果计算健康评分与等级
    func calculateHealthMetrics(issues: [LintIssue]) -> (score: Int, level: HealthLevel) {
        let errorCount = issues.filter { $0.severity == .error }.count
        let warningCount = issues.filter { $0.severity == .warning }.count
        let infoCount = issues.filter { $0.severity == .info }.count

        // 扣分制：错误 -10，警告 -5，提示 -2
        let deduction = (errorCount * 10) + (warningCount * 5) + (infoCount * 2)
        let score = max(0, 100 - deduction)

        let level: HealthLevel
        if score >= 90 { level = .excellent } else if score >= 75 { level = .good } else if score >= 50 { level = .fair } else { level = .poor }

        return (score, level)
    }
}
