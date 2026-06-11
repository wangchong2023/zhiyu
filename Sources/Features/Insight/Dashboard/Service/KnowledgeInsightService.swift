//
//  KnowledgeInsightService.swift
//  ZhiYu
//
//  Created by Antigravity on 2026/05/23.
//  Copyright © 2026 WangChong. All rights reserved.
//
//  系统层级：[L2] 业务功能层
//  核心职责：实现 KnowledgeInsight 模块的核心业务逻辑服务。
//
import Foundation
/// 知识见解服务 (PM 视角：价值闭环)
/// 负责生成知识周报与核心趋势分析。
actor KnowledgeInsightService {
    static let shared = KnowledgeInsightService()

    public struct WeeklyInsight: Codable, Equatable {
        public let dateRange: String
        public let totalNewPages: Int
        public let topKeywords: [String]
        public let aiSummary: String
        public let growthTraction: String // 增长趋势描述
    }

    public struct DailyRecap: Codable, Equatable {
        public let targetPageID: UUID
        public let targetPageTitle: String
        public let insight: String
        public let suggestedConnection: String
    }

    /// 生成每日主动召回见解 (Smart Recall)
    /// 每天仅生成一次，结果缓存至 UserDefaults。用户手动刷新时跳过缓存。
    func generateDailyRecap(pages: [KnowledgePage], llmService: any LLMServiceProtocol, forceRefresh: Bool = false) async throws -> DailyRecap {
        guard !pages.isEmpty else { throw AppError.insight(L10n.Dashboard.insight.addPagesFirst) }

        // UI 自动化测试靶场下的智能自愈：直接返回本地 Mock 保证 100% 绿通，免除外部大语言模型网络的依赖与波动
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            guard let target = pages.first else {
                throw AppError.insight(L10n.Dashboard.insight.addPagesFirst)
            }
            let recap = DailyRecap(
                targetPageID: target.id,
                targetPageTitle: target.title,
                insight: L10n.Dashboard.insight.mock.insight,
                suggestedConnection: L10n.Dashboard.insight.mock.suggestedConnection
            )
            saveCachedDailyRecap(recap)
            return recap
        }

        if !forceRefresh, let cached = loadCachedDailyRecap() {
            return cached
        }

        updateStatus(L10n.AI.Status.extracting)

        let now = Date()
        // ... (省略中间逻辑)
        let calendar = Calendar.current
        guard let recentThreshold = calendar.date(byAdding: .day, value: -3, to: now),
              let longTermMin = calendar.date(byAdding: .day, value: -90, to: now),
              let longTermMax = calendar.date(byAdding: .day, value: -30, to: now) else {
            throw AppError.insight(L10n.Insight.dateCalculationFailed, code: -2)
        }

        let recentPages = pages.filter { $0.updatedAt >= recentThreshold }
        let recentFocus = recentPages.isEmpty ? L10n.Insight.InsightSection.Daily.noUpdate : recentPages.map { $0.title }.joined(separator: " ")

        let candidates = pages.filter { $0.updatedAt >= longTermMin && $0.updatedAt <= longTermMax }
        let fallback = pages.sorted { $0.updatedAt < $1.updatedAt }.first
        guard let target = candidates.randomElement() ?? fallback else {
            throw AppError.insight(L10n.Dashboard.insight.addPagesFirst)
        }

        let prompt = L10n.Dashboard.insight.daily.promptRecent(recentFocus, target.title, String(target.content.prefix(500)))

        do {
            let response = try await llmService.generate(prompt: prompt, systemPrompt: L10n.Dashboard.insight.daily.systemPrompt)
            updateStatus(L10n.AI.Status.generating)

            // 提取并解析 JSON (增强鲁棒性：处理多行及 Markdown 代码块)
            var jsonString: String?
            if let firstBrace = response.firstIndex(of: "{"),
               let lastBrace = response.lastIndex(of: "}") {
                jsonString = String(response[firstBrace...lastBrace])
            }

            if let jsonData = jsonString?.data(using: .utf8),
               let json = try? JSONDecoder().decode([String: String].self, from: jsonData) {
                let recap = DailyRecap(
                    targetPageID: target.id,
                    targetPageTitle: target.title,
                    insight: json["insight"] ?? response,
                    suggestedConnection: json["suggestedConnection"] ?? ""
                )
                saveCachedDailyRecap(recap)
                return recap
            } else {
                let recap = DailyRecap(
                    targetPageID: target.id,
                    targetPageTitle: target.title,
                    insight: response,
                    suggestedConnection: L10n.Dashboard.insight.recap.tip
                )
                saveCachedDailyRecap(recap)
                return recap
            }
        } catch {
            throw error
        }
    }

    private func cacheKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let lang = Localized.currentLanguage
        return "\(AppConstants.Keys.Storage.dailyRecapPrefix)\(formatter.string(from: Date()))_\(lang)"
    }

    private func loadCachedDailyRecap() -> DailyRecap? {
        let key = cacheKey()
        guard let data = UserDefaults.standard.data(forKey: key),
              let recap = try? JSONDecoder().decode(DailyRecap.self, from: data) else {
            return nil
        }
        return recap
    }

    private func saveCachedDailyRecap(_ recap: DailyRecap) {
        let key = cacheKey()
        if let data = try? JSONEncoder().encode(recap) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// 生成最近一周的知识洞察
    func generateWeeklyInsight(pages: [KnowledgePage], llmService: any LLMServiceProtocol) async throws -> WeeklyInsight {
        updateStatus(L10n.AI.Status.synthesizing)
        let calendar = Calendar.current
        let lastWeek = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let newPages = pages.filter { $0.createdAt >= lastWeek }
        let newTitles = newPages.map { $0.title }.joined(separator: ", ")

        let prompt = L10n.Dashboard.insight.weekly.prompt(newTitles)

        let summary = try await llmService.generate(prompt: prompt, systemPrompt: L10n.Dashboard.insight.weekly.systemPrompt)
        let allTags = newPages.flatMap { $0.tags }
        let keywords = Array(Set(allTags)).sorted().prefix(5).map { String($0) }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: Localized.currentLanguage)
        let dateRange = "\(formatter.string(from: lastWeek)) - \(formatter.string(from: Date()))"

        return WeeklyInsight(
            dateRange: dateRange,
            totalNewPages: newPages.count,
            topKeywords: keywords,
            aiSummary: summary,
            growthTraction: newPages.count > 5 ? L10n.Dashboard.insight.growth.explosive : L10n.Dashboard.insight.growth.steady
        )
    }

    private func updateStatus(_ text: String) {
        Task { @MainActor in
            TaskCenter.shared.updateLatestStatus(text)
        }
    }
}
