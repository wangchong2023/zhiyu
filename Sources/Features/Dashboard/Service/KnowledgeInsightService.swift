// KnowledgeInsightService.swift
//
// 作者: Wang Chong
// 功能说明: 知识见解服务 (PM 视角：价值闭环)
// 版本: 1.0
// 修改记录:
//   - 创建: 2026-05-02
//   - 更新: 2026-05-04
// 日期: 2026-05-04
// 版权: 版权所有 © 2026 Wang Chong。保留所有权利。

import Foundation
/// 知识见解服务 (PM 视角：价值闭环)
/// 负责生成知识周报与核心趋势分析。
actor KnowledgeInsightService {
    static let shared = KnowledgeInsightService()

    struct WeeklyInsight: Codable, Equatable {
        let dateRange: String
        let totalNewPages: Int
        let topKeywords: [String]
        let aiSummary: String
        let growthTraction: String // 增长趋势描述
    }

    struct DailyRecap: Codable, Equatable {
        let targetPageID: UUID
        let targetPageTitle: String
        let insight: String
        let suggestedConnection: String
    }

    /// 生成每日主动召回见解 (Smart Recall)
    /// 每天仅生成一次，结果缓存至 UserDefaults。用户手动刷新时跳过缓存。
    func generateDailyRecap(pages: [KnowledgePage], llmService: any LLMServiceProtocol, forceRefresh: Bool = false) async throws -> DailyRecap {
        guard pages.count > 0 else { throw NSError(domain: "Insight", code: -1, userInfo: [NSLocalizedDescriptionKey: "请先添加知识页面以生成见解"]) }

        if !forceRefresh, let cached = loadCachedDailyRecap() {
            return cached
        }

        let now = Date()
        let calendar = Calendar.current
        let recentThreshold = calendar.date(byAdding: .day, value: -3, to: now)!
        let longTermMin = calendar.date(byAdding: .day, value: -90, to: now)!
        let longTermMax = calendar.date(byAdding: .day, value: -30, to: now)!

        let recentPages = pages.filter { $0.updated >= recentThreshold }
        let recentFocus = recentPages.isEmpty ? "近期暂无更新" : recentPages.map { $0.title }.joined(separator: " ")

        let candidates = pages.filter { $0.updated >= longTermMin && $0.updated <= longTermMax }
        let target = candidates.randomElement() ?? pages.sorted { $0.updated < $1.updated }.first!

        let prompt = Localized.trf("insight.daily.prompt.recent", recentFocus, target.title, String(target.content.prefix(500)))

        do {
            let response = try await llmService.generate(prompt: prompt, systemPrompt: L10n.Dashboard.tr("insight.daily.systemPrompt"))

            // 提取并解析 JSON (增强鲁棒性：处理多行及 Markdown 代码块)
            var jsonString: String? = nil
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
                    suggestedConnection: L10n.Dashboard.tr("insight.recap.tip")
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
        return "daily_recap_\(formatter.string(from: Date()))_\(lang)"
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
        let calendar = Calendar.current
        let lastWeek = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let newPages = pages.filter { $0.created >= lastWeek }
        let newTitles = newPages.map { $0.title }.joined(separator: ", ")

        let prompt = Localized.trf("insight.weekly.prompt", newTitles)

        let summary = try await llmService.generate(prompt: prompt, systemPrompt: L10n.Dashboard.tr("insight.weekly.systemPrompt"))
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
            growthTraction: newPages.count > 5 ? L10n.Dashboard.tr("insight.growth.explosive") : L10n.Dashboard.tr("insight.growth.steady")
        )
    }
}
